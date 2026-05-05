import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:optiflow/core/database/progress_repository.dart';
import 'package:optiflow/core/utils/audio_service.dart';
import 'package:optiflow/features/vision_training/domain/pursuit_pattern.dart';
import 'package:optiflow/features/vision_training/presentation/viewmodels/saccadic_jumps_viewmodel.dart'
    show ExerciseStatus;

class SmoothPursuitState {
  const SmoothPursuitState({
    this.pattern = PursuitPattern.circle,
    this.status = ExerciseStatus.idle,
    this.speedMs = _defaultSpeedMs,
    this.isMuted = false,
    this.minSpeedMs = _minSpeed,
    this.maxSpeedMs = _maxSpeed,
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

  SmoothPursuitState copyWith({
    PursuitPattern? pattern,
    ExerciseStatus? status,
    int? speedMs,
    bool? isMuted,
  }) {
    return SmoothPursuitState(
      pattern: pattern ?? this.pattern,
      status: status ?? this.status,
      speedMs: speedMs ?? this.speedMs,
      isMuted: isMuted ?? this.isMuted,
      minSpeedMs: minSpeedMs,
      maxSpeedMs: maxSpeedMs,
    );
  }
}

class SmoothPursuitNotifier extends Notifier<SmoothPursuitState> {
  @override
  SmoothPursuitState build() => const SmoothPursuitState();

  void setPattern(PursuitPattern p) {
    if (state.status != ExerciseStatus.idle) return;
    state = state.copyWith(pattern: p);
  }

  void setSpeed(int ms) => state = state.copyWith(speedMs: ms);

  void startExercise() {
    if (state.status == ExerciseStatus.active) return;
    state = state.copyWith(status: ExerciseStatus.active);
    if (!state.isMuted) {
      ref.read(audioServiceProvider).playBgm();
    }
  }

  void stopAndSave() {
    if (state.status != ExerciseStatus.active) return;
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
    ref.read(audioServiceProvider).stopBgm();
    state = const SmoothPursuitState();
  }
}

final smoothPursuitProvider =
    NotifierProvider<SmoothPursuitNotifier, SmoothPursuitState>(
      SmoothPursuitNotifier.new,
    );
