import 'package:flutter/material.dart';

/// Splits [rawText] into display lines that each fit within [maxWidth] at
/// the given [style]. Paragraph breaks (\n) in the source are preserved as
/// line boundaries regardless of available width.
///
/// [textScaler] must match `MediaQuery.textScalerOf(context)` from the
/// rendering view — otherwise this measures glyphs at a different size than
/// the `Text` widgets actually paint them at (e.g. under Windows display
/// scaling or accessibility text-size settings), so "lines that fit" on
/// paper wrap when rendered and overflow their fixed-height rows.
List<String> paginateTextIntoLines({
  required String rawText,
  required double maxWidth,
  required TextStyle style,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  final result = <String>[];
  // Reuse one painter to avoid allocating hundreds of objects.
  final painter = TextPainter(
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
  );

  for (final paragraph in rawText.split('\n')) {
    final trimmed = paragraph.trim();
    if (trimmed.isEmpty) continue;

    final words = trimmed.split(' ').where((w) => w.isNotEmpty).toList();
    var currentLine = '';

    for (final word in words) {
      final candidate = currentLine.isEmpty ? word : '$currentLine $word';
      painter
        ..text = TextSpan(text: candidate, style: style)
        ..layout();

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
