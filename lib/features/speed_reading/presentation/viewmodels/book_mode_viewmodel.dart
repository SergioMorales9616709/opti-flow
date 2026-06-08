import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:optiflow/core/database/progress_repository.dart';
import 'package:optiflow/core/utils/audio_cue.dart';
import 'package:optiflow/core/utils/audio_service.dart';
import 'package:optiflow/features/speed_reading/data/text_repository.dart';
import 'package:optiflow/features/speed_reading/domain/text_pagination_utils.dart';
import 'package:optiflow/features/vision_training/presentation/viewmodels/saccadic_jumps_viewmodel.dart'
    show ExerciseDuration;

const _kDefaultWpm = 300;
const _kMinWpm = 200;
const _kMaxWpm = 2400;
const _kAssetPath = 'assets/texts/cuento_1.txt';

// Sentinel privado para distinguir "no se pasó el parámetro" de null
// en copyWith.
class _Absent {
  const _Absent();
}

const _absent = _Absent();

/// Returns the display duration in ms for [line] at [wpm].
/// Exposed at library level for unit testing.
int msForLine(String line, int wpm) {
  final wordCount = line.split(' ').where((w) => w.isNotEmpty).length;
  return (60000 ~/ wpm) * wordCount;
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class BookModeState {
  const BookModeState({
    this.lines = const [],
    this.currentLineIndex = 0,
    this.currentWpm = _kDefaultWpm,
    this.isPlaying = false,
    this.isMuted = false,
    this.isLoaded = false,
    this.selectedDuration = ExerciseDuration.s60,
    this.timeLeftSeconds,
  });

  final List<String> lines;
  final int currentLineIndex;
  final int currentWpm;
  final bool isPlaying;
  final bool isMuted;
  final bool isLoaded;
  final ExerciseDuration selectedDuration;
  final int? timeLeftSeconds;

  BookModeState copyWith({
    List<String>? lines,
    int? currentLineIndex,
    int? currentWpm,
    bool? isPlaying,
    bool? isMuted,
    bool? isLoaded,
    ExerciseDuration? selectedDuration,
    Object? timeLeftSeconds = _absent,
  }) {
    return BookModeState(
      lines: lines ?? this.lines,
      currentLineIndex: currentLineIndex ?? this.currentLineIndex,
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

class BookModeNotifier extends Notifier<BookModeState> {
  bool _running = false;
  String _rawText = '';
  Timer? _countdownTimer;

  @override
  BookModeState build() {
    // Capture before disposal — ref.read is invalid after container tears down.
    final audioService = ref.read(audioServiceProvider);
    ref.onDispose(() {
      _running = false;
      _cancelCountdown();
      audioService.stopBgm();
    });
    _loadText();
    return const BookModeState();
  }

  Future<void> _loadText() async {
    final words = await ref.read(textRepositoryProvider).loadWords(_kAssetPath);
    _rawText = words.join(' ');
    state = state.copyWith(isLoaded: true);
  }

  /// Called from BookModeView via LayoutBuilder once the column width is
  /// known. Lines are paginated to fit a single book column.
  void paginate(
    double columnWidth,
    TextStyle style, {
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    if (_rawText.isEmpty) return;
    final lines = paginateTextIntoLines(
      rawText: _rawText,
      maxWidth: columnWidth,
      style: style,
      textScaler: textScaler,
    );
    state = state.copyWith(lines: lines, currentLineIndex: 0);
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
    if (state.isPlaying || state.lines.isEmpty) return;
    _running = true;
    final seconds = state.selectedDuration.seconds;
    state = state.copyWith(isPlaying: true, timeLeftSeconds: seconds);
    if (seconds != null) _startCountdown();
    if (!state.isMuted) {
      unawaited(ref.read(audioServiceProvider).playBgm());
    }

    while (_running && state.currentLineIndex < state.lines.length) {
      final line = state.lines[state.currentLineIndex];
      final ms = msForLine(line, state.currentWpm);
      await Future<void>.delayed(Duration(milliseconds: ms));
      if (!_running) break;
      state = state.copyWith(currentLineIndex: state.currentLineIndex + 1);
    }

    if (_running) await _onFinished();
  }

  void pause() {
    _running = false;
    _cancelCountdown();
    if (state.isPlaying) {
      state = state.copyWith(isPlaying: false);
      ref.read(audioServiceProvider).stopBgm();
    }
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
          exerciseType: 'speed_reading_book',
          maxSpeedMs: state.currentWpm,
        );
  }
}

final bookModeProvider = NotifierProvider<BookModeNotifier, BookModeState>(
  BookModeNotifier.new,
);
