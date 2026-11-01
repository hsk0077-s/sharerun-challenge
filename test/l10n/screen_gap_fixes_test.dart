import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/accessories/accessory_catalog.dart';
import 'package:share_run_challenge/features/iap/payment_auth.dart';
import 'package:share_run_challenge/features/jena_validation/verification_reason.dart';
import 'package:share_run_challenge/features/onboarding/src_onboarding_controller.dart';
import 'package:share_run_challenge/features/run_result/run_finish_share_card.dart';
import 'package:share_run_challenge/features/run_tracking/run_recording_policy.dart';
import 'package:share_run_challenge/l10n/remaining_surface.dart';

final _hangul = RegExp(r'[가-힣]');
const _langs = ['en', 'ja', 'zh', 'es', 'pt', 'de', 'fr', 'vi', 'th', 'id'];

void main() {
  final saved = RemainingSurface.currentLocale;
  tearDown(() => RemainingSurface.currentLocale = saved);

  test('shop slots, rarities and tier names have no Korean in any language', () {
    for (final code in _langs) {
      RemainingSurface.currentLocale = Locale(code);
      for (final text in [
        for (final s in AccessorySlot.values) s.label(),
        for (final r in AccessoryRarity.values) r.label(),
        for (final a in TierAnimal.values) a.label(),
      ]) {
        expect(_hangul.hasMatch(text), isFalse, reason: '$code: $text');
      }
    }
  });

  test('Korean labels stay as they were', () {
    RemainingSurface.currentLocale = const Locale('ko', 'KR');
    expect(AccessorySlot.head.label(), '머리');
    expect(AccessoryRarity.tierReward.label(), '티어 보상');
    expect(AccessoryRarity.rare.label(), '희귀');
  });

  test('run verdicts, payment checks and recording notices are translated', () {
    for (final code in _langs) {
      RemainingSurface.currentLocale = Locale(code);
      final texts = <String>[
        for (final reason in [
          'distance_too_short',
          'cadence_out_of_range',
          'heart_rate_required',
          'heart_rate_low',
          'heart_rate_flat',
          'stride_out_of_range',
          'vehicle_speed',
          'kickboard',
          'bike',
        ])
          verificationReasonKo(reason)!,
        verificationRejectedFallback,
        for (final r in PaymentAuthResult.values) paymentAuthMessage(r),
        interruptedRunTitle,
        interruptedRunBody,
        runRecordingBatteryGuidance,
        runFinishDonationCapLine,
        runFinishDailyDonationCapLine,
        runFinishDonationLine(12000)!,
        runFinishDonationSkippedLine(''),
      ];
      for (final text in texts) {
        expect(_hangul.hasMatch(text), isFalse, reason: '$code: $text');
      }
      expect(runFinishDonationLine(12000), contains('12,000'));
    }
  });

  test('Korean run verdicts are unchanged', () {
    RemainingSurface.currentLocale = const Locale('ko', 'KR');
    expect(verificationReasonKo('kickboard'),
        '킥보드나 탑승으로 보여 보상은 지급되지 않아요. 기록은 남아요.');
    expect(runFinishDonationLine(12000), '이번 달리기로 운영자가 12,000원을 기부할 예정이에요');
  });
}
