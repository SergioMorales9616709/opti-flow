import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:optiflow/features/vision_training/domain/saccadic_pattern.dart';
import 'package:optiflow/features/vision_training/presentation/viewmodels/saccadic_jumps_viewmodel.dart';

class SaccadicJumpsView extends ConsumerWidget {
  const SaccadicJumpsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF161B22),
      body: SafeArea(
        child: Stack(
          children: [
            const Column(
              children: [
                Expanded(child: _ExerciseArea()),
                Divider(height: 1, color: Color(0xFF2A2A2A)),
                _ControlPanel(),
              ],
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                tooltip: 'Volver al menú',
                icon: const Icon(Icons.arrow_back, color: Colors.white38),
                onPressed: () => Navigator.pop(context),
              ),
            ),
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
            ? const Color(0xFF00E5FF).withValues(alpha: 0.12)
            : Colors.transparent,
        border: Border.all(
          color: active ? const Color(0xFF00E5FF) : const Color(0xFF444444),
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        symbol,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: active ? const Color(0xFF00E5FF) : const Color(0xFF555555),
        ),
      ),
    );
  }
}

class _IdleOverlay extends StatelessWidget {
  const _IdleOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      alignment: Alignment.center,
      child: const Text(
        'Presiona INICIAR para comenzar\nel ejercicio de saltos sacádicos',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white54, fontSize: 18, height: 1.6),
      ),
    );
  }
}

class _SavedOverlay extends StatelessWidget {
  const _SavedOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, color: Color(0xFF00E5FF), size: 56),
          SizedBox(height: 16),
          Text(
            '¡Progreso guardado!',
            style: TextStyle(
              color: Color(0xFF00E5FF),
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
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF00E5FF),
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
                      ? const Color(0xFF00E5FF)
                      : Colors.white38,
                ),
                onPressed: notifier.toggleSound,
              ),
            ],
          ),
          // Row 2: slider
          Row(
            children: [
              const Text(
                'Rápido',
                style: TextStyle(color: Colors.white38, fontSize: 12),
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
              const Text(
                'Lento',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
          // Row 3: action button
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                    backgroundColor: const Color(0xFFFF4444),
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
