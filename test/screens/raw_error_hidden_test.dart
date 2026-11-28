import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/api/api_exception.dart';
import 'package:share_run_challenge/core/ui/user_visible_failure.dart';
import 'package:share_run_challenge/core/widgets/async_value_section.dart';
import 'package:share_run_challenge/l10n/app_localizations.dart';

/// Failure copy from three surfaces: the home data section, the sponsorship
/// payment snackbar, and the sign-in snackbar.
void main() {
  Widget app({required Widget home}) {
    return MaterialApp(
      locale: const Locale('ko', 'KR'),
      supportedLocales: ShareRunLocalizations.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
    );
  }

  void expectNoRawError(WidgetTester tester) {
    expect(find.textContaining('Bad state'), findsNothing);
    expect(find.textContaining('Exception'), findsNothing);
    expect(find.textContaining('Internal Server Error'), findsNothing);
    expect(find.textContaining('Unexpected backend error'), findsNothing);
  }

  testWidgets('home data section hides the exception', (tester) async {
    await tester.pumpWidget(
      app(
        home: Scaffold(
          body: AsyncValueSection<int>(
            asyncValue: AsyncValue.error(
              Exception('Bad state: Internal Server Error'),
              StackTrace.empty,
            ),
            dataBuilder: (_, __) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('데이터를 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.'), findsOneWidget);
    expectNoRawError(tester);
  });

  testWidgets('sponsorship payment snackbar hides the server text', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        userVisibleFailure(
                          context,
                          Exception('Bad state: Internal Server Error'),
                          key: 'sponsor_payment.toast.2',
                          ko: '후원 결제에 실패했어요. 잠시 후 다시 시도해 주세요.',
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('pay'),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('pay'));
    await tester.pump();

    expect(find.text('후원 결제에 실패했어요. 잠시 후 다시 시도해 주세요.'), findsOneWidget);
    expectNoRawError(tester);
  });

  testWidgets('sign-in snackbar hides an English server detail', (
    tester,
  ) async {
    const error = ApiException(
      statusCode: 500,
      detail: 'Unexpected backend error.',
    );
    await tester.pumpWidget(
      app(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        userVisibleFailure(
                          context,
                          error,
                          key: 'login.body.2',
                          ko: '로그인에 실패했어요. 잠시 후 다시 시도해 주세요.',
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('sign in'),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('sign in'));
    await tester.pump();

    expect(find.textContaining('잠시 후 다시 시도해 주세요.'), findsOneWidget);
    expectNoRawError(tester);
  });
}
