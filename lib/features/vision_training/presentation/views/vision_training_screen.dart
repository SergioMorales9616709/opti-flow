import 'package:flutter/material.dart';
import 'package:optiflow/features/vision_training/presentation/views/saccadic_jumps_view.dart';

class VisionTrainingScreen extends StatelessWidget {
  const VisionTrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'OptiFlow — Entrenamiento Visual',
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 1.2),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const SaccadicJumpsView(),
    );
  }
}
