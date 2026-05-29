import 'package:flutter/material.dart';

/// Splits [rawText] into display lines that each fit within [maxWidth] at
/// the given [style]. Paragraph breaks (\n) in the source are preserved as
/// line boundaries regardless of available width.
List<String> paginateTextIntoLines({
  required String rawText,
  required double maxWidth,
  required TextStyle style,
}) {
  final result = <String>[];
  // Reuse one painter to avoid allocating hundreds of objects.
  final painter = TextPainter(textDirection: TextDirection.ltr);

  for (final paragraph in rawText.split('\n')) {
    final trimmed = paragraph.trim();
    if (trimmed.isEmpty) continue;

    final words = trimmed.split(' ').where((w) => w.isNotEmpty).toList();
    var currentLine = '';

    for (final word in words) {
      final candidate = currentLine.isEmpty ? word : '$currentLine $word';
      painter
        ..text = TextSpan(text: candidate, style: style)
        ..layout(maxWidth: double.infinity);

      if (painter.size.width > maxWidth && currentLine.isNotEmpty) {
        result.add(currentLine);
        currentLine = word;
      } else {
        currentLine = candidate;
      }
    }

    if (currentLine.isNotEmpty) result.add(currentLine);
  }

  return result;
}
