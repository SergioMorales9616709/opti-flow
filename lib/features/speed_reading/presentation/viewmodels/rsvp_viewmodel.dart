import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:optiflow/core/database/progress_repository.dart';
import 'package:optiflow/core/utils/audio_cue.dart';
import 'package:optiflow/core/utils/audio_service.dart';
import 'package:optiflow/features/speed_reading/data/text_repository.dart';
import 'package:optiflow/features/speed_reading/domain/neuro_reading_utils.dart';
import 'package:optiflow/features/vision_training/presentation/viewmodels/saccadic_jumps_viewmodel.dart'
    show ExerciseDuration;

const _kDefaultWpm = 300;
const _kMinWpm = 200;
const _kMaxWpm = 1200;
const _kAssetPath = 'assets/texts/cuento_1.txt';

// Sentinel privado para distinguir "no se pasó el parámetro" de null
// en copyWith.
class _Absent {
  const _Absent();
}

const _absent = _Absent();

/// Calculates the delay in ms for [word] at [wpm], applying dynamic pauses
/// for sentence boundaries. Exposed at library level for unit testing.
int pauseMsFor(String word, int wpm) {
  final base = 60000 ~/ wpm;
  if (word.endsWith(',')) return (base * 1.5).round();
  const stops = {'.', ':', '?', '!', ';'};
  if (stops.any((s) => word.endsWith(s))) return (base * 2.5).round();
  return base;
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class RsvpState {
  const RsvpState({
    this.words = const [],
    this.currentIndex = 0,
    this.currentWpm = _kDefaultWpm,
    this.isPlaying = false,
    this.isMuted = false,
    this.isLoaded = false,
    this.selectedDuration = ExerciseDuration.s60,
    this.timeLeftSeconds,
  });

  final List<String> words;
  final int currentIndex;
  final int currentWpm;
  final bool isPlaying;
  final bool isMuted;
  final bool isLoaded;
  final ExerciseDuration selectedDuration;
  final int? timeLeftSeconds;

  RsvpState copyWith({
    List<String>? words,
    int? currentIndex,
    int? currentWpm,
    bool? isPlaying,
    bool? isMuted,
    bool? isLoaded,
    ExerciseDuration? selectedDuration,
    Object? timeLeftSeconds = _absent,
  }) {
    return RsvpState(
      words: words ?? this.words,
      currentIndex: currentIndex ?? this.currentIndex,
      currentWpm: currentWpm ?? this.currentWpm,
      isPlaying: isPlaying ?? this.isPlaying,
      isMuted: isMuted ?? this.isMuted,
      isLoaded: isLoaded ?? this.isLoaded,
      selectedDuration: selectedDuration ?? this.selectedDuration,
      timeLeftSeconds: timeLeftSeconds is _Absent
          ? this.timeLeftSeconds
          : timeLeftSeconds as int?,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class RsvpNotifier extends Notifier<RsvpState> {
  bool _running = false;
  Timer? _countdownTimer;

  @override
  RsvpState build() {
    // Capture before disposal — ref.read is invalid after container tears down.
    final audioService = ref.read(audioServiceProvider);
    ref.onDispose(() {
      _running = false;
      _cancelCountdown();
      audioService.stopBgm();
    });
    _loadText();
    return const RsvpState();
  }

  Future<void> _loadText() async {
    final rawWords = await ref
        .read(textRepositoryProvider)
        .loadWords(_kAssetPath);
    state = state.copyWith(words: chunkWords(rawWords), isLoaded: true);
  }

  void setWpm(int wpm) {
    state = state.copyWith(currentWpm: wpm.clamp(_kMinWpm, _kMaxWpm));
  }

  void setDuration(ExerciseDuration duration) {
    if (state.isPlaying) return;
    state = state.copyWith(selectedDuration: duration, timeLeftSeconds: null);
  }

  void toggleMute() {
    final muted = !state.isMuted;
    state = state.copyWith(isMuted: muted);
    final audio = ref.read(audioServiceProvider);
    if (state.isPlaying) {
      muted ? audio.stopBgm() : audio.playBgm();
    }
  }

  Future<void> startReading() async {
    if (state.isPlaying || state.words.isEmpty) return;
    _running = true;
    final seconds = state.selectedDuration.seconds;
    state = state.copyWith(isPlaying: true, timeLeftSeconds: seconds);
    if (seconds != null) _startCountdown();
    if (!state.isMuted) {
      unawaited(ref.read(audioServiceProvider).playBgm());
    }

    while (_running && state.currentIndex < state.words.length) {
      final word = state.words[state.currentIndex];
      final ms = pauseMsFor(word, state.currentWpm);
      await Future<void>.delayed(Duration(milliseconds: ms));
      if (!_running) break;
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }

    if (_running) await _onFinished();
  }

  void pause() {
    if (!state.isPlaying) return;
    _running = false;
    _cancelCountdown();
    state = state.copyWith(isPlaying: false);
    ref.read(audioServiceProvider).stopBgm();
    unawaited(_persist());
  }

  Future<void> _onFinished() async {
    _running = false;
    _cancelCountdown();
    unawaited(ref.read(audioServiceProvider).stopBgm());
    state = state.copyWith(isPlaying: false);
    await _persist();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final left = state.timeLeftSeconds;
      if (left == null) return;
      if (left <= 1) {
        unawaited(_onTimeUp());
      } else {
        state = state.copyWith(timeLeftSeconds: left - 1);
      }
    });
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  Future<void> _onTimeUp() async {
    _running = false;
    _cancelCountdown();
    final audio = ref.read(audioServiceProvider);
    await audio.stopBgm();
    state = state.copyWith(isPlaying: false, timeLeftSeconds: 0);
    await audio.play(AudioCue.success);
    await _persist();
  }

  Future<void> _persist() async {
    await ref
        .read(progressRepositoryProvider)
        .saveProgress(
          exerciseType: 'speed_reading_rsvp',
          maxSpeedMs: state.currentWpm,
        );
  }
}

final rsvpProvider = NotifierProvider<RsvpNotifier, RsvpState>(
  RsvpNotifier.new,
);
