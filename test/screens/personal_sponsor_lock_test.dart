import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/core/config/app_env.dart';
import 'package:share_run_challenge/data/repositories/user_repository.dart';
import 'package:share_run_challenge/features/profile/widgets/angel_tier_widgets.dart';
import 'package:share_run_challenge/screens/personal_sponsor_screen.dart';

import '../support/ko_localization.dart';

class _NoCallRepo implements UserRepository {
  int donations = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #recordDonation) donations++;
    throw StateError('unexpected ${invocation.memberName}');
  }
}

Widget _app(Widget home, _NoCallRepo repo) => ProviderScope(
      overrides: [userRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        locale: koTestLocale,
        supportedLocales: koTestSupportedLocales,
        localizationsDelegates: koTestDelegates,
        home: home,
      ),
    );

class _Opener extends StatelessWidget {
  const _Opener();
  @override
  Widget build(BuildContext context) => Scaffold(
        body: TextButton(
          onPressed: () => openPersonalSponsor(context),
          child: const Text('open'),
        ),
      );
}

void main() {
  tearDown(() => AppEnv.debugSponsorPaymentsOverride = null);

  testWidgets('스위치가 꺼져 있으면 openPersonalSponsor가 화면을 열지 않는다', (tester) async {
    AppEnv.debugSponsorPaymentsOverride = false;
    final repo = _NoCallRepo();
    await tester.pumpWidget(_app(const _Opener(), repo));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(PersonalSponsorScreen), findsNothing);
    expect(find.text('open'), findsOneWidget);
    expect(repo.donations, 0);
  });

  testWidgets('스위치가 꺼진 채 열린 화면에는 후원 버튼이 없고 서버 호출이 없다', (tester) async {
    AppEnv.debugSponsorPaymentsOverride = false;
    final repo = _NoCallRepo();
    await tester.pumpWidget(_app(const PersonalSponsorScreen(), repo));
    await tester.pump();
    expect(find.byKey(const Key('sponsor-closed-message')), findsOneWidget);
    expect(find.text('지금은 이용할 수 없는 기능이에요.'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
    expect(repo.donations, 0);
  });

  testWidgets('스위치가 켜져 있으면 openPersonalSponsor가 화면을 연다', (tester) async {
    AppEnv.debugSponsorPaymentsOverride = true;
    final repo = _NoCallRepo();
    await tester.pumpWidget(_app(const _Opener(), repo));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    tester.takeException();
    expect(find.byType(PersonalSponsorScreen), findsOneWidget);
    expect(find.byKey(const Key('sponsor-closed-message')), findsNothing);
  });
}
