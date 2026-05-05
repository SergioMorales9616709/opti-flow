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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _AppHeader(
              currentTheme: ref.watch(themeProvider),
              notifier: ref.read(themeProvider.notifier),
            ),
            Expanded(
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ExerciseCard(
                      title: 'SALTOS\nSACÁDICOS',
                      subtitle: '6 patrones · metrónomo',
                      iconData: Icons.compare_arrows,
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
                      onTap: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SmoothPursuitView(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// App header — label left, theme selector right
// ---------------------------------------------------------------------------
class _AppHeader extends StatelessWidget {
  const _AppHeader({required this.currentTheme, required this.notifier});

  final AppTheme currentTheme;
  final ThemeNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35)),
        ),
      ),
      child: Row(
        children: [
          Text(
            'ENTRENAMIENTO VISUAL',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.35),
              fontSize: 11,
              letterSpacing: 4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          _ThemeSelector(currentTheme: currentTheme, notifier: notifier),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Theme selector
// ---------------------------------------------------------------------------
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

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () => notifier.theme = appTheme,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 40,
          height: 40,
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
          child: Icon(
            isActive ? activeIcon : inactiveIcon,
            size: 18,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Exercise card — hover state, adaptive gradient via AppCardColors extension
// ---------------------------------------------------------------------------
class _ExerciseCard extends StatefulWidget {
  const _ExerciseCard({
    required this.title,
    required this.subtitle,
    required this.iconData,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData iconData;
  final VoidCallback onTap;

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cardColors = Theme.of(context).extension<AppCardColors>()!;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.025 : 1.0,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            width: 380,
            height: 260,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cardColors.gradientStart, cardColors.gradientEnd],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: cardColors.borderColor.withValues(
                  alpha: _hovered ? 0.38 : 0.18,
                ),
                width: _hovered ? 1.5 : 1.0,
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: cardColors.borderColor.withValues(alpha: 0.1),
                        blurRadius: 28,
                        spreadRadius: 4,
                      ),
                    ]
                  : [],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -12,
                  right: -12,
                  child: Icon(
                    widget.iconData,
                    size: 140,
                    color: cs.onSurface.withValues(alpha: 0.05),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          color: cs.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: _hovered ? 52 : 32,
                        height: 1.5,
                        color: cs.primary,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
