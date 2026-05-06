enum AudioCue {
  click('audio/click.mp3', isBgm: false),
  bgmFlow('audio/bgm_flow.mp3', isBgm: true),
  success('audio/success.mp3', isBgm: false);

  const AudioCue(this.path, {required this.isBgm});

  final String path;
  final bool isBgm;
}
