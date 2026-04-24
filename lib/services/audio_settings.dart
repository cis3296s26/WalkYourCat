class AudioSettings {
  static double sfxVolume = 1.0;
  static double musicVolume = 1.0;

  static bool sfxMuted = false;
  static bool musicMuted = false;

  static double get effectiveSfxVolume =>
      sfxMuted ? 0.0 : sfxVolume;

  static double get effectiveMusicVolume =>
      musicMuted ? 0.0 : musicVolume;

  static void toggleSfxMute() {
    sfxMuted = !sfxMuted;
  }

  static void toggleMusicMute() {
    musicMuted = !musicMuted;
  }

  static void setSfxVolume(double value) {
    sfxVolume = value.clamp(0.0, 1.0);
  }

  static void setMusicVolume(double value) {
    musicVolume = value.clamp(0.0, 1.0);
  }
}