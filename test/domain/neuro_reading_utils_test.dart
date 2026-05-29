import 'package:flutter_test/flutter_test.dart';
import 'package:optiflow/features/speed_reading/domain/neuro_reading_utils.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // chunkWords
  // ─────────────────────────────────────────────────────────────────────────
  group('chunkWords', () {
    group('basic merging', () {
      test('merges short word (≤3) with next word', () {
        expect(chunkWords(['La', 'casa']), ['La casa']);
      });

      test('merges two separate pairs independently', () {
        expect(chunkWords(['La', 'casa', 'de', 'papel']), [
          'La casa',
          'de papel',
        ]);
      });

      test('long word (>3) is kept alone', () {
        expect(chunkWords(['para', 'siempre']), ['para', 'siempre']);
      });

      test('exactly 3 chars is eligible for merge', () {
        expect(chunkWords(['uno', 'más']), ['uno más']);
      });

      test('4 chars is NOT eligible for merge', () {
        expect(chunkWords(['para', 'casa']), ['para', 'casa']);
      });
    });

    group('major punctuation blocks merge', () {
      test('word ending in period is not merged', () {
        expect(chunkWords(['Fin.', 'El', 'mar']), ['Fin.', 'El mar']);
      });

      test('word ending in question mark is not merged', () {
        expect(chunkWords(['¿Sí?', 'El', 'mar']), ['¿Sí?', 'El mar']);
      });

      test('word ending in exclamation mark is not merged', () {
        expect(chunkWords(['No!', 'El', 'mar']), ['No!', 'El mar']);
      });

      test('word ending in semicolon is not merged', () {
        expect(chunkWords(['así;', 'El', 'mar']), ['así;', 'El mar']);
      });

      test('word ending in colon is not merged', () {
        expect(chunkWords(['así:', 'El', 'mar']), ['así:', 'El mar']);
      });
    });

    group('comma does not block merge', () {
      test('word ending in comma IS merged', () {
        expect(chunkWords(['un,', 'día']), ['un, día']);
      });
    });

    group('edge cases', () {
      test('last short word kept solo (no next word)', () {
        expect(chunkWords(['casa', 'es']), ['casa', 'es']);
      });

      test('returns empty list for empty input', () {
        expect(chunkWords([]), <String>[]);
      });

      test('single short word returned as-is', () {
        expect(chunkWords(['yo']), ['yo']);
      });

      test('merged chunk is not re-merged with next short word', () {
        // 'yo'+'no' → 'yo no'; then 'sé' is last → kept solo
        expect(chunkWords(['yo', 'no', 'sé']), ['yo no', 'sé']);
      });

      test('long word between short words breaks the chain', () {
        expect(chunkWords(['de', 'extraordinario', 'en', 'el']), [
          'de extraordinario',
          'en el',
        ]);
      });
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // getOrpParts
  // ─────────────────────────────────────────────────────────────────────────
  group('getOrpParts', () {
    group('length 1 → index 0', () {
      test('single char: orp is the only char', () {
        final p = getOrpParts('a');
        expect(p.left, '');
        expect(p.orp, 'a');
        expect(p.right, '');
      });
    });

    group('length 2–5 → index 1', () {
      test('length 2: orp is second char', () {
        final p = getOrpParts('él');
        expect(p.left, 'é');
        expect(p.orp, 'l');
        expect(p.right, '');
      });

      test('length 3: orp is second char', () {
        final p = getOrpParts('una');
        expect(p.left, 'u');
        expect(p.orp, 'n');
        expect(p.right, 'a');
      });

      test('length 5: orp is second char', () {
        final p = getOrpParts('cinco');
        expect(p.left, 'c');
        expect(p.orp, 'i');
        expect(p.right, 'nco');
      });
    });

    group('length 6–9 → index 2', () {
      test('length 6: orp is third char', () {
        final p = getOrpParts('cuando');
        expect(p.left, 'cu');
        expect(p.orp, 'a');
        expect(p.right, 'ndo');
      });

      test('length 7 (spec example): "palabra" → orp at index 2 = l', () {
        final p = getOrpParts('palabra');
        expect(p.left, 'pa');
        expect(p.orp, 'l');
        expect(p.right, 'abra');
      });

      test('length 9: orp is third char', () {
        final p = getOrpParts('alrededor');
        expect(p.left, 'al');
        expect(p.orp, 'r');
        expect(p.right, 'ededor');
      });
    });

    group('length 10–13 → index 3', () {
      test('length 10: orp is fourth char', () {
        final p = getOrpParts('abcdefghij');
        expect(p.left, 'abc');
        expect(p.orp, 'd');
        expect(p.right, 'efghij');
      });

      test('length 13: orp is fourth char', () {
        final p = getOrpParts('abcdefghijklm');
        expect(p.left, 'abc');
        expect(p.orp, 'd');
        expect(p.right, 'efghijklm');
      });
    });

    group('length >13 → index 4', () {
      test('length 14: orp is fifth char', () {
        final p = getOrpParts('abcdefghijklmn');
        expect(p.left, 'abcd');
        expect(p.orp, 'e');
        expect(p.right, 'fghijklmn');
      });
    });

    group('chunks with spaces', () {
      test('"La casa": 6 non-space → idx 2 → 3rd non-space = c', () {
        final p = getOrpParts('La casa');
        expect(p.left, 'La ');
        expect(p.orp, 'c');
        expect(p.right, 'asa');
      });

      test('"de papel," (8 non-space) → idx 2 → orp = p', () {
        final p = getOrpParts('de papel,');
        expect(p.left, 'de ');
        expect(p.orp, 'p');
        expect(p.right, 'apel,');
      });

      test('"yo no" (4 non-space) → idx 1 → 2nd non-space = o', () {
        final p = getOrpParts('yo no');
        expect(p.left, 'y');
        expect(p.orp, 'o');
        expect(p.right, ' no');
      });
    });

    group('right can be empty', () {
      test('orp at last position leaves right empty', () {
        final p = getOrpParts('ab');
        expect(p.right, '');
      });
    });
  });
}
