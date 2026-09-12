import 'package:shared_preferences/shared_preferences.dart';

/// Device-local voice-coaching toggle. Survives process death / app restart.
class VoiceCoachingPreferenceStore {
  const VoiceCoachingPreferenceStore();

  static const enabledKey = 'src.voice_coaching.enabled';

  /// Default **off** so a first launch never surprises the user with TTS.
  Future<bool> readEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(enabledKey) ?? false;
  }

  Future<void> writeEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(enabledKey, enabled);
  }
}
