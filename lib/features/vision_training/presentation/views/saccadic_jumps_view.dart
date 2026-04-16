import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewmodels/saccadic_jumps_viewmodel.dart';

class SaccadicJumpsView extends ConsumerWidget {
  const SaccadicJumpsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            _ExerciseArea(availableHeight: constraints.maxHeight * 0.65),
            const Divider(height: 1, color: Color(0xFF2A2A2A)),
            const _ControlPanel(),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Exercise area — only rebuilds when position changes
// ---------------------------------------------------------------------------
class _ExerciseArea extends ConsumerWidget {
  const _ExerciseArea({required this.availableHeight});

  final double availableHeight;

  static const _symbols = ['●', 'A', '◆', 'X', '▲', 'Z', '■', 'O'];
  static int _symbolIndex = 0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(
      saccadicJumpsProvider.select((s) => s.position),
    );
    final status = ref.watch(
      saccadicJumpsProvider.select((s) => s.status),
    );

    final bool isActive = status == ExerciseStatus.active;
    final String symbol = isActive ? _symbols[_symbolIndex % _symbols.length] : '●';
    if (isActive) _symbolIndex++;

    return SizedBox(
      height: availableHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Center crosshair guide
          Center(
            child: Container(
              width: 1,
              height: availableHeight * 0.5,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          // Animated stimulus
          AnimatedAlign(
            duration: const Duration(milliseconds: 80),
            alignment: position == StimulusPosition.left
                ? const Alignment(-0.88, 0)
                : const Alignment(0.88, 0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 60),
              child: _StimulusWidget(
                key: ValueKey('$symbol$position'),
                symbol: symbol,
                active: isActive,
              ),
            ),
          ),
          // Overlay when idle
          if (status == ExerciseStatus.idle)
            const _IdleOverlay(),
          if (status == ExerciseStatus.saved)
            const _SavedOverlay(),
        ],
      ),
    );
  }
}

class _StimulusWidget extends StatelessWidget {
  const _StimulusWidget({
    super.key,
    required this.symbol,
    required this.active,
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
          color: active
              ? const Color(0xFF00E5FF)
              : const Color(0xFF444444),
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
              ? const Color(0xFF00E5FF)
              : const Color(0xFF555555),
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
        style: TextStyle(
          color: Colors.white54,
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
// Control panel — speed slider + buttons
// ---------------------------------------------------------------------------
class _ControlPanel extends ConsumerWidget {
  const _ControlPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(saccadicJumpsProvider);
    final notifier = ref.read(saccadicJumpsProvider.notifier);

    final bool isActive = state.status == ExerciseStatus.active;
    final bool isSaving = state.status == ExerciseStatus.saving;
    final bool isSaved = state.status == ExerciseStatus.saved;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Speed label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Velocidad del estímulo',
                style: TextStyle(fontSize: 15, color: Colors.white70),
              ),
              Text(
                '${state.speedMs} ms / salto',
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF00E5FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Slider — inverted so right = faster (lower ms)
          Row(
            children: [
              const Text('Lento', style: TextStyle(color: Colors.white38, fontSize: 12)),
              Expanded(
                child: Slider(
                  value: state.speedMs.toDouble(),
                  min: state.minSpeedMs.toDouble(),
                  max: state.maxSpeedMs.toDouble(),
                  divisions: (state.maxSpeedMs - state.minSpeedMs) ~/ 50,
                  onChanged: isSaving || isSaved
                      ? null
                      : (v) => notifier.setSpeed(v.round()),
                ),
              ),
              const Text('Rápido', style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 20),
          // Buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isActive && !isSaved) ...[
                ElevatedButton.icon(
                  onPressed: isSaving ? null : notifier.startExercise,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('INICIAR'),
                ),
              ],
              if (isActive) ...[
                ElevatedButton.icon(
                  onPressed: notifier.stopAndSave,
                  icon: const Icon(Icons.stop),
                  label: const Text('DETENER Y GUARDAR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4444),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
              if (isSaved) ...[
                ElevatedButton.icon(
                  onPressed: notifier.reset,
                  icon: const Icon(Icons.refresh),
                  label: const Text('NUEVO EJERCICIO'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
