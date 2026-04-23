import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF00E5FF),
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF0D0D0D),
    sliderTheme: const SliderThemeData(
      activeTrackColor: Color(0xFF00E5FF),
      thumbColor: Color(0xFF00E5FF),
      inactiveTrackColor: Color(0xFF2A2A2A),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00E5FF),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
