import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:optiflow/core/theme/app_themes.dart';

class ThemeNotifier extends Notifier<AppTheme> {
  @override
  AppTheme build() => AppTheme.dark;

  AppTheme get theme => state;
  set theme(AppTheme t) => state = t;
}

final themeProvider = NotifierProvider<ThemeNotifier, AppTheme>(
  ThemeNotifier.new,
);
