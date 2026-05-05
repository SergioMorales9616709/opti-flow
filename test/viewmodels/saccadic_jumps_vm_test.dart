import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:optiflow/features/vision_training/presentation/viewmodels/saccadic_jumps_viewmodel.dart';

void main() {
  group('SaccadicJumpsNotifier initial state', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('default speedMs is 800', () {
      expect(container.read(saccadicJumpsProvider).speedMs, 800);
    });

    test('minSpeedMs is 300', () {
      expect(container.read(saccadicJumpsProvider).minSpeedMs, 300);
    });

    test('maxSpeedMs is 1200', () {
      expect(container.read(saccadicJumpsProvider).maxSpeedMs, 1200);
    });
  });
}
