import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:optiflow/core/database/database_helper.dart';
import 'package:optiflow/core/database/progress_repository.dart';
import 'package:optiflow/main.dart';

// Stub repository — records calls without hitting disk.
class _FakeProgressRepository implements ProgressRepository {
  final List<Map<String, dynamic>> saved = [];

  @override
  Future<void> saveProgress({
    required String exerciseType,
    required int maxSpeedMs,
  }) async {
    saved.add({'exerciseType': exerciseType, 'maxSpeedMs': maxSpeedMs});
  }
}

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await DatabaseHelper.initializeForTesting();
  });

  testWidgets('App launches smoke test', (WidgetTester tester) async {
    final fakeRepo = _FakeProgressRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          progressRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const OptiFlowApp(),
      ),
    );

    expect(find.text('OptiFlow — Entrenamiento Visual'), findsOneWidget);
  });
}
