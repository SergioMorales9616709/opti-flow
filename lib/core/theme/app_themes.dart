import 'package:flutter/material.dart';

enum AppTheme { dark, light, cyber }

class AppThemes {
  AppThemes._();

  static ThemeData themeData(AppTheme theme) {
    switch (theme) {
      case AppTheme.dark:
        return ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF161B22),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF00E5FF),
            brightness: Brightness.dark,
          ),
          sliderTheme: const SliderThemeData(
            activeTrackColor: Color(0xFF00E5FF),
            thumbColor: Color(0xFF00E5FF),
            inactiveTrackColor: Color(0xFF2A2A2A),
          ),
          cardTheme: const CardThemeData(
            color: Color(0xFF21262D),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );

      case AppTheme.light:
        return ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF8F9FA),
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE63946)),
          sliderTheme: const SliderThemeData(
            activeTrackColor: Color(0xFFE63946),
            thumbColor: Color(0xFFE63946),
            inactiveTrackColor: Color(0xFFDDDDDD),
          ),
          cardTheme: const CardThemeData(
            color: Color(0xFFFFFFFF),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE63946),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );

      case AppTheme.cyber:
        return ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF1E1B4B),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFF007F),
            brightness: Brightness.dark,
          ),
          sliderTheme: const SliderThemeData(
            activeTrackColor: Color(0xFFFF007F),
            thumbColor: Color(0xFFFF007F),
            inactiveTrackColor: Color(0xFF2A2035),
          ),
          cardTheme: const CardThemeData(
            color: Color(0xFF2D2A5E),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF007F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
    }
  }
}
