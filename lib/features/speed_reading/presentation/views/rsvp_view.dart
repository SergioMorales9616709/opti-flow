import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:optiflow/features/speed_reading/presentation/viewmodels/rsvp_viewmodel.dart';

class RsvpView extends ConsumerWidget {
  const RsvpView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isLoaded = ref.watch(rsvpProvider.select((s) => s.isLoaded));
    final isPlaying = ref.watch(rsvpProvider.select((s) => s.isPlaying));
    final isMuted = ref.watch(rsvpProvider.select((s) => s.isMuted));
    final currentWpm = ref.watch(rsvpProvider.select((s) => s.currentWpm));
    final currentIndex = ref.watch(rsvpProvider.select((s) => s.currentIndex));
    final words = ref.watch(rsvpProvider.select((s) => s.words));

    final notifier = ref.read(rsvpProvider.notifier);
    final progress =
        words.isEmpty ? 0.0 : currentIndex / words.length;
    final currentWord =
        (isLoaded && words.isNotEmpty && currentIndex < words.length)
            ? words[currentIndex]
            : '';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Central word area ──────────────────────────────────────────
            Expanded(
              child: Center(
                child: isLoaded
                    ? Text(
                        currentWord,
                        style: TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                          letterSpacing: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      )
                    : CircularProgressIndicator(color: cs.primary),
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

                  // Row 2: Speed slider
                  Slider(
                    value: currentWpm.toDouble(),
                    min: 200,
                    max: 1200,
                    label: '$currentWpm WPM',
                    activeColor: cs.primary,
                    inactiveColor: cs.surfaceContainerHighest,
                    onChanged: (v) => notifier.setWpm(v.round()),
                  ),

                  // Row 3: Back | Progress | Play/Pause
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
                            backgroundColor:
                                cs.surfaceContainerHighest,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(cs.primary),
                            borderRadius: BorderRadius.circular(4),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: isLoaded
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
