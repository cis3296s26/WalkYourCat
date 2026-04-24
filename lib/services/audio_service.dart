import 'package:audioplayers/audioplayers.dart';
import 'audio_settings.dart';

class AudioService {
  static final AudioPlayer _sfxPlayer = AudioPlayer();

  static Future<void> playSfx(String asset) async {
    await _sfxPlayer.setVolume(AudioSettings.effectiveSfxVolume);
    await _sfxPlayer.play(AssetSource(asset));
  }
}