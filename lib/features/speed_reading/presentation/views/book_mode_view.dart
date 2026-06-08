import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:optiflow/features/speed_reading/presentation/viewmodels/book_mode_viewmodel.dart';
import 'package:optiflow/features/vision_training/presentation/viewmodels/saccadic_jumps_viewmodel.dart'
    show ExerciseDuration;

const _kFontSize = 24.0;

// Line height expressed as a multiple of `fontSize`, applied via
// `TextStyle.height` so Flutter reserves the full glyph box (including
// descenders on letters like p/g/y and accents) instead of clipping it
// inside an externally-forced box. The per-line height used for pagination
// and the page-flip math is derived from this — never hardcoded — so the
// two always agree with what's physically on screen.
const _kLineHeightMultiplier = 2.0;
const _kLineHeight = _kFontSize * _kLineHeightMultiplier;

// Width reserved for the central "spine" — the gutter that keeps the two
// columns from touching, with a subtle divider drawn through its middle.
const _kSpineWidth = 32.0;

const _kHorizontalPadding = 24.0;

// Every horizontal inset between a column's width and its Text glyphs —
// _BookColumn padding + _BookLineTile padding (each applied on both sides).
// `paginateTextIntoLines` must measure against this *exact* width; otherwise
// lines that "fit" on paper wrap when rendered, blowing past the strict
// per-row height and overflowing the page.
const _kColumnHorizontalPadding = 8.0;
const _kLineHorizontalPadding = 8.0;
const _kTextHorizontalChrome =
    (_kColumnHorizontalPadding + _kLineHorizontalPadding) * 2;

// The style used for pagination measurement, and the upper bound for
// rendering. `_BookLineTile` renders the active line in `FontWeight.w600`
// (bolder — and therefore wider — than the w400 used for inactive lines), so
// measurement must use w600 too: a line that fits at its widest possible
// render weight is guaranteed to fit at every weight, whether or not it is
// the active line when paginated. Using w400 here let "fitting" lines wrap
// the moment they became active and rendered bold, overflowing their
// fixed-height row. The explicit `height` keeps the measured line box in
// sync with the rendered one.
TextStyle _lineStyle(BuildContext context) => TextStyle(
  fontSize: _kFontSize,
  fontWeight: FontWeight.w600,
  height: _kLineHeightMultiplier,
  color: Theme.of(context).colorScheme.onSurface,
);

class BookModeView extends ConsumerStatefulWidget {
  const BookModeView({super.key});

  @override
  ConsumerState<BookModeView> createState() => _BookModeViewState();
}

class _BookModeViewState extends ConsumerState<BookModeView> {
  bool _paginationScheduled = false;

  // The text width pagination last ran against. Re-paginating only on the
  // very first layout meant that resizing the window afterwards left the
  // existing lines measured for the *old* width — they'd wrap when rendered
  // into the new (e.g. narrower) columns, overflowing their fixed-height
  // rows. Tracking this lets us re-run pagination whenever the available
  // width actually changes, not just once.
  double? _paginatedTextWidth;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLoaded = ref.watch(bookModeProvider.select((s) => s.isLoaded));
    final lines = ref.watch(bookModeProvider.select((s) => s.lines));
    final isPlaying = ref.watch(bookModeProvider.select((s) => s.isPlaying));
    final isMuted = ref.watch(bookModeProvider.select((s) => s.isMuted));
    final currentWpm = ref.watch(bookModeProvider.select((s) => s.currentWpm));
    final currentLineIndex = ref.watch(
      bookModeProvider.select((s) => s.currentLineIndex),
    );
    final selectedDuration = ref.watch(
      bookModeProvider.select((s) => s.selectedDuration),
    );
    final timeLeftSeconds = ref.watch(
      bookModeProvider.select((s) => s.timeLeftSeconds),
    );

    final notifier = ref.read(bookModeProvider.notifier);
    final progress = lines.isEmpty ? 0.0 : currentLineIndex / lines.length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Book area ──────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: _kHorizontalPadding,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxLinesPerPage =
                        (constraints.maxHeight / _kLineHeight).floor();
                    final columnWidth =
                        (constraints.maxWidth - _kSpineWidth) / 2;
                    final textWidth = columnWidth - _kTextHorizontalChrome;

                    // (Re)paginate whenever the measured text width hasn't
                    // been seen yet — first layout, or a resize that changed
                    // the column width enough to invalidate existing lines.
                    final widthChanged =
                        _paginatedTextWidth == null ||
                        (textWidth - _paginatedTextWidth!).abs() > 0.5;
                    if (isLoaded && widthChanged && !_paginationScheduled) {
                      _paginationScheduled = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _paginationScheduled = false;
                        if (mounted) {
                          _paginatedTextWidth = textWidth;
                          notifier.paginate(
                            textWidth,
                            _lineStyle(context),
                            textScaler: MediaQuery.textScalerOf(context),
                          );
                        }
                      });
                    }

                    // While re-pagination is pending, `lines` still holds
                    // entries measured for the *previous* width — rendering
                    // them against the new layout constraints is exactly
                    // what overflowed. Show the loading state instead until
                    // pagination catches up and the widths agree again.
                    if (!isLoaded ||
                        lines.isEmpty ||
                        maxLinesPerPage <= 0 ||
                        widthChanged) {
                      return Center(
                        child: CircularProgressIndicator(color: cs.primary),
                      );
                    }

                    // "Page Flip": derive which double-page is on screen
                    // straight from currentLineIndex — no scrolling, just a
                    // static rebuild when the index crosses a page boundary.
                    final linesPerDoublePage = maxLinesPerPage * 2;
                    final doublePageIndex =
                        currentLineIndex ~/ linesPerDoublePage;
                    final startIndex = doublePageIndex * linesPerDoublePage;
                    final endIndex = math.min(
                      startIndex + linesPerDoublePage,
                      lines.length,
                    );
                    final visibleLines = lines.sublist(startIndex, endIndex);

                    final leftCount = math.min(
                      maxLinesPerPage,
                      visibleLines.length,
                    );
                    final leftLines = visibleLines.sublist(0, leftCount);
                    final rightLines = visibleLines.sublist(leftCount);

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _BookColumn(
                            lines: leftLines,
                            startGlobalIndex: startIndex,
                            currentLineIndex: currentLineIndex,
                          ),
                        ),
                        VerticalDivider(
                          width: _kSpineWidth,
                          thickness: 1,
                          color: cs.outlineVariant.withValues(alpha: 0.35),
                        ),
                        Expanded(
                          child: _BookColumn(
                            lines: rightLines,
                            startGlobalIndex: startIndex + leftCount,
                            currentLineIndex: currentLineIndex,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // ── Control panel ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row 1: WPM label + Mute
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$currentWpm WPM',
                        style: TextStyle(
                          color: cs.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                      IconButton(
                        onPressed: notifier.toggleMute,
                        icon: Icon(
                          isMuted ? Icons.volume_off : Icons.volume_up,
                          color: isMuted
                              ? cs.onSurface.withValues(alpha: 0.4)
                              : cs.primary,
                        ),
                        tooltip: isMuted ? 'Activar audio' : 'Silenciar',
                      ),
                    ],
                  ),

                  // Row 2: Speed slider + duration selector
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: currentWpm.toDouble(),
                          min: 200,
                          max: 2400,
                          label: '$currentWpm WPM',
                          activeColor: cs.primary,
                          inactiveColor: cs.surfaceContainerHighest,
                          onChanged: (v) => notifier.setWpm(v.round()),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SegmentedButton<ExerciseDuration>(
                        segments: ExerciseDuration.values
                            .map(
                              (d) =>
                                  ButtonSegment(value: d, label: Text(d.label)),
                            )
                            .toList(),
                        selected: {selectedDuration},
                        onSelectionChanged: isPlaying
                            ? null
                            : (s) => notifier.setDuration(s.first),
                      ),
                    ],
                  ),

                  // Row 3: Back | Progress | Timer | Play/Pause
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          notifier.pause();
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.arrow_back_ios, size: 14),
                        label: const Text('ATRÁS'),
                        style: TextButton.styleFrom(
                          foregroundColor: cs.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: cs.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              cs.primary,
                            ),
                            borderRadius: BorderRadius.circular(4),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      if (isPlaying &&
                          selectedDuration != ExerciseDuration.infinite &&
                          timeLeftSeconds != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: cs.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Builder(
                              builder: (context) {
                                final t = timeLeftSeconds;
                                final mm = (t ~/ 60).toString().padLeft(2, '0');
                                final ss = (t % 60).toString().padLeft(2, '0');
                                return Text(
                                  '$mm:$ss',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: cs.primary,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      IconButton(
                        onPressed: (isLoaded && lines.isNotEmpty)
                            ? () => isPlaying
                                  ? notifier.pause()
                                  : notifier.startReading()
                            : null,
                        icon: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 28,
                        ),
                        color: cs.primary,
                        tooltip: isPlaying ? 'Pausar' : 'Iniciar',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Book column — renders a static stack of fixed-height line rows
// ---------------------------------------------------------------------------

class _BookColumn extends StatelessWidget {
  const _BookColumn({
    required this.lines,
    required this.startGlobalIndex,
    required this.currentLineIndex,
  });

  final List<String> lines;
  final int startGlobalIndex;
  final int currentLineIndex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _kColumnHorizontalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < lines.length; i++)
            _BookLineTile(
              text: lines[i],
              isActive: startGlobalIndex + i == currentLineIndex,
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Line tile — active line highlighted, others dimmed. The row's height comes
// naturally from `TextStyle.height` (= `_kLineHeight`), not from a forced
// box — this is what lets Flutter reserve room for descenders/accents
// instead of clipping them.
//
// `maxLines: 1` + `overflow: ellipsis` is the actual overflow guard: even
// though `paginateTextIntoLines` measures each string to fit `_kFontSize` at
// the column's text width, a single word that's wider than the column on its
// own can't be split — pagination has to place it alone, and the renderer
// would otherwise wrap it onto a second line, doubling that row's height and
// busting the strict per-page line count. Forcing one line guarantees every
// row is exactly `_kLineHeight` tall no matter what the text measures to.
// ---------------------------------------------------------------------------

class _BookLineTile extends StatelessWidget {
  const _BookLineTile({required this.text, required this.isActive});

  final String text;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: _kLineHorizontalPadding),
      decoration: BoxDecoration(
        color: isActive
            ? cs.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: _kFontSize,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          height: _kLineHeightMultiplier,
          color: isActive ? cs.primary : cs.onSurface.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
