import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:optiflow/core/database/progress_repository.dart';
import 'package:optiflow/core/utils/audio_service.dart';
import 'package:optiflow/features/speed_reading/data/text_repository.dart';
import 'package:optiflow/features/speed_reading/domain/text_pagination_utils.dart';

const _kDefaultWpm = 300;
const _kMinWpm = 200;
const _kMaxWpm = 1200;
const _kAssetPath = 'assets/texts/cuento_1.txt';

/// Returns the display duration in ms for [line] at [wpm].
/// Exposed at library level for unit testing.
int msForLine(String line, int wpm) {
  final wordCount = line.split(' ').where((w) => w.isNotEmpty).length;
  return (60000 ~/ wpm) * wordCount;
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class GuidedLinesState {
  const GuidedLinesState({
    this.lines = const [],
    this.currentLineIndex = 0,
    this.currentWpm = _kDefaultWpm,
    this.isPlaying = false,
    this.isMuted = false,
    this.isLoaded = false,
  });

  final List<String> lines;
  final int currentLineIndex;
  final int currentWpm;
  final bool isPlaying;
  final bool isMuted;
  final bool isLoaded;

  GuidedLinesState copyWith({
    List<String>? lines,
    int? currentLineIndex,
    int? currentWpm,
    bool? isPlaying,
    bool? isMuted,
    bool? isLoaded,
  }) {
    return GuidedLinesState(
      lines: lines ?? this.lines,
      currentLineIndex: currentLineIndex ?? this.currentLineIndex,
      currentWpm: currentWpm ?? this.currentWpm,
      isPlaying: isPlaying ?? this.isPlaying,
      isMuted: isMuted ?? this.isMuted,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class GuidedLinesNotifier extends Notifier<GuidedLinesState> {
  bool _running = false;
  String _rawText = '';

  @override
  GuidedLinesState build() {
    // Capture before disposal — ref.read is invalid after container tears down.
    final audioService = ref.read(audioServiceProvider);
    ref.onDispose(() {
      _running = false;
      audioService.stopBgm();
    });
    _loadText();
    return const GuidedLinesState();
  }

  Future<void> _loadText() async {
    final words = await ref.read(textRepositoryProvider).loadWords(_kAssetPath);
    _rawText = words.join(' ');
    state = state.copyWith(isLoaded: true);
  }

  /// Called from GuidedLinesView via LayoutBuilder once the widget width is
  /// known.
  void paginate(double maxWidth, TextStyle style) {
    if (_rawText.isEmpty) return;
    final lines = paginateTextIntoLines(
      rawText: _rawText,
      maxWidth: maxWidth,
      style: style,
    );
    state = state.copyWith(lines: lines, currentLineIndex: 0);
  }

  void setWpm(int wpm) {
    state = state.copyWith(currentWpm: wpm.clamp(_kMinWpm, _kMaxWpm));
  }

  void toggleMute() {
    final muted = !state.isMuted;
    state = state.copyWith(isMuted: muted);
    final audio = ref.read(audioServiceProvider);
    if (state.isPlaying) {
      muted ? audio.stopBgm() : audio.playBgm();
    }
  }

  Future<void> startReading() async {
    if (state.isPlaying || state.lines.isEmpty) return;
    _running = true;
    state = state.copyWith(isPlaying: true);
    if (!state.isMuted) {
      unawaited(ref.read(audioServiceProvider).playBgm());
    }

    while (_running && state.currentLineIndex < state.lines.length) {
      final line = state.lines[state.currentLineIndex];
      final ms = msForLine(line, state.currentWpm);
      await Future<void>.delayed(Duration(milliseconds: ms));
      if (!_running) break;
      state = state.copyWith(currentLineIndex: state.currentLineIndex + 1);
    }

    if (_running) await _onFinished();
  }

  void pause() {
    _running = false;
    if (state.isPlaying) {
      state = state.copyWith(isPlaying: false);
      ref.read(audioServiceProvider).stopBgm();
    }
    unawaited(_persist());
  }

  Future<void> _onFinished() async {
    _running = false;
    unawaited(ref.read(audioServiceProvider).stopBgm());
    state = state.copyWith(isPlaying: false);
    await _persist();
  }

  Future<void> _persist() async {
    await ref.read(progressRepositoryProvider).saveProgress(
      exerciseType: 'speed_reading_guided_lines',
      maxSpeedMs: state.currentWpm,
    );
  }
}

final guidedLinesProvider =
    NotifierProvider<GuidedLinesNotifier, GuidedLinesState>(
  GuidedLinesNotifier.new,
);
