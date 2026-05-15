import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:optiflow/features/vision_training/domain/saccadic_pattern.dart';
import 'package:optiflow/features/vision_training/presentation/viewmodels/saccadic_jumps_viewmodel.dart';

class SaccadicJumpsView extends ConsumerWidget {
  const SaccadicJumpsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Expanded(child: _ExerciseArea()),
            Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const _ControlPanel(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Exercise area — rebuilds only when alignment or status changes
// ---------------------------------------------------------------------------
class _ExerciseArea extends ConsumerWidget {
  const _ExerciseArea();

  static const _symbols = ['●', 'A', '◆', 'X', '▲', 'Z', '■', 'O'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alignment = ref.watch(
      saccadicJumpsProvider.select((s) => s.currentAlignment),
    );
    final status = ref.watch(saccadicJumpsProvider.select((s) => s.status));
    final symbolIndex = ref.watch(
      saccadicJumpsProvider.select((s) => s.symbolIndex),
    );

    final isActive = status == ExerciseStatus.active;
    final symbol = isActive ? _symbols[symbolIndex % _symbols.length] : '●';

    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: alignment,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 60),
            child: _StimulusWidget(
              key: ValueKey('$symbol$alignment'),
              symbol: symbol,
              active: isActive,
            ),
          ),
        ),
        if (status == ExerciseStatus.idle) const _IdleOverlay(),
        if (status == ExerciseStatus.saved) const _SavedOverlay(),
      ],
    );
  }
}

class _StimulusWidget extends StatelessWidget {
  const _StimulusWidget({
    required this.symbol,
    required this.active,
    super.key,
  });

  final String symbol;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        border: Border.all(
          color: active
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outlineVariant,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        symbol,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: active
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

class _IdleOverlay extends StatelessWidget {
  const _IdleOverlay();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surface.withValues(alpha: 0.88),
      alignment: Alignment.center,
      child: Text(
        'Presiona INICIAR para comenzar\nel ejercicio de saltos sacádicos',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: cs.onSurface.withValues(alpha: 0.65),
          fontSize: 18,
          height: 1.6,
        ),
      ),
    );
  }
}

class _SavedOverlay extends StatelessWidget {
  const _SavedOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Theme.of(context).colorScheme.primary,
            size: 56,
          ),
          const SizedBox(height: 16),
          Text(
            '¡Progreso guardado!',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Control panel — pattern selector + speed slider + action buttons (compact)
// ---------------------------------------------------------------------------
class _ControlPanel extends ConsumerWidget {
  const _ControlPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pattern = ref.watch(saccadicJumpsProvider.select((s) => s.pattern));
    final status = ref.watch(saccadicJumpsProvider.select((s) => s.status));
    final speedMs = ref.watch(saccadicJumpsProvider.select((s) => s.speedMs));
    final minSpeedMs = ref.watch(
      saccadicJumpsProvider.select((s) => s.minSpeedMs),
    );
    final maxSpeedMs = ref.watch(
      saccadicJumpsProvider.select((s) => s.maxSpeedMs),
    );
    final isSoundEnabled = ref.watch(
      saccadicJumpsProvider.select((s) => s.isSoundEnabled),
    );
    final notifier = ref.read(saccadicJumpsProvider.notifier);

    final isActive = status == ExerciseStatus.active;
    final isSaving = status == ExerciseStatus.saving;
    final isSaved = status == ExerciseStatus.saved;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: pattern selector + speed label + mute
          Row(
            children: [
              Expanded(
                child: SegmentedButton<SaccadicPattern>(
                  segments: SaccadicPattern.values
                      .map((p) => ButtonSegment(value: p, label: Text(p.label)))
                      .toList(),
                  selected: {pattern},
                  onSelectionChanged: status == ExerciseStatus.idle
                      ? (s) => notifier.setPattern(s.first)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 58,
                child: Text(
                  '$speedMs ms',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: isSoundEnabled
                    ? 'Silenciar metrónomo'
                    : 'Activar metrónomo',
                icon: Icon(
                  isSoundEnabled ? Icons.volume_up : Icons.volume_off,
                  color: isSoundEnabled
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                onPressed: notifier.toggleSound,
              ),
            ],
          ),
          // Row 2: slider + duration selector
          Row(
            children: [
              Text(
                'Rápido',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.4),
                  fontSize: 12,
                ),
              ),
              Expanded(
                child: Slider(
                  value: speedMs.toDouble(),
                  min: minSpeedMs.toDouble(),
                  max: maxSpeedMs.toDouble(),
                  divisions: (maxSpeedMs - minSpeedMs) ~/ 50,
                  onChanged: isSaving || isSaved
                      ? null
                      : (v) => notifier.setSpeed(v.round()),
                ),
              ),
              Text(
                'Lento',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.4),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 16),
              SegmentedButton<ExerciseDuration>(
                segments: ExerciseDuration.values
                    .map((d) => ButtonSegment(value: d, label: Text(d.label)))
                    .toList(),
                selected: {
                  ref.watch(
                    saccadicJumpsProvider.select((s) => s.selectedDuration),
                  ),
                },
                onSelectionChanged: isActive || isSaving || isSaved
                    ? null
                    : (s) => notifier.setDuration(s.first),
              ),
            ],
          ),
          // Row 3: back nav + timer chip + action button
          const SizedBox(height: 4),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Práctica Libre'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
              const Spacer(),
              Builder(
                builder: (_) {
                  final selectedDuration = ref.watch(
                    saccadicJumpsProvider.select((s) => s.selectedDuration),
                  );
                  final timeLeft = ref.watch(
                    saccadicJumpsProvider.select((s) => s.timeLeftSeconds),
                  );
                  if (!isActive ||
                      selectedDuration == ExerciseDuration.infinite ||
                      timeLeft == null) {
                    return const SizedBox.shrink();
                  }
                  final mm = (timeLeft ~/ 60).toString().padLeft(2, '0');
                  final ss = (timeLeft % 60).toString().padLeft(2, '0');
                  final cs = Theme.of(context).colorScheme;
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
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
                      child: Text(
                        '$mm:$ss',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (!isActive && !isSaved)
                ElevatedButton.icon(
                  onPressed: isSaving ? null : notifier.startExercise,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('INICIAR'),
                ),
              if (isActive)
                ElevatedButton.icon(
                  onPressed: notifier.stopAndSave,
                  icon: const Icon(Icons.stop),
                  label: const Text('DETENER Y GUARDAR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Colors.white,
                  ),
                ),
              if (isSaved)
                ElevatedButton.icon(
                  onPressed: notifier.reset,
                  icon: const Icon(Icons.refresh),
                  label: const Text('NUEVO EJERCICIO'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
