import 'package:shared_preferences/shared_preferences.dart';

/// Local health-data consent flag for MVP (no Firebase required).
class HealthDataConsentStore {
  static const isHealthDataAgreedKey = 'isHealthDataAgreed';

  Future<bool> readAgreed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(isHealthDataAgreedKey) ?? false;
  }

  Future<void> writeAgreed(bool agreed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(isHealthDataAgreedKey, agreed);
  }
}
