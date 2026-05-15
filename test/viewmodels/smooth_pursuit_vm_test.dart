import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:optiflow/core/database/progress_repository.dart';
import 'package:optiflow/core/utils/audio_cue.dart';
import 'package:optiflow/core/utils/audio_service.dart';
import 'package:optiflow/features/vision_training/presentation/viewmodels/saccadic_jumps_viewmodel.dart'
    show ExerciseDuration, ExerciseStatus;
import 'package:optiflow/features/vision_training/presentation/viewmodels/smooth_pursuit_viewmodel.dart';

class _FakeAudioService extends AudioService {
  final List<AudioCue> played = [];

  @override
  Future<void> init() async {}

  @override
  Future<void> play(AudioCue cue) async => played.add(cue);

  @override
  Future<void> playBgm({double volume = 0.5}) async {}

  @override
  Future<void> stopBgm() async {}
}

class _FakeProgressRepository implements ProgressRepository {
  @override
  Future<void> saveProgress({
    required String exerciseType,
    required int maxSpeedMs,
  }) async {}
}

ProviderContainer _makeContainer({AudioService? audio}) => ProviderContainer(
  overrides: [
    audioServiceProvider.overrideWithValue(audio ?? _FakeAudioService()),
    progressRepositoryProvider.overrideWithValue(_FakeProgressRepository()),
  ],
);

void main() {
  group('SmoothPursuitNotifier initial state', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('default speedMs is 3000', () {
      expect(container.read(smoothPursuitProvider).speedMs, 3000);
    });

    test('minSpeedMs is 1500', () {
      expect(container.read(smoothPursuitProvider).minSpeedMs, 1500);
    });

    test('maxSpeedMs is 5000', () {
      expect(container.read(smoothPursuitProvider).maxSpeedMs, 5000);
    });
  });

  group('SmoothPursuitNotifier ExerciseDuration', () {
    test('default selectedDuration is s60', () {
      final container = _makeContainer();
      addTearDown(container.dispose);
      expect(
        container.read(smoothPursuitProvider).selectedDuration,
        ExerciseDuration.s60,
      );
    });

    test('setDuration changes selectedDuration when idle', () {
      final container = _makeContainer();
      addTearDown(container.dispose);
      container
          .read(smoothPursuitProvider.notifier)
          .setDuration(ExerciseDuration.m2);
      expect(
        container.read(smoothPursuitProvider).selectedDuration,
        ExerciseDuration.m2,
      );
    });

    test('selectedDuration preserved after reset', () {
      final container = _makeContainer();
      addTearDown(container.dispose);
      container
          .read(smoothPursuitProvider.notifier)
          .setDuration(ExerciseDuration.s30);
      container.read(smoothPursuitProvider.notifier).reset();
      expect(
        container.read(smoothPursuitProvider).selectedDuration,
        ExerciseDuration.s30,
      );
    });
  });

  group('SmoothPursuitNotifier countdown', () {
    test('startExercise with finite duration sets timeLeftSeconds', () {
      fakeAsync((async) {
        final container = _makeContainer();
        addTearDown(container.dispose);
        container
            .read(smoothPursuitProvider.notifier)
            .setDuration(ExerciseDuration.s30);
        container.read(smoothPursuitProvider.notifier).startExercise();

        expect(container.read(smoothPursuitProvider).timeLeftSeconds, 30);
        async.elapse(const Duration(seconds: 1));
        expect(container.read(smoothPursuitProvider).timeLeftSeconds, 29);
      });
    });

    test('startExercise with infinite duration keeps timeLeftSeconds null', () {
      fakeAsync((async) {
        final container = _makeContainer();
        addTearDown(container.dispose);
        container
            .read(smoothPursuitProvider.notifier)
            .setDuration(ExerciseDuration.infinite);
        container.read(smoothPursuitProvider.notifier).startExercise();

        async.elapse(const Duration(seconds: 5));
        expect(container.read(smoothPursuitProvider).timeLeftSeconds, isNull);
      });
    });

    test('countdown auto-stops and plays success at zero', () {
      fakeAsync((async) {
        final audio = _FakeAudioService();
        final container = _makeContainer(audio: audio);
        addTearDown(container.dispose);
        container
            .read(smoothPursuitProvider.notifier)
            .setDuration(ExerciseDuration.s30);
        container.read(smoothPursuitProvider.notifier).startExercise();

        async
          ..elapse(const Duration(seconds: 30))
          ..flushMicrotasks();

        expect(
          container.read(smoothPursuitProvider).status,
          ExerciseStatus.saved,
        );
        expect(audio.played, contains(AudioCue.success));
      });
    });
  });
}
