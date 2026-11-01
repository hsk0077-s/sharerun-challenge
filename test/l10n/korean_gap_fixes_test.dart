import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/crew/crew_ranking.dart';
import 'package:share_run_challenge/features/onboarding/src_onboarding_controller.dart';
import 'package:share_run_challenge/l10n/remaining_surface.dart';

import '../support/ko_localization.dart';

final _hangul = RegExp(r'[가-힣]');
const _langs = ['en', 'ja', 'zh', 'es', 'pt', 'de', 'fr', 'vi', 'th', 'id'];

void main() {
  final saved = RemainingSurface.currentLocale;
  tearDown(() => RemainingSurface.currentLocale = saved);

  test('angel names, requirements, perks and gaps have no Korean left', () {
    for (final code in _langs) {
      RemainingSurface.currentLocale = Locale(code);
      for (final tier in AngelTier.values) {
        for (final text in [
          tier.localizedName(),
          tier.circleName(),
          tier.requirementFor(),
          tier.rewardFor(),
        ]) {
          expect(_hangul.hasMatch(text), isFalse,
              reason: '$code ${tier.name}: $text');
        }
      }
      for (final tier in [
        AngelTier.preAngel,
        AngelTier.cupid,
        AngelTier.archangel,
      ]) {
        final gap = tier.nextGapLabel(
          donationCount: 3,
          cumulativeDonationAmount: 100000,
        );
        expect(_hangul.hasMatch(gap), isFalse,
            reason: '$code ${tier.name}: $gap');
        expect(gap.contains(r'$'), isFalse, reason: gap);
      }
      final top = AngelTier.seraphim.nextGapLabel(
        donationCount: 200,
        cumulativeDonationAmount: 9000000,
      );
      expect(_hangul.hasMatch(top), isFalse, reason: '$code: $top');
    }
  });

  test('Korean stays Korean', () {
    RemainingSurface.currentLocale = const Locale('ko', 'KR');
    expect(AngelTier.archangel.localizedName(), '대천사');
    expect(AngelTier.preAngel.circleName(), '예비 천사');
  });

  testWidgets('crew ranking line and crew card are translated', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ja', 'JP'),
      supportedLocales: koTestSupportedLocales,
      localizationsDelegates: koTestDelegates,
      home: Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      }),
    ));
    final ranking = CrewRanking.fromJson({
      'min_members': 5,
      'my_member_count': 1,
      'my_eligible': false,
    });
    final line = ranking.myLineFor(ctx);
    expect(_hangul.hasMatch(line), isFalse, reason: line);
    expect(line, contains('5'));
    for (final key in [
      'running_crew.card_open',
      'running_crew.card_approval'
    ]) {
      final text = RemainingSurface.tr(ctx, key, '한국어', {
        'crew.memberCount': 1,
        'crew.maxMembers': 50,
      });
      expect(_hangul.hasMatch(text), isFalse, reason: text);
      expect(text, contains('1/50'));
    }
    expect(
      _hangul.hasMatch(RemainingSurface.tr(ctx, 'common.preparing', '준비 중')),
      isFalse,
    );
  });
}
