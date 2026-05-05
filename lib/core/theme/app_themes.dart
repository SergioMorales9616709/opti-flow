import 'package:flutter/material.dart';

enum AppTheme { dark, light, cyber }

@immutable
class AppCardColors extends ThemeExtension<AppCardColors> {
  const AppCardColors({
    required this.gradientStart,
    required this.gradientEnd,
    required this.borderColor,
  });

  final Color gradientStart;
  final Color gradientEnd;
  final Color borderColor;

  @override
  AppCardColors copyWith({
    Color? gradientStart,
    Color? gradientEnd,
    Color? borderColor,
  }) => AppCardColors(
    gradientStart: gradientStart ?? this.gradientStart,
    gradientEnd: gradientEnd ?? this.gradientEnd,
    borderColor: borderColor ?? this.borderColor,
  );

  @override
  AppCardColors lerp(ThemeExtension<AppCardColors>? other, double t) {
    if (other is! AppCardColors) return this;
    return AppCardColors(
      gradientStart: Color.lerp(gradientStart, other.gradientStart, t)!,
      gradientEnd: Color.lerp(gradientEnd, other.gradientEnd, t)!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
    );
  }
}

class AppThemes {
  AppThemes._();

  static ThemeData themeData(AppTheme theme) {
    switch (theme) {
      case AppTheme.dark:
        const primary = Color(0xFF00E5FF);
        const onSurface = Colors.white;
        return ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF161B22),
          colorScheme: ColorScheme.fromSeed(
            seedColor: primary,
            brightness: Brightness.dark,
          ),
          sliderTheme: const SliderThemeData(
            activeTrackColor: primary,
            thumbColor: primary,
            inactiveTrackColor: Color(0xFF2A2A2A),
          ),
          cardTheme: const CardThemeData(
            color: Color(0xFF21262D),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
          ),
          segmentedButtonTheme: SegmentedButtonThemeData(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith(
                (s) => s.contains(WidgetState.selected)
                    ? primary.withValues(alpha: 0.18)
                    : Colors.transparent,
              ),
              foregroundColor: WidgetStateProperty.resolveWith(
                (s) => s.contains(WidgetState.selected)
                    ? primary
                    : onSurface.withValues(alpha: 0.5),
              ),
              side: WidgetStateProperty.resolveWith(
                (s) => BorderSide(
                  color: s.contains(WidgetState.selected)
                      ? primary
                      : onSurface.withValues(alpha: 0.18),
                ),
              ),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          extensions: const [
            AppCardColors(
              gradientStart: Color(0xFF1C2128),
              gradientEnd: Color(0xFF0D2535),
              borderColor: Color(0xFF00E5FF),
            ),
          ],
        );

      case AppTheme.light:
        const primary = Color(0xFFE63946);
        const onSurface = Color(0xFF1C1B1E);
        return ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF8F9FA),
          colorScheme: ColorScheme.fromSeed(seedColor: primary),
          sliderTheme: const SliderThemeData(
            activeTrackColor: primary,
            thumbColor: primary,
            inactiveTrackColor: Color(0xFFDDDDDD),
          ),
          cardTheme: const CardThemeData(
            color: Color(0xFFFFFFFF),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
          ),
          segmentedButtonTheme: SegmentedButtonThemeData(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith(
                (s) => s.contains(WidgetState.selected)
                    ? primary.withValues(alpha: 0.1)
                    : Colors.transparent,
              ),
              foregroundColor: WidgetStateProperty.resolveWith(
                (s) => s.contains(WidgetState.selected)
                    ? primary
                    : onSurface.withValues(alpha: 0.5),
              ),
              side: WidgetStateProperty.resolveWith(
                (s) => BorderSide(
                  color: s.contains(WidgetState.selected)
                      ? primary
                      : onSurface.withValues(alpha: 0.2),
                ),
              ),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          extensions: const [
            AppCardColors(
              gradientStart: Color(0xFFECEEF5),
              gradientEnd: Color(0xFFF5E0E3),
              borderColor: Color(0xFFE63946),
            ),
          ],
        );

      case AppTheme.cyber:
        const primary = Color(0xFFFF007F);
        const onSurface = Colors.white;
        return ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF1E1B4B),
          colorScheme: ColorScheme.fromSeed(
            seedColor: primary,
            brightness: Brightness.dark,
          ),
          sliderTheme: const SliderThemeData(
            activeTrackColor: primary,
            thumbColor: primary,
            inactiveTrackColor: Color(0xFF2A2035),
          ),
          cardTheme: const CardThemeData(
            color: Color(0xFF2D2A5E),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
          ),
          segmentedButtonTheme: SegmentedButtonThemeData(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith(
                (s) => s.contains(WidgetState.selected)
                    ? primary.withValues(alpha: 0.22)
                    : Colors.transparent,
              ),
              foregroundColor: WidgetStateProperty.resolveWith(
                (s) => s.contains(WidgetState.selected)
                    ? primary
                    : onSurface.withValues(alpha: 0.45),
              ),
              side: WidgetStateProperty.resolveWith(
                (s) => BorderSide(
                  color: s.contains(WidgetState.selected)
                      ? primary
                      : onSurface.withValues(alpha: 0.15),
                ),
              ),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          extensions: const [
            AppCardColors(
              gradientStart: Color(0xFF252259),
              gradientEnd: Color(0xFF3B1843),
              borderColor: Color(0xFFFF007F),
            ),
          ],
        );
    }
  }
}
