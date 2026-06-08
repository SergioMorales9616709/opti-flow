import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:optiflow/core/database/database_helper.dart';
import 'package:optiflow/core/database/progress_repository.dart';
import 'package:optiflow/core/utils/audio_cue.dart';
import 'package:optiflow/core/utils/audio_service.dart';
import 'package:optiflow/features/speed_reading/data/text_repository.dart';
import 'package:optiflow/features/speed_reading/presentation/viewmodels/book_mode_viewmodel.dart';
import 'package:optiflow/features/speed_reading/presentation/viewmodels/guided_lines_viewmodel.dart';
import 'package:optiflow/features/speed_reading/presentation/views/book_mode_view.dart';
import 'package:optiflow/features/speed_reading/presentation/views/guided_lines_view.dart';

// ---------------------------------------------------------------------------
// Fakes — identical structure to guided_lines_vm_test.dart
// ---------------------------------------------------------------------------

class _FakeAudioService extends AudioService {
  @override
  Future<void> init() async {}
  @override
  Future<void> play(AudioCue cue) async {}
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

class _FakeTextRepository implements TextRepository {
  _FakeTextRepository(this.words);
  final List<String> words;
  @override
  Future<List<String>> loadWords(String assetPath) async => words;
}

// Long enough that pagination produces several lines per column — exercises
// the same wrapping math that overflowed in the field.
final _longText = List.generate(220, (i) => 'palabra$i').join(' ');

// Mixed-length, accented, punctuated words — unlike `_longText`'s uniform
// "palabra0 palabra1 ..." this produces lines whose width sits close to the
// column boundary, the way real prose (`cuento_1.txt`) does. That borderline
// width is what exposes the bug where a line measured to "fit" at the
// inactive `FontWeight.w400` rendering wraps to two visual lines the moment
// it becomes the active line and re-renders bolder (`FontWeight.w600`),
// overflowing its fixed-height row.
final _borderlineWords = List.generate(300, (i) {
  const alphabet = 'abcdefghijklmnopqrstuvwxyzáéíóúñ';
  final length = 3 + (i % 10);
  final word = List.generate(
    length,
    (j) => alphabet[(i + j) % alphabet.length],
  ).join();
  final suffix = i % 7 == 0 ? '.' : (i % 5 == 0 ? ',' : '');
  return '$word$suffix';
});

Future<void> _pumpAndPaginate(
  WidgetTester tester,
  Widget view, {
  List<String>? words,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        audioServiceProvider.overrideWithValue(_FakeAudioService()),
        progressRepositoryProvider.overrideWithValue(_FakeProgressRepository()),
        textRepositoryProvider.overrideWithValue(
          _FakeTextRepository(words ?? _longText.split(' ')),
        ),
      ],
      child: MaterialApp(home: view),
    ),
  );
  // Lets the async text load resolve and the post-frame pagination callback
  // run against the current (possibly small) window size.
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await DatabaseHelper.initializeForTesting();
  });

  // Regression coverage for the bug where `paginateTextIntoLines` measured
  // against a wider width than what the Text glyphs actually render into
  // (column/tile padding wasn't subtracted). Paginated "lines" then wrapped
  // to multiple visual lines inside fixed-height rows, blowing past
  // `maxLinesPerPage` and triggering "BOTTOM OVERFLOWED BY n PIXELS".
  for (final size in [const Size(900, 600), const Size(1280, 720)]) {
    testWidgets('BookModeView renders without overflow at '
        '${size.width.toInt()}x${size.height.toInt()}', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpAndPaginate(tester, const BookModeView());

      expect(tester.takeException(), isNull);
      expect(find.textContaining('OVERFLOWED'), findsNothing);
    });

    testWidgets('GuidedLinesView renders without overflow at '
        '${size.width.toInt()}x${size.height.toInt()}', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpAndPaginate(tester, const GuidedLinesView());

      expect(tester.takeException(), isNull);
      expect(find.textContaining('OVERFLOWED'), findsNothing);
    });
  }

  // Regression coverage for the bug where pagination measured lines against
  // the inactive `FontWeight.w400` style, but the active line renders bolder
  // (`FontWeight.w600` — wider glyphs). A line that "fit" while inactive
  // could wrap to two visual lines the instant it became active, blowing
  // past its fixed-height row and triggering "BOTTOM OVERFLOWED BY n PIXELS".
  // Driving an actual reading session — so each line takes its turn as the
  // active (bold) line — is the only way to exercise that render path.
  group('overflow while actively reading (active-line bold re-render)', () {
    testWidgets('BookModeView stays overflow-free through a reading pass', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1024, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpAndPaginate(
        tester,
        const BookModeView(),
        words: _borderlineWords,
      );

      final notifier = ProviderScope.containerOf(
        tester.element(find.byType(BookModeView)),
      ).read(bookModeProvider.notifier)..setWpm(2400);
      unawaited(notifier.startReading());

      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 30));
        expect(tester.takeException(), isNull);
        expect(find.textContaining('OVERFLOWED'), findsNothing);
      }

      // Stop the loop, then flush the one in-flight `Future.delayed` so no
      // Timer remains pending when the widget tree is disposed.
      notifier.pause();
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('GuidedLinesView stays overflow-free through a reading pass', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1024, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpAndPaginate(
        tester,
        const GuidedLinesView(),
        words: _borderlineWords,
      );

      final notifier = ProviderScope.containerOf(
        tester.element(find.byType(GuidedLinesView)),
      ).read(guidedLinesProvider.notifier)..setWpm(2400);
      unawaited(notifier.startReading());

      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 30));
        expect(tester.takeException(), isNull);
        expect(find.textContaining('OVERFLOWED'), findsNothing);
      }

      // Stop the loop, then flush the one in-flight `Future.delayed` so no
      // Timer remains pending when the widget tree is disposed.
      notifier.pause();
      await tester.pump(const Duration(milliseconds: 200));
    });
  });

  // Regression coverage for the bug where pagination ran exactly once, on
  // first layout. Lines were measured to fit the *initial* window width;
  // shrinking the window afterwards left those same (now too-wide) lines on
  // screen, so several wrapped to two visual lines at once inside their
  // fixed-height rows — a much larger cumulative "BOTTOM OVERFLOWED BY n
  // PIXELS" than a single borderline line wrapping. Re-running pagination
  // whenever the measured width changes is what fixes this.
  group('overflow after window resize (stale pagination)', () {
    testWidgets('BookModeView re-paginates and stays overflow-free '
        'after shrinking', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpAndPaginate(
        tester,
        const BookModeView(),
        words: _borderlineWords,
      );
      expect(find.textContaining('OVERFLOWED'), findsNothing);

      // Shrink the window — columns are now noticeably narrower than what
      // the on-screen lines were paginated for.
      await tester.binding.setSurfaceSize(const Size(720, 480));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('OVERFLOWED'), findsNothing);
    });

    testWidgets('GuidedLinesView re-paginates and stays overflow-free '
        'after shrinking', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpAndPaginate(
        tester,
        const GuidedLinesView(),
        words: _borderlineWords,
      );
      expect(find.textContaining('OVERFLOWED'), findsNothing);

      // Shrink the window — the list is now noticeably narrower than what
      // the on-screen lines were paginated for.
      await tester.binding.setSurfaceSize(const Size(720, 480));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('OVERFLOWED'), findsNothing);
    });
  });
}
