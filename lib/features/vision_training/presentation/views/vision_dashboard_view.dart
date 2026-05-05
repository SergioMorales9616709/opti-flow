import 'package:flutter/material.dart';
import 'package:optiflow/features/vision_training/presentation/views/saccadic_jumps_view.dart';
import 'package:optiflow/features/vision_training/presentation/views/smooth_pursuit_view.dart';

class VisionDashboardView extends StatelessWidget {
  const VisionDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF161B22),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'ENTRENAMIENTO VISUAL',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ExerciseCard(
                    title: 'SALTOS\nSACÁDICOS',
                    subtitle: '6 patrones · metrónomo',
                    iconData: Icons.compare_arrows,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF21262D), Color(0xFF0D2020)],
                    ),
                    onTap: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SaccadicJumpsView(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  _ExerciseCard(
                    title: 'SEGUIMIENTO\nOCULAR',
                    subtitle: '3 patrones · BGM Lo-Fi',
                    iconData: Icons.track_changes,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF21262D), Color(0xFF0D1A20)],
                    ),
                    onTap: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SmoothPursuitView(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.title,
    required this.subtitle,
    required this.iconData,
    required this.gradient,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData iconData;
  final LinearGradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        height: 200,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x2600E5FF)),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -12,
              right: -12,
              child: Icon(
                iconData,
                size: 120,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF00E5FF),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 32,
                    height: 1.5,
                    color: const Color(0xFF00E5FF),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
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
