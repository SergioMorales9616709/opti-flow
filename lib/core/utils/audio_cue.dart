enum AudioCue {
  click('audio/click.mp3', isBgm: false),
  bgmFlow('audio/bgm_flow.mp3', isBgm: true);

  const AudioCue(this.path, {required this.isBgm});

  final String path;
  final bool isBgm;
}
