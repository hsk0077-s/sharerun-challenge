import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/strings/app_strings.dart';
import 'package:share_run_challenge/features/auth/existing_account_question.dart';

void main() {
  test('the question names the current method and offers a fresh start', () {
    final body = AppStrings.existingAccountBody('카카오');
    expect(AppStrings.existingAccountTitle, '처음 가입할 때 어떤 방법을 쓰셨나요?');
    expect(body, contains('카카오'));
    expect(body, contains('연결돼요'));
    expect(body, contains('닉네임과 재화도 그대로예요'));
    expect(AppStrings.existingAccountBody('구글'), contains('구글이'));
    expect(AppStrings.existingAccountBody('네이버'), contains('네이버가'));
    expect(AppStrings.existingAccountCreate, '새로 시작하기');
    expect(AppStrings.existingAccountEmpty, '그 방법으로 가입된 계정이 없어요. 다른 방법을 골라 주세요.');
    expect(
      AppStrings.linkAttached('카카오'),
      '카카오가 연결됐어요. 이제 어느 쪽으로 들어와도 같은 계정이에요.',
    );
    expect(AppStrings.linkConfirmTitle('구글'), '이 계정에 구글을 연결할까요?');
  });

  testWidgets('kakao login offers the other methods and a small fresh start',
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
    expect(find.text(AppStrings.existingAccountCreateHint), findsOneWidget);
    expect(find.text(AppStrings.existingAccountKakao), findsNothing);
    expect(find.text(AppStrings.existingAccountGoogle), findsOneWidget);
    expect(find.text(AppStrings.existingAccountNaver), findsOneWidget);

    await tester.tap(find.byKey(const Key('existing-account-create')));
    await tester.pumpAndSettle();
    expect(choice, ExistingAccountAnswer.create);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('existing-account-google')));
    await tester.pumpAndSettle();
    expect(choice, ExistingAccountAnswer.google);
  });

  testWidgets('confirm shows nickname and SHARE before linking', (tester) async {
    bool? choice;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  choice = await showAccountLinkConfirm(
                    context,
                    methodName: '네이버',
                    nickname: '달림이',
                    shareBalance: 1200,
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

    expect(find.byKey(const Key('link-confirm-dialog')), findsOneWidget);
    expect(find.text('이 계정에 네이버를 연결할까요?'), findsOneWidget);
    expect(find.textContaining('달림이'), findsOneWidget);
    expect(find.textContaining('SHARE 1,200'), findsOneWidget);
    expect(find.text(AppStrings.linkConfirmYes), findsOneWidget);
    expect(find.text(AppStrings.linkConfirmNo), findsOneWidget);

    await tester.tap(find.byKey(const Key('link-confirm-no')));
    await tester.pumpAndSettle();
    expect(choice, isFalse);
  });
}
