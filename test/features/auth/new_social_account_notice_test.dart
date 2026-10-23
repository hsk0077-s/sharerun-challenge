import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/strings/app_strings.dart';
import 'package:share_run_challenge/features/auth/new_social_account_notice.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('the notice is remembered only for the new account', () async {
    await NewSocialAccountNoticeStore.mark(
        uid: 'new-user', providerName: '카카오');
    expect(
        await NewSocialAccountNoticeStore.pendingProvider('new-user'), '카카오');
    expect(await NewSocialAccountNoticeStore.pendingProvider('other'), isNull);

    await NewSocialAccountNoticeStore.clear();
    expect(
        await NewSocialAccountNoticeStore.pendingProvider('new-user'), isNull);
  });

  test('the copy tells them to link from settings and does not merge email',
      () {
    final body = AppStrings.newSocialAccountBody('카카오');
    expect(body, contains('카카오'));
    expect(body, contains('설정 > 로그인 연결'));
    expect(body, contains('자동으로 합쳐지지 않아요'));
    expect(AppStrings.newSocialAccountCancel, '다른 방법으로 로그인');
    expect(AppStrings.newSocialAccountBody('네이버'), contains('네이버'));
  });

  testWidgets('continue stays and cancel is the sign-out choice',
      (tester) async {
    bool? choice;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  choice = await showNewSocialAccountNotice(
                    context,
                    providerName: '카카오',
                  );
                },
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('new-social-account-notice')), findsOneWidget);
    expect(find.text(AppStrings.newSocialAccountTitle), findsOneWidget);
    expect(find.textContaining('설정 > 로그인 연결에서 카카오를 연결'), findsOneWidget);

    await tester.tap(find.byKey(const Key('new-social-account-cancel')));
    await tester.pumpAndSettle();
    expect(choice, isFalse);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('new-social-account-continue')));
    await tester.pumpAndSettle();
    expect(choice, isTrue);
  });
}
