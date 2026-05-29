// Neuro-reading domain utilities: chunking and Optimal Recognition Point.
// All functions are top-level and pure — no Flutter/Riverpod dependencies.

// ─────────────────────────────────────────────────────────────────────────────
// Chunking
// ─────────────────────────────────────────────────────────────────────────────

const _kMaxChunkLen = 3;
const _kMajorPunct = {'.', '?', '!', ';', ':'};

// Groups short words (≤ 3 chars) with the following word.
// Words ending in major punctuation are never merged.
// Single left-to-right pass — merged results are not re-evaluated.
List<String> chunkWords(List<String> words) {
  final result = <String>[];
  var i = 0;
  while (i < words.length) {
    final word = words[i];
    final canMerge =
        word.length <= _kMaxChunkLen &&
        !_kMajorPunct.any(word.endsWith) &&
        i + 1 < words.length;
    if (canMerge) {
      result.add('$word ${words[i + 1]}');
      i += 2;
    } else {
      result.add(word);
      i += 1;
    }
  }
  return result;
}

// ─────────────────────────────────────────────────────────────────────────────
// ORP — Optimal Recognition Point
// ─────────────────────────────────────────────────────────────────────────────

// Splits a word or chunk into three parts around the ORP letter.
// Spaces are ignored when computing effective length and ORP index,
// but preserved in the returned left/right strings so the
// display widget keeps correct spacing for multi-word chunks.
typedef OrpParts = ({String left, String orp, String right});

OrpParts getOrpParts(String chunk) {
  final effectiveLen = chunk.replaceAll(' ', '').length;
  final orpIdx = _orpIndex(effectiveLen);

  // Walk the full string, counting only non-space chars.
  var nonSpaceCount = 0;
  for (var pos = 0; pos < chunk.length; pos++) {
    if (chunk[pos] != ' ') {
      if (nonSpaceCount == orpIdx) {
        return (
          left: chunk.substring(0, pos),
          orp: chunk[pos],
          right: chunk.substring(pos + 1),
        );
      }
      nonSpaceCount++;
    }
  }
  // Fallback: should never happen for non-empty input.
  return (left: chunk, orp: '', right: '');
}

int _orpIndex(int effectiveLen) {
  if (effectiveLen <= 1) return 0;
  if (effectiveLen <= 5) return 1;
  if (effectiveLen <= 9) return 2;
  if (effectiveLen <= 13) return 3;
  return 4;
}
