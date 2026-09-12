import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/strings/app_strings.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/features/voice_coaching/voice_coaching_preference_store.dart';
import 'package:share_run_challenge/features/voice_coaching/voice_coaching_providers.dart';
import 'package:share_run_challenge/features/voice_coaching/voice_coaching_speaker.dart';
import 'package:share_run_challenge/features/voice_coaching/widgets/voice_coaching_walk_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpBanner(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          voiceCoachingSpeakerProvider.overrideWithValue(
            const SilentVoiceCoachingSpeaker(),
          ),
        ],
        child: MaterialApp(
          theme: SrcTheme.light,
          home: const Scaffold(
            body: VoiceCoachingWalkBanner(),
          ),
        ),
      ),
    );
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(VoiceCoachingWalkBanner)),
    );
    await container.read(voiceCoachingEnabledProvider.notifier).ensureLoaded();
    await tester.pump();
  }

  testWidgets('walk banner stays off until tapped, then persists', (tester) async {
    await pumpBanner(tester);

    expect(find.text(AppStrings.voiceCoachingWalkOff), findsOneWidget);
    expect(find.text(AppStrings.voiceCoachingEnable), findsOneWidget);

    await tester.tap(find.byKey(const Key('voice-coaching-walk-toggle')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.text(AppStrings.voiceCoachingWalkOn), findsOneWidget);
    expect(find.text(AppStrings.voiceCoachingDisable), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(VoiceCoachingPreferenceStore.enabledKey), isTrue);
  });
}
