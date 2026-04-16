import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:optiflow/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: OptiFlowApp()),
    );
    expect(find.text('OptiFlow — Entrenamiento Visual'), findsOneWidget);
  });
}
