import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:optiflow/features/vision_training/presentation/viewmodels/smooth_pursuit_viewmodel.dart';

void main() {
  group('SmoothPursuitNotifier initial state', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('default speedMs is 3000', () {
      expect(container.read(smoothPursuitProvider).speedMs, 3000);
    });

    test('minSpeedMs is 1500', () {
      expect(container.read(smoothPursuitProvider).minSpeedMs, 1500);
    });

    test('maxSpeedMs is 5000', () {
      expect(container.read(smoothPursuitProvider).maxSpeedMs, 5000);
    });
  });
}
