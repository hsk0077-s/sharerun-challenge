import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/features/pedometer/walking_challenge_share.dart';
import 'package:share_run_challenge/features/profile/widgets/my_page_invite_code_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var clipboardText = '';

  setUp(() {
    clipboardText = '';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      switch (call.method) {
        case 'Clipboard.setData':
          final args = Map<String, dynamic>.from(call.arguments as Map);
          clipboardText = args['text'] as String? ?? '';
          return null;
        case 'Clipboard.getData':
          return <String, dynamic>{'text': clipboardText};
        default:
          return null;
      }
    });
    WalkingChallengeShare.debugShareOverride = (params) async {
      return const ShareResult('', ShareResultStatus.success);
    };
    WalkingChallengeShare.debugKakaoInstalledOverride = () async => false;
    WalkingChallengeShare.debugKakaoShareOverride = null;
  });

  tearDown(() {
    WalkingChallengeShare.debugShareOverride = null;
    WalkingChallengeShare.debugKakaoInstalledOverride = null;
    WalkingChallengeShare.debugKakaoShareOverride = null;
  });

  Future<void> pumpCard(
    WidgetTester tester, {
    required Future<String> Function() load,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myPageInviteCodeLoaderProvider.overrideWith((ref) => load),
        ],
        child: MaterialApp(
          theme: SrcTheme.light,
          home: const Scaffold(
            body: MyPageInviteCodeCard(),
          ),
        ),
      ),
    );
  }

  testWidgets('shows a loading state and no placeholder code', (tester) async {
    final pending = Completer<String>();
    await pumpCard(tester, load: () => pending.future);
    await tester.pump();

    expect(find.text(MyPageInviteCodeCard.title), findsOneWidget);
    expect(find.byKey(MyPageInviteCodeCard.loadingKey), findsOneWidget);
    expect(find.byKey(MyPageInviteCodeCard.codeKey), findsNothing);
    expect(find.text('SRC8A2F91'), findsNothing);
    expect(find.textContaining('보상'), findsNothing);
    expect(find.textContaining('SRV'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(find.byKey(MyPageInviteCodeCard.kakaoKey))
          .onPressed,
      isNull,
    );
  });

  testWidgets('shows the server code and copies it', (tester) async {
    await pumpCard(tester, load: () async => 'AB23CD45');
    await tester.pump();

    expect(find.text('AB23CD45'), findsOneWidget);
    expect(find.byKey(MyPageInviteCodeCard.loadingKey), findsNothing);
    expect(find.byKey(MyPageInviteCodeCard.retryKey), findsNothing);

    await tester.tap(find.byKey(MyPageInviteCodeCard.copyKey));
    await tester.pump();
    await tester.pump();

    expect(find.text(MyPageInviteCodeCard.copiedMessage), findsOneWidget);
    final copied = await Clipboard.getData(Clipboard.kTextPlain);
    expect(copied?.text, 'AB23CD45');
  });

  testWidgets('failure shows a retry message and never a fake code',
      (tester) async {
    var calls = 0;
    await pumpCard(tester, load: () async {
      calls += 1;
      if (calls == 1) throw StateError('down');
      return 'K7MNPQ23';
    });
    await tester.pump();

    expect(find.text(MyPageInviteCodeCard.loadFailedMessage), findsOneWidget);
    expect(find.byKey(MyPageInviteCodeCard.codeKey), findsNothing);
    expect(find.text('SRC8A2F91'), findsNothing);

    await tester.tap(find.byKey(MyPageInviteCodeCard.retryKey));
    await tester.pump();

    expect(find.text('K7MNPQ23'), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('blank code is treated as a failure', (tester) async {
    await pumpCard(tester, load: () async => '   ');
    await tester.pump();

    expect(find.text(MyPageInviteCodeCard.loadFailedMessage), findsOneWidget);
    expect(find.byKey(MyPageInviteCodeCard.codeKey), findsNothing);
  });

  testWidgets('Kakao invite falls back to the system sheet when not installed',
      (tester) async {
    ShareParams? sent;
    WalkingChallengeShare.debugKakaoInstalledOverride = () async => false;
    WalkingChallengeShare.debugShareOverride = (params) async {
      sent = params;
      return const ShareResult('', ShareResultStatus.success);
    };

    await pumpCard(tester, load: () async => 'AB23CD45');
    await tester.pump();
    await tester.tap(find.byKey(MyPageInviteCodeCard.kakaoKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final text = myPageInviteShareText('AB23CD45');
    expect(sent, isNotNull);
    expect(sent!.text, text);
    expect(sent!.subject, MyPageInviteCodeCard.shareSubject);
    expect(sent!.title, MyPageInviteCodeCard.shareSubject);
    expect(text, contains('AB23CD45'));
    expect(text, contains(myPageInvitePlayStoreUrl));
    expect(text, contains('com.sharerun.share_run_challenge'));
    expect(
        text.length, lessThanOrEqualTo(WalkingChallengeShare.kakaoTextLimit));
    expect(text, isNot(contains('SRV')));
    expect(text, isNot(contains('보상')));
    expect(text, isNot(contains('300')));
  });

  testWidgets('Kakao invite uses the existing Kakao share path when installed',
      (tester) async {
    ShareParams? sent;
    String? kakaoText;
    WalkingChallengeShare.debugKakaoInstalledOverride = () async => true;
    WalkingChallengeShare.debugKakaoShareOverride = (text) async {
      kakaoText = text;
    };
    WalkingChallengeShare.debugShareOverride = (params) async {
      sent = params;
      return const ShareResult('', ShareResultStatus.success);
    };

    await pumpCard(tester, load: () async => 'AB23CD45');
    await tester.pump();
    await tester.tap(find.byKey(MyPageInviteCodeCard.kakaoKey));
    await tester.pumpAndSettle();

    expect(find.byKey(WalkingChallengeShare.kakaoChoiceKey), findsOneWidget);
    await tester.tap(find.byKey(WalkingChallengeShare.kakaoChoiceKey));
    await tester.pumpAndSettle();

    expect(kakaoText, myPageInviteShareText('AB23CD45'));
    expect(sent, isNull);
  });
}
