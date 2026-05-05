import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:optiflow/core/utils/audio_service.dart';
import 'package:optiflow/features/vision_training/domain/pursuit_pattern.dart';
import 'package:optiflow/features/vision_training/presentation/viewmodels/saccadic_jumps_viewmodel.dart'
    show ExerciseStatus;
import 'package:optiflow/features/vision_training/presentation/viewmodels/smooth_pursuit_viewmodel.dart';

class SmoothPursuitView extends ConsumerStatefulWidget {
  const SmoothPursuitView({super.key});

  @override
  ConsumerState<SmoothPursuitView> createState() => _SmoothPursuitViewState();
}

class _SmoothPursuitViewState extends ConsumerState<SmoothPursuitView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late AudioService _audioService;

  @override
  void initState() {
    super.initState();
    _audioService = ref.read(audioServiceProvider);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioService.stopBgm();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(smoothPursuitProvider);
    final notifier = ref.read(smoothPursuitProvider.notifier);

    ref
      ..listen(smoothPursuitProvider.select((s) => s.status), (_, status) {
        if (status == ExerciseStatus.active) {
          _controller.repeat();
        } else {
          _controller
            ..stop()
            ..reset();
        }
      })
      ..listen(smoothPursuitProvider.select((s) => s.speedMs), (_, ms) {
        _controller.duration = Duration(milliseconds: ms);
        if (ref.read(smoothPursuitProvider).status == ExerciseStatus.active) {
          _controller.repeat();
        }
      });

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: _StimulusArea(
                    controller: _controller,
                    pattern: state.pattern,
                    status: state.status,
                  ),
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                _ControlPanel(state: state, notifier: notifier),
              ],
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                tooltip: 'Volver al menú',
                icon: Icon(
                  Icons.arrow_back,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                onPressed: () {
                  notifier.reset();
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stimulus area — AnimatedBuilder rebuilds only the circle widget
// ---------------------------------------------------------------------------
class _StimulusArea extends StatelessWidget {
  const _StimulusArea({
    required this.controller,
    required this.pattern,
    required this.status,
  });

  final AnimationController controller;
  final PursuitPattern pattern;
  final ExerciseStatus status;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (status == ExerciseStatus.active)
          AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              final t = controller.value * 2 * math.pi;
              final (dx, dy) = pattern.position(t);
              return Align(
                alignment: Alignment(dx * 0.90, dy * 0.90),
                child: child,
              );
            },
            child: const _StimulusCircle(),
          )
        else
          const Center(child: _StimulusCircle()),
        if (status == ExerciseStatus.idle) const _IdleOverlay(),
        if (status == ExerciseStatus.saving) const _SavingOverlay(),
        if (status == ExerciseStatus.saved) const _SavedOverlay(),
      ],
    );
  }
}

class _StimulusCircle extends StatelessWidget {
  const _StimulusCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primary,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
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
        'Presiona INICIAR para comenzar\nel seguimiento ocular',
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

class _SavingOverlay extends StatelessWidget {
  const _SavingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
      alignment: Alignment.center,
      child: CircularProgressIndicator(
        color: Theme.of(context).colorScheme.primary,
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
class _ControlPanel extends StatelessWidget {
  const _ControlPanel({required this.state, required this.notifier});

  final SmoothPursuitState state;
  final SmoothPursuitNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final isActive = state.status == ExerciseStatus.active;
    final isSaving = state.status == ExerciseStatus.saving;
    final isSaved = state.status == ExerciseStatus.saved;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: pattern selector + speed label + mute
          Row(
            children: [
              Expanded(
                child: SegmentedButton<PursuitPattern>(
                  segments: PursuitPattern.values
                      .map((p) => ButtonSegment(value: p, label: Text(p.label)))
                      .toList(),
                  selected: {state.pattern},
                  onSelectionChanged: state.status == ExerciseStatus.idle
                      ? (s) => notifier.setPattern(s.first)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 58,
                child: Text(
                  '${state.speedMs} ms',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: state.isMuted ? 'Activar música' : 'Silenciar música',
                icon: Icon(
                  state.isMuted ? Icons.volume_off : Icons.volume_up,
                  color: state.isMuted
                      ? Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.4)
                      : Theme.of(context).colorScheme.primary,
                ),
                onPressed: notifier.toggleMute,
              ),
            ],
          ),
          // Row 2: slider
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
                  value: state.speedMs.toDouble(),
                  min: state.minSpeedMs.toDouble(),
                  max: state.maxSpeedMs.toDouble(),
                  divisions: 20,
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
