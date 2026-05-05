import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'audio_cue.dart';

class AudioService {
  final Map<AudioCue, AudioPlayer> _players = {};

  Future<void> init() async {
    for (final cue in AudioCue.values) {
      final player = AudioPlayer();
      await player.setPlayerMode(PlayerMode.lowLatency);
      // ReleaseMode.stop keeps the source loaded in memory after each play.
      // The default ReleaseMode.release would free the asset on completion,
      // silencing all ticks after the first.
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setSourceAsset(cue.path);
      _players[cue] = player;
    }
  }

  Future<void> play(AudioCue cue) async {
    final player = _players[cue];
    if (player == null) return;
    await player.seek(Duration.zero);
    await player.resume();
  }

  Future<void> dispose() async {
    for (final player in _players.values) {
      await player.dispose();
    }
    _players.clear();
  }
}

final audioServiceProvider = Provider<AudioService>((ref) {
  throw UnimplementedError(
    'audioServiceProvider must be overridden in ProviderScope',
  );
});
