import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/strings/app_strings.dart';
import 'package:share_run_challenge/features/auth/existing_account_question.dart';

void main() {
  test('the question explains a verified email already joins the account', () {
    final body = AppStrings.existingAccountBody('카카오');
    expect(AppStrings.existingAccountTitle, '예전에 다른 방법으로 가입하셨나요?');
    expect(body, contains('카카오'));
    expect(body, contains('새 계정을 만들지 않았어요'));
    expect(body, contains('자동으로 이어져요'));
    expect(body, isNot(contains('합쳐지지 않아요')));
    expect(AppStrings.existingAccountBody('네이버'), contains('네이버'));
    expect(AppStrings.existingAccountCreate, '새 계정 만들기');
  });

  testWidgets('kakao login offers the other methods, create, or cancel',
      (tester) async {
    ExistingAccountAnswer? choice;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  choice = await showExistingAccountQuestion(
                    context,
                    provider: 'kakao',
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

    expect(find.byKey(const Key('existing-account-question')), findsOneWidget);
    expect(find.text(AppStrings.existingAccountTitle), findsOneWidget);
    expect(find.text(AppStrings.existingAccountKakao), findsNothing);
    expect(find.text(AppStrings.existingAccountGoogle), findsOneWidget);
    expect(find.text(AppStrings.existingAccountNaver), findsOneWidget);

    await tester.tap(find.byKey(const Key('existing-account-cancel')));
    await tester.pumpAndSettle();
    expect(choice, ExistingAccountAnswer.cancel);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('existing-account-create')));
    await tester.pumpAndSettle();
    expect(choice, ExistingAccountAnswer.create);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('existing-account-google')));
    await tester.pumpAndSettle();
    expect(choice, ExistingAccountAnswer.google);
  });
}
