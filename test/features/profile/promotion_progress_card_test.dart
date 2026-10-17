import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/strings/app_strings.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/data/models/user_model.dart';
import 'package:share_run_challenge/features/profile/user_profile_notifier.dart';
import 'package:share_run_challenge/features/profile/widgets/my_dashboard_sections.dart';

class _Profile extends UserProfileNotifier {
  _Profile(this._profile);
  final UserModel _profile;
  @override
  UserProfile build() => _profile;
}

Future<void> _pump(WidgetTester tester, UserModel profile) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [userProfileProvider.overrideWith(() => _Profile(profile))],
      child: MaterialApp(
        theme: SrcTheme.night,
        home: const Scaffold(body: PromotionProgressCard()),
      ),
    ),
  );
  await tester.pump();
}

UserModel _user({
  int rank = 12,
  int points = 0,
  int step = 0,
  String blocked = '',
}) =>
    UserModel.dashboardDefault(uid: 'u1').copyWith(
      gradeRank: rank,
      promotionPoints: points,
      promotionStep: step,
      promotionBlocked: blocked,
    );

void main() {
  testWidgets('shows the server points and step', (tester) async {
    await _pump(tester, _user(points: 25, step: 40));
    expect(find.text(AppStrings.promotionProgress(25, 40)), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byKey(PromotionProgressCard.barKey),
    );
    expect(bar.value, closeTo(25 / 40, 1e-9));
  });

  testWidgets('before the first result it uses the animal default step',
      (tester) async {
    await _pump(tester, _user(rank: 3));
    expect(find.text(AppStrings.promotionProgress(0, 20)), findsOneWidget);
    expect(find.text(AppStrings.promotionHint), findsOneWidget);
  });

  testWidgets('says why a full bar did not promote', (tester) async {
    await _pump(tester, _user(points: 40, step: 40, blocked: 'pace'));
    expect(find.text(AppStrings.promotionBlockedPace), findsOneWidget);
  });

  testWidgets('a snail has no points and the top rank has nothing next',
      (tester) async {
    await _pump(tester, _user(rank: 0));
    expect(find.text(AppStrings.promotionTitle), findsNothing);
    await _pump(tester, _user(rank: 25));
    expect(find.text(AppStrings.promotionTitle), findsNothing);
  });

  test('fallback step follows the animal', () {
    expect(PromotionProgressCard.fallbackStep(1), 20);
    expect(PromotionProgressCard.fallbackStep(6), 30);
    expect(PromotionProgressCard.fallbackStep(11), 40);
    expect(PromotionProgressCard.fallbackStep(16), 60);
    expect(PromotionProgressCard.fallbackStep(24), 60);
  });

  test('user json reads the server promotion map', () {
    final user = UserModel.fromJson({
      'uid': 'u1',
      'gradeRank': 7,
      'promotion': {'points': 12, 'step': 30, 'blocked': 'cooldown'},
    });
    expect(user.promotionPoints, 12);
    expect(user.promotionStep, 30);
    expect(user.promotionBlocked, 'cooldown');
    expect(UserModel.fromJson({'uid': 'u2'}).promotionPoints, 0);
  });
}
