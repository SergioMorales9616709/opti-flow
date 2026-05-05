import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:optiflow/core/theme/app_themes.dart';

class ThemeNotifier extends Notifier<AppTheme> {
  @override
  AppTheme build() => AppTheme.dark;

  void setTheme(AppTheme theme) {
    state = theme;
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, AppTheme>(
  ThemeNotifier.new,
);
