import 'package:flutter_test/flutter_test.dart';
import 'package:optiflow/features/speed_reading/data/text_repository.dart';

void main() {
  group('parseTextToWords', () {
    test('splits a simple sentence into words', () {
      const raw = 'Hola mundo cruel';
      expect(parseTextToWords(raw), ['Hola', 'mundo', 'cruel']);
    });

    test('collapses multiple consecutive spaces', () {
      const raw = 'uno  dos   tres';
      expect(parseTextToWords(raw), ['uno', 'dos', 'tres']);
    });

    test('collapses newlines and tabs into spaces', () {
      const raw = 'primera\nsegunda\ttercer';
      expect(parseTextToWords(raw), ['primera', 'segunda', 'tercer']);
    });

    test('strips leading and trailing whitespace', () {
      const raw = '  hola mundo  ';
      expect(parseTextToWords(raw), ['hola', 'mundo']);
    });

    test('filters out empty strings', () {
      const raw = 'a  b';
      final result = parseTextToWords(raw);
      expect(result.every((w) => w.isNotEmpty), isTrue);
    });

    test('preserves punctuation attached to words', () {
      const raw = 'Hola, mundo.';
      final result = parseTextToWords(raw);
      expect(result, ['Hola,', 'mundo.']);
    });

    test('returns empty list for blank text', () {
      expect(parseTextToWords(''), isEmpty);
      expect(parseTextToWords('   '), isEmpty);
    });
  });
}
