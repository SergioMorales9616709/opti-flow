import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database_helper.dart';

abstract interface class ProgressRepository {
  Future<void> saveProgress({
    required String exerciseType,
    required int maxSpeedMs,
  });
}

class ProgressRepositoryImpl implements ProgressRepository {
  @override
  Future<void> saveProgress({
    required String exerciseType,
    required int maxSpeedMs,
  }) async {
    await DatabaseHelper.db.insert('user_progress', {
      'date': DateTime.now().toIso8601String(),
      'exercise_type': exerciseType,
      'max_speed_ms': maxSpeedMs,
    });
  }
}

final progressRepositoryProvider = Provider<ProgressRepository>(
  (_) => ProgressRepositoryImpl(),
);
