import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:optiflow/core/database/database_helper.dart';
import 'package:optiflow/core/theme/app_theme.dart';
import 'package:optiflow/core/utils/audio_service.dart';
import 'package:optiflow/features/vision_training/presentation/views/vision_dashboard_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.initialize();

  final audioService = AudioService();
  await audioService.init();

  runApp(
    ProviderScope(
      overrides: [audioServiceProvider.overrideWithValue(audioService)],
      child: const OptiFlowApp(),
    ),
  );
}

class OptiFlowApp extends StatelessWidget {
  const OptiFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OptiFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const VisionDashboardView(),
    );
  }
}
