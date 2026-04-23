import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/database/progress_repository.dart';

enum StimulusPosition { left, right }

enum ExerciseStatus { idle, active, saving, saved }

class SaccadicJumpsState {
  final StimulusPosition position;
  final ExerciseStatus status;
  final int speedMs;
  final int minSpeedMs;
  final int maxSpeedMs;

  const SaccadicJumpsState({
    required this.position,
    required this.status,
    required this.speedMs,
    required this.minSpeedMs,
    required this.maxSpeedMs,
  });

  SaccadicJumpsState copyWith({
    StimulusPosition? position,
    ExerciseStatus? status,
    int? speedMs,
  }) {
    return SaccadicJumpsState(
      position: position ?? this.position,
      status: status ?? this.status,
      speedMs: speedMs ?? this.speedMs,
      minSpeedMs: minSpeedMs,
      maxSpeedMs: maxSpeedMs,
    );
  }
}

class SaccadicJumpsNotifier extends Notifier<SaccadicJumpsState> {
  static const int _defaultSpeedMs = 800;
  static const int _minSpeedMs = 200;
  static const int _maxSpeedMs = 1000;

  Timer? _timer;

  @override
  SaccadicJumpsState build() {
    ref.onDispose(_cancelTimer);
    return const SaccadicJumpsState(
      position: StimulusPosition.left,
      status: ExerciseStatus.idle,
      speedMs: _defaultSpeedMs,
      minSpeedMs: _minSpeedMs,
      maxSpeedMs: _maxSpeedMs,
    );
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

  void reset() {
    _cancelTimer();
    state = const SaccadicJumpsState(
      position: StimulusPosition.left,
      status: ExerciseStatus.idle,
      speedMs: _defaultSpeedMs,
      minSpeedMs: _minSpeedMs,
      maxSpeedMs: _maxSpeedMs,
    );
  }

  void _startTimer(int ms) {
    _cancelTimer();
    _timer = Timer.periodic(Duration(milliseconds: ms), (_) {
      state = state.copyWith(
        position: state.position == StimulusPosition.left
            ? StimulusPosition.right
            : StimulusPosition.left,
      );
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
