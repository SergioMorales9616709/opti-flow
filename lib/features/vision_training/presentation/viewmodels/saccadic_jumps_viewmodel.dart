import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:optiflow/core/database/progress_repository.dart';
import 'package:optiflow/core/utils/audio_cue.dart';
import 'package:optiflow/core/utils/audio_service.dart';
import 'package:optiflow/features/vision_training/domain/saccadic_pattern.dart';

enum ExerciseStatus { idle, active, saving, saved }

class SaccadicJumpsState {
  const SaccadicJumpsState({
    required this.pattern,
    required this.stepIndex,
    required this.symbolIndex,
    required this.status,
    required this.speedMs,
    required this.minSpeedMs,
    required this.maxSpeedMs,
    required this.isSoundEnabled,
  });

  final SaccadicPattern pattern;
  final int stepIndex;
  final int symbolIndex;
  final ExerciseStatus status;
  final int speedMs;
  final int minSpeedMs;
  final int maxSpeedMs;
  final bool isSoundEnabled;

  Alignment get currentAlignment => pattern.sequence[stepIndex];

  SaccadicJumpsState copyWith({
    SaccadicPattern? pattern,
    int? stepIndex,
    int? symbolIndex,
    ExerciseStatus? status,
    int? speedMs,
    bool? isSoundEnabled,
  }) {
    return SaccadicJumpsState(
      pattern: pattern ?? this.pattern,
      stepIndex: stepIndex ?? this.stepIndex,
      symbolIndex: symbolIndex ?? this.symbolIndex,
      status: status ?? this.status,
      speedMs: speedMs ?? this.speedMs,
      minSpeedMs: minSpeedMs,
      maxSpeedMs: maxSpeedMs,
      isSoundEnabled: isSoundEnabled ?? this.isSoundEnabled,
    );
  }
}

class SaccadicJumpsNotifier extends Notifier<SaccadicJumpsState> {
  static const int _defaultSpeedMs = 800;
  static const int _minSpeedMs = 300;
  static const int _maxSpeedMs = 1200;

  Timer? _timer;

  @override
  SaccadicJumpsState build() {
    ref.onDispose(_cancelTimer);
    return const SaccadicJumpsState(
      pattern: SaccadicPattern.horizontal,
      stepIndex: 0,
      symbolIndex: 0,
      status: ExerciseStatus.idle,
      speedMs: _defaultSpeedMs,
      minSpeedMs: _minSpeedMs,
      maxSpeedMs: _maxSpeedMs,
      isSoundEnabled: true,
    );
  }

  void setPattern(SaccadicPattern p) {
    if (state.status != ExerciseStatus.idle) return;
    // Reset stepIndex: new pattern may have fewer steps than current index.
    state = state.copyWith(pattern: p, stepIndex: 0);
  }

  void setSpeed(int ms) {
    if (state.status == ExerciseStatus.active) {
      _startTimer(ms);
    }
    state = state.copyWith(speedMs: ms);
  }

  void startExercise() {
    if (state.status == ExerciseStatus.active) return;
    state = state.copyWith(status: ExerciseStatus.active);
    _startTimer(state.speedMs);
  }

  void stopAndSave() {
    if (state.status != ExerciseStatus.active) return;
    _cancelTimer();
    state = state.copyWith(status: ExerciseStatus.saving);
    _persist();
  }

  Future<void> _persist() async {
    final repo = ref.read(progressRepositoryProvider);
    await repo.saveProgress(
      exerciseType: 'saccadic_jumps',
      maxSpeedMs: state.speedMs,
    );
    state = state.copyWith(status: ExerciseStatus.saved);
  }

  void toggleSound() {
    state = state.copyWith(isSoundEnabled: !state.isSoundEnabled);
  }

  void reset() {
    _cancelTimer();
    state = SaccadicJumpsState(
      pattern: SaccadicPattern.horizontal,
      stepIndex: 0,
      symbolIndex: 0,
      status: ExerciseStatus.idle,
      speedMs: _defaultSpeedMs,
      minSpeedMs: _minSpeedMs,
      maxSpeedMs: _maxSpeedMs,
      isSoundEnabled: state.isSoundEnabled,
    );
  }

  void _startTimer(int ms) {
    _cancelTimer();
    _timer = Timer.periodic(Duration(milliseconds: ms), (_) {
      final seq = state.pattern.sequence;
      state = state.copyWith(
        stepIndex: (state.stepIndex + 1) % seq.length,
        symbolIndex: state.symbolIndex + 1,
      );
      if (state.isSoundEnabled) {
        ref.read(audioServiceProvider).play(AudioCue.click);
      }
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }
}

final saccadicJumpsProvider =
    NotifierProvider<SaccadicJumpsNotifier, SaccadicJumpsState>(
      SaccadicJumpsNotifier.new,
    );
