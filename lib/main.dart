import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/database/database_helper.dart';
import 'core/theme/app_theme.dart';
import 'features/vision_training/presentation/views/vision_training_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.initialize();

  runApp(const ProviderScope(child: OptiFlowApp()));
}

class OptiFlowApp extends StatelessWidget {
  const OptiFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OptiFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const VisionTrainingScreen(),
    );
  }
}
