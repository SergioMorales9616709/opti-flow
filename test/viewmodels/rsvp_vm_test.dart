import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:optiflow/core/database/progress_repository.dart';
import 'package:optiflow/core/utils/audio_cue.dart';
import 'package:optiflow/core/utils/audio_service.dart';
import 'package:optiflow/features/speed_reading/data/text_repository.dart';
import 'package:optiflow/features/speed_reading/presentation/viewmodels/rsvp_viewmodel.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeAudioService extends AudioService {
  final List<AudioCue> played = [];
  bool bgmPlaying = false;

  @override
  Future<void> init() async {}

  @override
  Future<void> play(AudioCue cue) async => played.add(cue);

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
  final a = audio ?? _FakeAudioService();
  final r = repo ?? _FakeProgressRepository();
  return ProviderContainer(
    overrides: [
      audioServiceProvider.overrideWithValue(a),
      progressRepositoryProvider.overrideWithValue(r),
      textRepositoryProvider.overrideWithValue(_FakeTextRepository(words)),
    ],
  );
}

// ---------------------------------------------------------------------------
// pauseMsFor
// ---------------------------------------------------------------------------

void main() {
  group('pauseMsFor', () {
    const wpm = 300; // base = 60000 ~/ 300 = 200 ms

    test('returns base ms for a normal word', () {
      expect(pauseMsFor('hola', wpm), 200);
    });

    test('returns 1.5x base for a word ending in comma', () {
      expect(pauseMsFor('casa,', wpm), (200 * 1.5).round());
    });

    test('returns 2.5x base for a word ending in period', () {
      expect(pauseMsFor('fin.', wpm), (200 * 2.5).round());
    });

    test('returns 2.5x base for a word ending in question mark', () {
      expect(pauseMsFor('bien?', wpm), (200 * 2.5).round());
    });

    test('returns 2.5x base for a word ending in exclamation mark', () {
      expect(pauseMsFor('genial!', wpm), (200 * 2.5).round());
    });

    test('returns 2.5x base for a word ending in colon', () {
      expect(pauseMsFor('resultado:', wpm), (200 * 2.5).round());
    });

    test('returns 2.5x base for a word ending in semicolon', () {
      expect(pauseMsFor('primero;', wpm), (200 * 2.5).round());
    });

    test('scales correctly at 600 WPM', () {
      const base = 60000 ~/ 600; // 100 ms
      expect(pauseMsFor('normal', 600), base);
      expect(pauseMsFor('pausa,', 600), (base * 1.5).round());
      expect(pauseMsFor('fin.', 600), (base * 2.5).round());
    });
  });

  // ---------------------------------------------------------------------------
  // RsvpNotifier initial state
  // ---------------------------------------------------------------------------

  group('RsvpNotifier initial state', () {
    late ProviderContainer container;

    setUp(() => container = _makeContainer());
    tearDown(() => container.dispose());

    test('currentWpm is 300', () {
      expect(container.read(rsvpProvider).currentWpm, 300);
    });

    test('isPlaying is false', () {
      expect(container.read(rsvpProvider).isPlaying, isFalse);
    });

    test('isMuted is false', () {
      expect(container.read(rsvpProvider).isMuted, isFalse);
    });

    test('currentIndex is 0', () {
      expect(container.read(rsvpProvider).currentIndex, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // setWpm
  // ---------------------------------------------------------------------------

  group('RsvpNotifier.setWpm', () {
    late ProviderContainer container;

    setUp(() => container = _makeContainer());
    tearDown(() => container.dispose());

    test('updates currentWpm', () {
      container.read(rsvpProvider.notifier).setWpm(500);
      expect(container.read(rsvpProvider).currentWpm, 500);
    });

    test('clamps to min 200', () {
      container.read(rsvpProvider.notifier).setWpm(50);
      expect(container.read(rsvpProvider).currentWpm, 200);
    });

    test('clamps to max 1200', () {
      container.read(rsvpProvider.notifier).setWpm(9999);
      expect(container.read(rsvpProvider).currentWpm, 1200);
    });
  });

  // ---------------------------------------------------------------------------
  // pause
  // ---------------------------------------------------------------------------

  group('RsvpNotifier.pause', () {
    late ProviderContainer container;

    setUp(() => container = _makeContainer());
    tearDown(() => container.dispose());

    test('sets isPlaying to false', () async {
      container.read(rsvpProvider.notifier).pause();
      expect(container.read(rsvpProvider).isPlaying, isFalse);
    });

    test('stops BGM when playing', () async {
      final audio = _FakeAudioService();
      final c = _makeContainer(audio: audio);
      addTearDown(c.dispose);
      // Drain the microtask chain until _loadText() has set words.
      while (!c.read(rsvpProvider).isLoaded) {
        await Future<void>.delayed(Duration.zero);
      }
      // startReading sets isPlaying:true synchronously before the first await.
      unawaited(c.read(rsvpProvider.notifier).startReading());
      expect(c.read(rsvpProvider).isPlaying, isTrue);
      c.read(rsvpProvider.notifier).pause();
      expect(audio.bgmPlaying, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // toggleMute
  // ---------------------------------------------------------------------------

  group('RsvpNotifier.toggleMute', () {
    late ProviderContainer container;

    setUp(() => container = _makeContainer());
    tearDown(() => container.dispose());

    test('flips isMuted from false to true', () {
      container.read(rsvpProvider.notifier).toggleMute();
      expect(container.read(rsvpProvider).isMuted, isTrue);
    });

    test('flips isMuted back to false', () {
      container.read(rsvpProvider.notifier)
        ..toggleMute()
        ..toggleMute();
      expect(container.read(rsvpProvider).isMuted, isFalse);
    });
  });
}
