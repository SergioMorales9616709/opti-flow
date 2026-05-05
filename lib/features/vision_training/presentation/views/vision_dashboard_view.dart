import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:optiflow/core/theme/app_themes.dart';
import 'package:optiflow/core/theme/theme_provider.dart';
import 'package:optiflow/features/vision_training/presentation/views/saccadic_jumps_view.dart';
import 'package:optiflow/features/vision_training/presentation/views/smooth_pursuit_view.dart';

class VisionDashboardView extends ConsumerWidget {
  const VisionDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final gradientEnd = Color.alphaBlend(
      cs.primary.withValues(alpha: 0.18),
      cs.surface,
    );

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ENTRENAMIENTO VISUAL',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.35),
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
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [cs.surfaceContainerHighest, gradientEnd],
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
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [cs.surfaceContainerHighest, gradientEnd],
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
            Positioned(
              top: 8,
              right: 8,
              child: _ThemeSelector(
                currentTheme: ref.watch(themeProvider),
                notifier: ref.read(themeProvider.notifier),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.currentTheme, required this.notifier});

  final AppTheme currentTheme;
  final ThemeNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ThemeButton(
          appTheme: AppTheme.dark,
          currentTheme: currentTheme,
          activeIcon: Icons.dark_mode,
          inactiveIcon: Icons.dark_mode_outlined,
          label: 'OSCURO',
          tooltip: 'Oscuro',
          notifier: notifier,
          colorScheme: cs,
        ),
        const SizedBox(width: 4),
        _ThemeButton(
          appTheme: AppTheme.light,
          currentTheme: currentTheme,
          activeIcon: Icons.light_mode,
          inactiveIcon: Icons.light_mode_outlined,
          label: 'CLARO',
          tooltip: 'Claro',
          notifier: notifier,
          colorScheme: cs,
        ),
        const SizedBox(width: 4),
        _ThemeButton(
          appTheme: AppTheme.cyber,
          currentTheme: currentTheme,
          activeIcon: Icons.electric_bolt,
          inactiveIcon: Icons.electric_bolt_outlined,
          label: 'CYBER',
          tooltip: 'Cyber',
          notifier: notifier,
          colorScheme: cs,
        ),
      ],
    );
  }
}

class _ThemeButton extends StatelessWidget {
  const _ThemeButton({
    required this.appTheme,
    required this.currentTheme,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
    required this.tooltip,
    required this.notifier,
    required this.colorScheme,
  });

  final AppTheme appTheme;
  final AppTheme currentTheme;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  final String tooltip;
  final ThemeNotifier notifier;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final isActive = currentTheme == appTheme;
    final iconColor = isActive
        ? colorScheme.primary
        : colorScheme.onSurface.withValues(alpha: 0.4);
    final labelColor = isActive
        ? colorScheme.primary
        : colorScheme.onSurface.withValues(alpha: 0.3);

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () => notifier.theme = appTheme,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 48,
          height: 52,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isActive
                ? colorScheme.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? activeIcon : inactiveIcon,
                size: 18,
                color: iconColor,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: labelColor,
                  fontSize: 6.5,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w600,
                ),
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
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        height: 200,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -12,
              right: -12,
              child: Icon(
                iconData,
                size: 120,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.06),
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
                    style: TextStyle(
                      color: cs.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(width: 32, height: 1.5, color: cs.primary),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
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
