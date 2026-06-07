import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:optiflow/features/speed_reading/domain/text_pagination_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const style = TextStyle(fontSize: 32, fontWeight: FontWeight.w400);

  group('paginateTextIntoLines', () {
    test('single short word fits in one line', () {
      final lines = paginateTextIntoLines(
        rawText: 'Hola',
        maxWidth: 800,
        style: style,
      );
      expect(lines, ['Hola']);
    });

    test('all words appear across lines without loss', () {
      const text = 'uno dos tres cuatro cinco';
      final lines = paginateTextIntoLines(
        rawText: text,
        maxWidth: 800,
        style: style,
      );
      expect(lines.join(' '), text);
    });

    test('wraps long text onto multiple lines for narrow width', () {
      final longText = List.generate(30, (_) => 'palabra').join(' ');
      final lines = paginateTextIntoLines(
        rawText: longText,
        maxWidth: 250,
        style: style,
      );
      expect(lines.length, greaterThan(1));
    });

    test('respects explicit newline as paragraph break', () {
      final lines = paginateTextIntoLines(
        rawText: 'Primera linea\nSegunda linea',
        maxWidth: 800,
        style: style,
      );
      expect(lines.length, 2);
      expect(lines[0], 'Primera linea');
      expect(lines[1], 'Segunda linea');
    });

    test('ignores blank paragraphs', () {
      final lines = paginateTextIntoLines(
        rawText: 'Linea A\n\nLinea B',
        maxWidth: 800,
        style: style,
      );
      expect(lines.length, 2);
    });

    test('each line fits within maxWidth', () {
      const maxW = 300.0;
      final lines = paginateTextIntoLines(
        rawText: List.generate(40, (_) => 'texto').join(' '),
        maxWidth: maxW,
        style: style,
      );
      final painter = TextPainter(textDirection: TextDirection.ltr);
      for (final line in lines) {
        painter
          ..text = TextSpan(text: line, style: style)
          ..layout();
        expect(
          painter.size.width,
          lessThanOrEqualTo(maxW + 1),
          reason: 'Line "$line" exceeds maxWidth',
        );
      }
    });
  });
}
