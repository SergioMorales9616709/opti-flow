import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:optiflow/features/speed_reading/presentation/viewmodels/guided_lines_viewmodel.dart';
import 'package:optiflow/features/vision_training/presentation/viewmodels/saccadic_jumps_viewmodel.dart'
    show ExerciseDuration;

// Strict per-line height enforced via `itemExtent` on the ListView so the
// physical row height always matches the math used for page-flip scrolling.
// fontSize(32) * lineHeight(1.4) + vertical margin(16) + container padding(12)
// ≈ 72.8, rounded up so the text never clips inside the fixed row.
const _kLineHeight = 73.0;

// The style used for both pagination calculation and rendering.
// Must be identical so TextPainter measurements match the rendered layout.
TextStyle _lineStyle(BuildContext context) => TextStyle(
  fontSize: 32,
  fontWeight: FontWeight.w400,
  color: Theme.of(context).colorScheme.onSurface,
);

class GuidedLinesView extends ConsumerStatefulWidget {
  const GuidedLinesView({super.key});

  @override
  ConsumerState<GuidedLinesView> createState() => _GuidedLinesViewState();
}

class _GuidedLinesViewState extends ConsumerState<GuidedLinesView> {
  final _scrollController = ScrollController();
  bool _paginationScheduled = false;

  // Computed once per layout pass inside the LayoutBuilder below — counts
  // only lines that fit *completely* in the viewport, so the page math here
  // matches the strict `itemExtent: _kLineHeight` rows exactly.
  int _maxLinesPerPage = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// "Page Flip": jumps instantly to the exact top offset of the page that
  /// contains [index], instead of continuously scrolling to center the active
  /// line. Because rows have a strict `itemExtent`, `targetPage * linesPerPage
  /// * lineHeight` always lands the new line flush with the viewport's top
  /// edge — the eye returns to the top of the screen, like flipping a page.
  void _flipToLine(int index) {
    if (!_scrollController.hasClients || _maxLinesPerPage <= 0) return;
    final targetPage = index ~/ _maxLinesPerPage;
    final exactOffset = (targetPage * _maxLinesPerPage * _kLineHeight).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    if (_scrollController.offset != exactOffset) {
      _scrollController.jumpTo(exactOffset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLoaded = ref.watch(guidedLinesProvider.select((s) => s.isLoaded));
    final lines = ref.watch(guidedLinesProvider.select((s) => s.lines));
    final isPlaying = ref.watch(guidedLinesProvider.select((s) => s.isPlaying));
    final isMuted = ref.watch(guidedLinesProvider.select((s) => s.isMuted));
    final currentWpm = ref.watch(
      guidedLinesProvider.select((s) => s.currentWpm),
    );
    final currentLineIndex = ref.watch(
      guidedLinesProvider.select((s) => s.currentLineIndex),
    );
    final selectedDuration = ref.watch(
      guidedLinesProvider.select((s) => s.selectedDuration),
    );
    final timeLeftSeconds = ref.watch(
      guidedLinesProvider.select((s) => s.timeLeftSeconds),
    );

    final notifier = ref.read(guidedLinesProvider.notifier);
    final progress = lines.isEmpty ? 0.0 : currentLineIndex / lines.length;

    // Page-flip whenever the active line crosses into a new page.
    ref.listen<int>(
      guidedLinesProvider.select((s) => s.currentLineIndex),
      (_, index) => _flipToLine(index),
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Line list area ─────────────────────────────────────────────
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Strict count of lines that fit completely in the
                  // viewport — drives the page-flip math in `_flipToLine`.
                  _maxLinesPerPage = (constraints.maxHeight / _kLineHeight)
                      .floor();

                  // Trigger pagination once — after layout width is known.
                  if (isLoaded && lines.isEmpty && !_paginationScheduled) {
                    _paginationScheduled = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        notifier.paginate(
                          // 24px horizontal padding × 2
                          constraints.maxWidth - 48,
                          _lineStyle(context),
                        );
                      }
                    });
                  }

                  if (!isLoaded || lines.isEmpty) {
                    return Center(
                      child: CircularProgressIndicator(color: cs.primary),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemExtent: _kLineHeight,
                    itemCount: lines.length,
                    itemBuilder: (context, index) {
                      final isActive = index == currentLineIndex;
                      return _LineTile(text: lines[index], isActive: isActive);
                    },
                  );
                },
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
                          max: 1200,
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
// Line tile — active line highlighted, others dimmed
// ---------------------------------------------------------------------------

class _LineTile extends StatelessWidget {
  const _LineTile({required this.text, required this.isActive});

  final String text;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isActive
            ? cs.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 32,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          color: isActive ? cs.primary : cs.onSurface.withValues(alpha: 0.15),
          height: 1.4,
        ),
      ),
    );
  }
}
