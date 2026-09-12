import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/voice_coaching/voice_coaching_preference_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const store = VoiceCoachingPreferenceStore();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults to off so first launch does not speak', () async {
    expect(await store.readEnabled(), isFalse);
  });

  test('persists the toggle across a fresh store read', () async {
    await store.writeEnabled(true);

    const restarted = VoiceCoachingPreferenceStore();
    expect(await restarted.readEnabled(), isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(VoiceCoachingPreferenceStore.enabledKey), isTrue);

    await restarted.writeEnabled(false);
    expect(await store.readEnabled(), isFalse);
  });
}
