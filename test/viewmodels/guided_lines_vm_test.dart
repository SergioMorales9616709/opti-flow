import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:optiflow/core/database/progress_repository.dart';
import 'package:optiflow/core/utils/audio_cue.dart';
import 'package:optiflow/core/utils/audio_service.dart';
import 'package:optiflow/features/speed_reading/data/text_repository.dart';
import 'package:optiflow/features/speed_reading/presentation/viewmodels/guided_lines_viewmodel.dart';

// ---------------------------------------------------------------------------
// Fakes — identical structure to rsvp_vm_test.dart
// ---------------------------------------------------------------------------

class _FakeAudioService extends AudioService {
  bool bgmPlaying = false;
  @override
  Future<void> init() async {}
  @override
  Future<void> play(AudioCue cue) async {}
  @override
  Future<void> playBgm({double volume = 0.5}) async => bgmPlaying = true;
  @override
  Future<void> stopBgm() async => bgmPlaying = false;
}

class _FakeProgressRepository implements ProgressRepository {
  String? savedType;
  int? savedValue;
  @override
  Future<void> saveProgress({
    required String exerciseType,
    required int maxSpeedMs,
  }) async {
    savedType = exerciseType;
    savedValue = maxSpeedMs;
  }
}

class _FakeTextRepository implements TextRepository {
  _FakeTextRepository(this.words);
  final List<String> words;
  @override
  Future<List<String>> loadWords(String assetPath) async => words;
}

ProviderContainer _makeContainer({
  List<String> words = const ['Hola', 'mundo.'],
  _FakeAudioService? audio,
  _FakeProgressRepository? repo,
}) {
  return ProviderContainer(
    overrides: [
      audioServiceProvider.overrideWithValue(audio ?? _FakeAudioService()),
      progressRepositoryProvider.overrideWithValue(
        repo ?? _FakeProgressRepository(),
      ),
      textRepositoryProvider.overrideWithValue(_FakeTextRepository(words)),
    ],
  );
}

// Helper: wait until text is loaded
Future<void> _waitLoaded(ProviderContainer c) async {
  while (!c.read(guidedLinesProvider).isLoaded) {
    await Future<void>.delayed(Duration.zero);
  }
}

// ---------------------------------------------------------------------------
// msForLine
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('msForLine', () {
    test('calculates ms based on word count at 300 WPM', () {
      // 300 WPM → 200 ms/word. "Hola mundo" = 2 words → 400 ms.
      expect(msForLine('Hola mundo', 300), 400);
    });

    test('single word line', () {
      expect(msForLine('Hola', 300), 200);
    });

    test('scales with WPM', () {
      // 600 WPM → 100 ms/word. 3 words → 300 ms.
      expect(msForLine('uno dos tres', 600), 300);
    });
  });

  // ---------------------------------------------------------------------------
  // Initial state
  // ---------------------------------------------------------------------------

  group('GuidedLinesNotifier initial state', () {
    late ProviderContainer container;
    setUp(() => container = _makeContainer());
    tearDown(() => container.dispose());

    test('currentWpm is 300', () {
      expect(container.read(guidedLinesProvider).currentWpm, 300);
    });

    test('isPlaying is false', () {
      expect(container.read(guidedLinesProvider).isPlaying, isFalse);
    });

    test('isMuted is false', () {
      expect(container.read(guidedLinesProvider).isMuted, isFalse);
    });

    test('currentLineIndex is 0', () {
      expect(container.read(guidedLinesProvider).currentLineIndex, 0);
    });

    test('isLoaded becomes true after text loads', () async {
      await _waitLoaded(container);
      expect(container.read(guidedLinesProvider).isLoaded, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // setWpm
  // ---------------------------------------------------------------------------

  group('GuidedLinesNotifier.setWpm', () {
    late ProviderContainer container;
    setUp(() => container = _makeContainer());
    tearDown(() => container.dispose());

    test('updates currentWpm', () {
      container.read(guidedLinesProvider.notifier).setWpm(500);
      expect(container.read(guidedLinesProvider).currentWpm, 500);
    });

    test('clamps to min 200', () {
      container.read(guidedLinesProvider.notifier).setWpm(50);
      expect(container.read(guidedLinesProvider).currentWpm, 200);
    });

    test('clamps to max 2400', () {
      container.read(guidedLinesProvider.notifier).setWpm(9999);
      expect(container.read(guidedLinesProvider).currentWpm, 2400);
    });
  });

  // ---------------------------------------------------------------------------
  // paginate
  // ---------------------------------------------------------------------------

  group('GuidedLinesNotifier.paginate', () {
    late ProviderContainer container;
    setUp(() => container = _makeContainer(words: ['Hola', 'mundo', 'feliz']));
    tearDown(() => container.dispose());

    test('populates lines after text is loaded', () async {
      await _waitLoaded(container);
      container
          .read(guidedLinesProvider.notifier)
          .paginate(
            800,
            const TextStyle(fontSize: 32, fontWeight: FontWeight.w400),
          );
      expect(container.read(guidedLinesProvider).lines, isNotEmpty);
    });

    test('resets currentLineIndex to 0 on re-paginate', () async {
      await _waitLoaded(container);
      container.read(guidedLinesProvider.notifier)
        ..paginate(800, const TextStyle(fontSize: 32))
        ..paginate(800, const TextStyle(fontSize: 32));
      expect(container.read(guidedLinesProvider).currentLineIndex, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // pause
  // ---------------------------------------------------------------------------

  group('GuidedLinesNotifier.pause', () {
    late ProviderContainer container;
    setUp(() => container = _makeContainer());
    tearDown(() => container.dispose());

    test('sets isPlaying to false', () {
      container.read(guidedLinesProvider.notifier).pause();
      expect(container.read(guidedLinesProvider).isPlaying, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // toggleMute
  // ---------------------------------------------------------------------------

  group('GuidedLinesNotifier.toggleMute', () {
    late ProviderContainer container;
    setUp(() => container = _makeContainer());
    tearDown(() => container.dispose());

    test('flips isMuted from false to true', () {
      container.read(guidedLinesProvider.notifier).toggleMute();
      expect(container.read(guidedLinesProvider).isMuted, isTrue);
    });

    test('flips isMuted back to false', () {
      container.read(guidedLinesProvider.notifier)
        ..toggleMute()
        ..toggleMute();
      expect(container.read(guidedLinesProvider).isMuted, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // persist uses correct exercise_type
  // ---------------------------------------------------------------------------

  group('GuidedLinesNotifier persistence', () {
    test('saves speed_reading_guided_lines on pause', () async {
      final repo = _FakeProgressRepository();
      final c = _makeContainer(repo: repo);
      addTearDown(c.dispose);
      await _waitLoaded(c);
      c.read(guidedLinesProvider.notifier)
        ..paginate(800, const TextStyle(fontSize: 32))
        ..pause();
      await Future<void>.delayed(Duration.zero);
      expect(repo.savedType, 'speed_reading_guided_lines');
    });
  });
}
