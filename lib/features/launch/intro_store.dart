import 'package:shared_preferences/shared_preferences.dart';

/// 첫 설치 소개를 봤는지. 화면 설정일 뿐 재화·등급과는 무관해서 기기에 둔다.
class IntroStore {
  const IntroStore();

  static const _seenKey = 'src.launch.intro_seen_v1';

  Future<bool> seen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_seenKey) ?? false;
    } catch (_) {
      return true; // 읽지 못하면 소개를 막지 않고 건너뛴다.
    }
  }

  Future<void> markSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_seenKey, true);
    } catch (_) {}
  }
}
