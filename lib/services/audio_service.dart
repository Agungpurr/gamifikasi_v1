// lib/services/audio_service.dart

import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService {
  static final AudioPlayer _sfxPlayer = AudioPlayer();
  static final AudioPlayer _bgmPlayer = AudioPlayer();

  static bool _sfxEnabled = true;
  static bool _bgmEnabled = true;

  // ═══════════════════════════════════════
  // INIT & SETTINGS
  // ═══════════════════════════════════════

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _sfxEnabled = prefs.getBool('sfx_enabled') ?? true;
    _bgmEnabled = prefs.getBool('bgm_enabled') ?? true;

    _bgmPlayer.setReleaseMode(ReleaseMode.loop); // BGM loop otomatis
    _bgmPlayer.setVolume(0.4); // BGM lebih pelan dari SFX
  }

  static Future<void> toggleSfx() async {
    _sfxEnabled = !_sfxEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sfx_enabled', _sfxEnabled);
  }

  static Future<void> toggleBgm() async {
    _bgmEnabled = !_bgmEnabled;
    if (!_bgmEnabled) {
      await _bgmPlayer.stop();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bgm_enabled', _bgmEnabled);
  }

  static bool get isSfxEnabled => _sfxEnabled;
  static bool get isBgmEnabled => _bgmEnabled;

  // ═══════════════════════════════════════
  // BACKGROUND MUSIC
  // ═══════════════════════════════════════

  static Future<void> playHomeBgm() async {
    if (!_bgmEnabled) return;
    await _bgmPlayer.stop();
    await _bgmPlayer.play(AssetSource('music/bgm_home.mp3'));
  }

  static Future<void> playQuizBgm() async {
    if (!_bgmEnabled) return;
    await _bgmPlayer.stop();
    await _bgmPlayer.play(AssetSource('music/bgm_quiz.mp3'));
  }

  static Future<void> stopBgm() async {
    await _bgmPlayer.stop();
  }

  static Future<void> pauseBgm() async {
    await _bgmPlayer.pause();
  }

  static Future<void> resumeBgm() async {
    if (!_bgmEnabled) return;
    await _bgmPlayer.resume();
  }

  // ═══════════════════════════════════════
  // SOUND EFFECTS
  // ═══════════════════════════════════════

  static Future<void> playCorrect() async {
    if (!_sfxEnabled) return;
    await _sfxPlayer.play(AssetSource('sounds/correct.wav'));
  }

  static Future<void> playWrong() async {
    if (!_sfxEnabled) return;
    await _sfxPlayer.play(AssetSource('sounds/wrong.ogg'));
  }

  static Future<void> playLevelUp() async {
    if (!_sfxEnabled) return;
    await _sfxPlayer.play(AssetSource('sounds/level_up.mp3'));
  }

  static Future<void> playBadgeEarned() async {
    if (!_sfxEnabled) return;
    await _sfxPlayer.play(AssetSource('sounds/win.mp3'));
  }

  static Future<void> playButtonClick() async {
    if (!_sfxEnabled) return;
    await _sfxPlayer.play(AssetSource('sounds/button_click.mp3'));
  }

  static Future<void> dispose() async {
    await _sfxPlayer.dispose();
    await _bgmPlayer.dispose();
  }
}
