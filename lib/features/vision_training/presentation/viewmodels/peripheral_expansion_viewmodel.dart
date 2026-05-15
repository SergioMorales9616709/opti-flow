import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:optiflow/core/database/progress_repository.dart';
import 'package:optiflow/core/utils/audio_cue.dart';
import 'package:optiflow/core/utils/audio_service.dart';
import 'package:optiflow/features/vision_training/presentation/viewmodels/saccadic_jumps_viewmodel.dart'
    show ExerciseDuration, ExerciseStatus;

enum PeripheralPattern {
  expandingCircles('Anillos'),
  contractingSquares('Marcos'),
  pulsingTarget('Pulso');

  const PeripheralPattern(this.label);
  final String label;
}

class _Absent {
  const _Absent();
}

const _absent = _Absent();

class PeripheralExpansionState {
  const PeripheralExpansionState({
    this.pattern = PeripheralPattern.expandingCircles,
    this.status = ExerciseStatus.idle,
    this.speedMs = _defaultSpeedMs,
    this.isSoundEnabled = true,
    this.minSpeedMs = _minSpeed,
    this.maxSpeedMs = _maxSpeed,
    this.selectedDuration = ExerciseDuration.s60,
    this.timeLeftSeconds,
  });

  static const int _defaultSpeedMs = 1500;
  static const int _minSpeed = 500;
  static const int _maxSpeed = 3000;

  final PeripheralPattern pattern;
  final ExerciseStatus status;
  final int speedMs;
  final bool isSoundEnabled;
  final int minSpeedMs;
  final int maxSpeedMs;
  final ExerciseDuration selectedDuration;
  final int? timeLeftSeconds;

  PeripheralExpansionState copyWith({
    PeripheralPattern? pattern,
    ExerciseStatus? status,
    int? speedMs,
    bool? isSoundEnabled,
    ExerciseDuration? selectedDuration,
    Object? timeLeftSeconds = _absent,
  }) {
    return PeripheralExpansionState(
      pattern: pattern ?? this.pattern,
      status: status ?? this.status,
      speedMs: speedMs ?? this.speedMs,
      isSoundEnabled: isSoundEnabled ?? this.isSoundEnabled,
      minSpeedMs: minSpeedMs,
      maxSpeedMs: maxSpeedMs,
      selectedDuration: selectedDuration ?? this.selectedDuration,
      timeLeftSeconds: timeLeftSeconds is _Absent
          ? this.timeLeftSeconds
          : timeLeftSeconds as int?,
    );
  }
}

class PeripheralExpansionNotifier extends Notifier<PeripheralExpansionState> {
  Timer? _countdownTimer;

  @override
  PeripheralExpansionState build() {
    ref.onDispose(_cancelCountdown);
    return const PeripheralExpansionState();
  }

  void setPattern(PeripheralPattern p) {
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
    if (seconds != null) {
      _startCountdown();
    }
  }

  void stopAndSave() {
    if (state.status != ExerciseStatus.active) return;
    _cancelCountdown();
    state = state.copyWith(status: ExerciseStatus.saving);
    _persist();
  }

  Future<void> _persist() async {
    await ref
        .read(progressRepositoryProvider)
        .saveProgress(
          exerciseType: 'peripheral_expansion',
          maxSpeedMs: state.speedMs,
        );
    state = state.copyWith(status: ExerciseStatus.saved);
  }

  void toggleSound() {
    state = state.copyWith(isSoundEnabled: !state.isSoundEnabled);
  }

  void reset() {
    _cancelCountdown();
    state = PeripheralExpansionState(
      isSoundEnabled: state.isSoundEnabled,
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

final peripheralExpansionProvider =
    NotifierProvider<PeripheralExpansionNotifier, PeripheralExpansionState>(
      PeripheralExpansionNotifier.new,
    );
