import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Splits raw text into a list of words, collapsing all whitespace.
/// Exposed at library level so it can be unit-tested directly.
List<String> parseTextToWords(String raw) {
  return raw
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .split(' ')
      .where((w) => w.isNotEmpty)
      .toList();
}

abstract interface class TextRepository {
  Future<List<String>> loadWords(String assetPath);
}

class TextRepositoryImpl implements TextRepository {
  @override
  Future<List<String>> loadWords(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    return parseTextToWords(raw);
  }
}

final textRepositoryProvider = Provider<TextRepository>(
  (_) => TextRepositoryImpl(),
);
