import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static const String appOpen = 'audio/israel-novaes.mp3';
  static const String loss    = 'audio/loss.mp3';
  static const String rabbi   = 'audio/rabbi.mp3';

  // Sound played when the user invests in each asset
  static const Map<String, String> _assetSounds = {
    'kibbutz':   'audio/kibbutz.mp3',
    'startup':   'audio/tel-aviv.mp3',
    'hummus':    'audio/hummus.mp3',
    'dead_sea':  'audio/dead_sea.mp3',
    'diamonds':  'audio/diamonds.mp3',
    'yeshiva':   'audio/yeshiva.mp3',
    'idf':       'audio/idf.mp3',
    'falafel':   'audio/falafel.mp3',
    'mossad':    'audio/military.mp3',
    'iron_dome': 'audio/dome.mp3',
  };

  // Manual set instead of relying on PlayerState (more reliable across Android versions)
  static final Set<String> _playing = {};
  static final Map<String, AudioPlayer> _players = {};

  static Future<void> play(String sound) async {
    if (_playing.contains(sound)) return;
    _playing.add(sound);

    final player = _players.putIfAbsent(sound, () {
      final p = AudioPlayer();
      p.onPlayerComplete.listen((_) => _playing.remove(sound));
      return p;
    });

    await player.play(AssetSource(sound));

    // Hard cap at 3 seconds
    Future.delayed(const Duration(seconds: 3), () async {
      if (_playing.contains(sound)) {
        await player.stop();
        _playing.remove(sound);
      }
    });
  }

  static Future<void> playForAsset(String assetId) async {
    final sound = _assetSounds[assetId];
    if (sound != null) await play(sound);
  }

  static void disposeAll() {
    for (final p in _players.values) p.dispose();
    _players.clear();
    _playing.clear();
  }
}
