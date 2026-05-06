import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:optiflow/core/database/progress_repository.dart';
import 'package:optiflow/core/utils/audio_cue.dart';
import 'package:optiflow/core/utils/audio_service.dart';
import 'package:optiflow/features/vision_training/domain/pursuit_pattern.dart';
import 'package:optiflow/features/vision_training/presentation/viewmodels/saccadic_jumps_viewmodel.dart'
    show ExerciseDuration, ExerciseStatus;

class _Absent {
  const _Absent();
}

const _absent = _Absent();

class SmoothPursuitState {
  const SmoothPursuitState({
    this.pattern = PursuitPattern.circle,
    this.status = ExerciseStatus.idle,
    this.speedMs = _defaultSpeedMs,
    this.isMuted = false,
    this.minSpeedMs = _minSpeed,
    this.maxSpeedMs = _maxSpeed,
    this.selectedDuration = ExerciseDuration.s60,
    this.timeLeftSeconds,
  });

  static const int _defaultSpeedMs = 3000;
  static const int _minSpeed = 1500;
  static const int _maxSpeed = 5000;

  final PursuitPattern pattern;
  final ExerciseStatus status;
  final int speedMs;
  final bool isMuted;
  final int minSpeedMs;
  final int maxSpeedMs;
  final ExerciseDuration selectedDuration;
  final int? timeLeftSeconds;

  SmoothPursuitState copyWith({
    PursuitPattern? pattern,
    ExerciseStatus? status,
    int? speedMs,
    bool? isMuted,
    ExerciseDuration? selectedDuration,
    Object? timeLeftSeconds = _absent,
  }) {
    return SmoothPursuitState(
      pattern: pattern ?? this.pattern,
      status: status ?? this.status,
      speedMs: speedMs ?? this.speedMs,
      isMuted: isMuted ?? this.isMuted,
      minSpeedMs: minSpeedMs,
      maxSpeedMs: maxSpeedMs,
      selectedDuration: selectedDuration ?? this.selectedDuration,
      timeLeftSeconds: timeLeftSeconds is _Absent
          ? this.timeLeftSeconds
          : timeLeftSeconds as int?,
    );
  }
}

class SmoothPursuitNotifier extends Notifier<SmoothPursuitState> {
  Timer? _countdownTimer;

  @override
  SmoothPursuitState build() {
    ref.onDispose(_cancelCountdown);
    return const SmoothPursuitState();
  }

  void setPattern(PursuitPattern p) {
    if (state.status != ExerciseStatus.idle) return;
    state = state.copyWith(pattern: p);
  }

  void setSpeed(int ms) => state = state.copyWith(speedMs: ms);

  void setDuration(ExerciseDuration d) {
    if (state.status != ExerciseStatus.idle) return;
    state = state.copyWith(selectedDuration: d, timeLeftSeconds: null);
  }

  void startExercise() {
    if (state.status == ExerciseStatus.active) return;
    final seconds = state.selectedDuration.seconds;
    state = state.copyWith(
      status: ExerciseStatus.active,
      timeLeftSeconds: seconds,
    );
    if (!state.isMuted) {
      ref.read(audioServiceProvider).playBgm();
    }
    if (seconds != null) {
      _startCountdown();
    }
  }

  void stopAndSave() {
    if (state.status != ExerciseStatus.active) return;
    _cancelCountdown();
    ref.read(audioServiceProvider).stopBgm();
    state = state.copyWith(status: ExerciseStatus.saving);
    _persist();
  }

  Future<void> _persist() async {
    await ref
        .read(progressRepositoryProvider)
        .saveProgress(
          exerciseType: 'smooth_pursuit',
          maxSpeedMs: state.speedMs,
        );
    state = state.copyWith(status: ExerciseStatus.saved);
  }

  void toggleMute() {
    final muted = !state.isMuted;
    state = state.copyWith(isMuted: muted);
    final audio = ref.read(audioServiceProvider);
    if (state.status == ExerciseStatus.active) {
      muted ? audio.stopBgm() : audio.playBgm();
    }
  }

  void reset() {
    _cancelCountdown();
    ref.read(audioServiceProvider).stopBgm();
    state = SmoothPursuitState(
      isMuted: state.isMuted,
      selectedDuration: state.selectedDuration,
    );
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final left = state.timeLeftSeconds;
      if (left == null) return;
      if (left <= 1) {
        _countdownTimer?.cancel();
        _countdownTimer = null;
        ref.read(audioServiceProvider).play(AudioCue.success);
        stopAndSave();
      } else {
        state = state.copyWith(timeLeftSeconds: left - 1);
      }
    });
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }
}

final smoothPursuitProvider =
    NotifierProvider<SmoothPursuitNotifier, SmoothPursuitState>(
      SmoothPursuitNotifier.new,
    );
