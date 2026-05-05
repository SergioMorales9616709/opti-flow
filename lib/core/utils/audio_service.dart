import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:optiflow/core/utils/audio_cue.dart';

class AudioService {
  final Map<AudioCue, AudioPlayer> _players = {};
  AudioPlayer? _bgmPlayer;

  Future<void> init() async {
    for (final cue in AudioCue.values.where((c) => !c.isBgm)) {
      final player = AudioPlayer();
      await player.setPlayerMode(PlayerMode.lowLatency);
      // ReleaseMode.stop keeps the source loaded in memory after each play.
      // The default ReleaseMode.release would free the asset on completion,
      // silencing all ticks after the first.
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setSourceAsset(cue.path);
      _players[cue] = player;
    }
    // _bgmPlayer is intentionally NOT initialized here.
    // Initializing WMF-backed players (mediaPlayer mode) during app startup
    // triggers platform-channel callbacks on non-platform threads before
    // Flutter's render tree is stable, crashing the Windows app.
    // The BGM player is created lazily on the first playBgm() call instead.
  }

  Future<void> play(AudioCue cue) async {
    final player = _players[cue];
    if (player == null) return;
    await player.seek(Duration.zero);
    await player.resume();
  }

  Future<void> playBgm({double volume = 0.5}) async {
    if (_bgmPlayer == null) {
      _bgmPlayer = AudioPlayer();
      await _bgmPlayer!.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer!.setSourceAsset(AudioCue.bgmFlow.path);
    }
    await _bgmPlayer?.setVolume(volume);
    await _bgmPlayer?.resume();
  }

  Future<void> stopBgm() async => _bgmPlayer?.stop();

  Future<void> dispose() async {
    for (final player in _players.values) {
      await player.dispose();
    }
    _players.clear();
    await _bgmPlayer?.dispose();
    _bgmPlayer = null;
  }
}

final audioServiceProvider = Provider<AudioService>((ref) {
  throw UnimplementedError(
    'audioServiceProvider must be overridden in ProviderScope',
  );
});
