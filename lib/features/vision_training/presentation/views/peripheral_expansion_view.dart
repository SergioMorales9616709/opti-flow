import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:optiflow/core/utils/audio_cue.dart';
import 'package:optiflow/core/utils/audio_service.dart';
import 'package:optiflow/features/vision_training/presentation/viewmodels/peripheral_expansion_viewmodel.dart';
import 'package:optiflow/features/vision_training/presentation/viewmodels/saccadic_jumps_viewmodel.dart'
    show ExerciseDuration, ExerciseStatus;

class PeripheralExpansionView extends ConsumerStatefulWidget {
  const PeripheralExpansionView({super.key});

  @override
  ConsumerState<PeripheralExpansionView> createState() =>
      _PeripheralExpansionViewState();
}

class _PeripheralExpansionViewState
    extends ConsumerState<PeripheralExpansionView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late AudioService _audioService;

  @override
  void initState() {
    super.initState();
    _audioService = ref.read(audioServiceProvider);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _controller.addStatusListener(_onAnimationStatus);
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      final s = ref.read(peripheralExpansionProvider);
      if (!s.isMuted && s.status == ExerciseStatus.active) {
        _audioService.play(AudioCue.click);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioService.stopBgm();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(peripheralExpansionProvider);
    final notifier = ref.read(peripheralExpansionProvider.notifier);

    ref
      ..listen(peripheralExpansionProvider.select((s) => s.status), (
        _,
        status,
      ) {
        if (status == ExerciseStatus.active) {
          _controller.repeat();
        } else {
          _controller
            ..stop()
            ..reset();
        }
      })
      ..listen(peripheralExpansionProvider.select((s) => s.speedMs), (_, ms) {
        _controller.duration = Duration(milliseconds: ms);
        if (ref.read(peripheralExpansionProvider).status ==
            ExerciseStatus.active) {
          _controller.repeat();
        }
      });

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _AnimationArea(
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Animation area — CustomPainter for geometric patterns + overlays
// ---------------------------------------------------------------------------
class _AnimationArea extends StatelessWidget {
  const _AnimationArea({
    required this.controller,
    required this.pattern,
    required this.status,
  });

  final AnimationController controller;
  final PeripheralPattern pattern;
  final ExerciseStatus status;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _PeripheralExpansionPainter(
                value: controller.value,
                pattern: pattern,
                primaryColor: primaryColor,
                isActive: status == ExerciseStatus.active,
              ),
            );
          },
        ),
        if (status == ExerciseStatus.idle) const _IdleOverlay(),
        if (status == ExerciseStatus.saving) const _SavingOverlay(),
        if (status == ExerciseStatus.saved) const _SavedOverlay(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// CustomPainter — geometric patterns + fixation dot
// ---------------------------------------------------------------------------
class _PeripheralExpansionPainter extends CustomPainter {
  const _PeripheralExpansionPainter({
    required this.value,
    required this.pattern,
    required this.primaryColor,
    required this.isActive,
  });

  final double value;
  final PeripheralPattern pattern;
  final Color primaryColor;
  final bool isActive;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    if (isActive) {
      switch (pattern) {
        case PeripheralPattern.expandingCircles:
          _paintExpandingCircles(canvas, size, center);
        case PeripheralPattern.contractingSquares:
          _paintContractingSquares(canvas, size, center);
        case PeripheralPattern.pulsingTarget:
          _paintPulsingTarget(canvas, size, center);
      }
    }

    _paintFixationDot(canvas, center);
  }

  void _paintExpandingCircles(Canvas canvas, Size size, Offset center) {
    final maxRadius = math.min(size.width, size.height) / 2 * 0.95;
    final radius = maxRadius * value;
    if (radius < 1) return;
    final opacity = 1.0 - value;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = primaryColor.withValues(alpha: opacity),
    );
  }

  void _paintContractingSquares(Canvas canvas, Size size, Offset center) {
    final maxHalf = math.min(size.width, size.height) / 2 * 0.95;
    final half = maxHalf * (1.0 - value);
    if (half < 1) return;
    // Constant opacity, fades out only in the last 15% as it nears the center.
    final opacity = value > 0.85 ? (1.0 - value) / 0.15 : 1.0;
    canvas.drawRect(
      Rect.fromCenter(center: center, width: half * 2, height: half * 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = primaryColor.withValues(alpha: opacity),
    );
  }

  void _paintPulsingTarget(Canvas canvas, Size size, Offset center) {
    final maxRadius = math.min(size.width, size.height) / 2 * 0.95;
    final sinVal = math.sin(value * math.pi);
    final radius = maxRadius * 0.9 * sinVal;
    if (radius < 1) return;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = primaryColor.withValues(alpha: sinVal.clamp(0.05, 1.0)),
    );
  }

  void _paintFixationDot(Canvas canvas, Offset center) {
    final crossPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white;
    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;
    canvas
      ..drawLine(center.translate(-10, 0), center.translate(10, 0), crossPaint)
      ..drawLine(center.translate(0, -10), center.translate(0, 10), crossPaint)
      ..drawCircle(center, 5, dotPaint);
  }

  @override
  bool shouldRepaint(_PeripheralExpansionPainter old) => true;
}

// ---------------------------------------------------------------------------
// Overlays
// ---------------------------------------------------------------------------
class _IdleOverlay extends StatelessWidget {
  const _IdleOverlay();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surface.withValues(alpha: 0.88),
      alignment: Alignment.center,
      child: Text(
        'Mantén la vista en el punto central\ny presiona INICIAR',
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
// Control panel
// ---------------------------------------------------------------------------
class _ControlPanel extends StatelessWidget {
  const _ControlPanel({required this.state, required this.notifier});

  final PeripheralExpansionState state;
  final PeripheralExpansionNotifier notifier;

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
          // Row 1: pattern selector + speed label + sound toggle
          Row(
            children: [
              Expanded(
                child: SegmentedButton<PeripheralPattern>(
                  segments: PeripheralPattern.values
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
                  value: state.speedMs.toDouble(),
                  min: state.minSpeedMs.toDouble(),
                  max: state.maxSpeedMs.toDouble(),
                  divisions: 25,
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
                selected: {state.selectedDuration},
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
                onPressed: () {
                  notifier.reset();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Práctica Libre'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
              const Spacer(),
              if (isActive &&
                  state.selectedDuration != ExerciseDuration.infinite &&
                  state.timeLeftSeconds != null)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Builder(
                      builder: (context) {
                        final t = state.timeLeftSeconds!;
                        final mm = (t ~/ 60).toString().padLeft(2, '0');
                        final ss = (t % 60).toString().padLeft(2, '0');
                        return Text(
                          '$mm:$ss',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        );
                      },
                    ),
                  ),
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
