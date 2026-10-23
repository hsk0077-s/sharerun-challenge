import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/api/api_exception.dart';
import 'package:share_run_challenge/core/strings/app_strings.dart';
import 'package:share_run_challenge/data/api/identity_api_client.dart';
import 'package:share_run_challenge/features/auth/login_connection_providers.dart';
import 'package:share_run_challenge/screens/login_connections_screen.dart';

class _FakeIdentityApi implements IdentityApiClient {
  _FakeIdentityApi(this.providers);

  List<String> providers;
  ApiException? linkError;
  AccountLinkPreview preview = const AccountLinkPreview(
    nickname: '달림이',
    shareBalance: 1200,
    canLink: true,
  );
  final calls = <String>[];

  @override
  Future<List<String>> fetchProviders() async {
    calls.add('list');
    return List.of(providers);
  }

  @override
  Future<AccountLinkPreview> fetchLinkPreview() async {
    calls.add('preview');
    return preview;
  }

  @override
  Future<void> unlinkGoogle() async {
    calls.add('unlink-google');
    providers = providers.where((p) => p != 'google').toList();
  }

  @override
  Future<void> linkKakao(String accessToken) async {
    calls.add('link:$accessToken');
    final error = linkError;
    if (error != null) throw error;
    providers = [...providers, 'kakao'];
  }

  @override
  Future<void> unlinkKakao() async {
    calls.add('unlink');
    providers = providers.where((p) => p != 'kakao').toList();
  }

  @override
  Future<void> linkNaver(String accessToken) async {
    calls.add('link-naver:$accessToken');
    providers = [...providers, 'naver'];
  }

  @override
  Future<void> unlinkNaver() async {
    calls.add('unlink-naver');
    providers = providers.where((p) => p != 'naver').toList();
  }

  @override
  Future<KakaoLoginResult> kakaoLogin(
    String accessToken, {
    bool createAccount = false,
  }) =>
      throw UnimplementedError();

  @override
  Future<ProviderLoginResult> naverLogin(
    String accessToken, {
    bool createAccount = false,
  }) =>
      throw UnimplementedError();

  @override
  Future<ProviderLoginResult> googleLogin(
    String idToken, {
    bool createAccount = false,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> linkGoogle(String idToken) => throw UnimplementedError();

  @override
  Uri get baseUri => throw UnimplementedError();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(
  WidgetTester tester,
  _FakeIdentityApi api, {
  Future<String?> Function()? kakaoToken,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        identityApiClientProvider.overrideWithValue(api),
        kakaoAccessTokenProvider.overrideWithValue(
          kakaoToken ?? () async => 'kakao-token-12345',
        ),
        naverAccessTokenProvider.overrideWithValue(
          () async => 'naver-token-12345',
        ),
      ],
      child: const MaterialApp(home: LoginConnectionsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _inKakaoRow(String text) => find.descendant(
      of: find.byKey(LoginConnectionsScreen.kakaoRowKey),
      matching: find.text(text),
    );

void main() {
  testWidgets('shows what is connected and what is not', (tester) async {
    await _pump(tester, _FakeIdentityApi(['google']));
    expect(
      find.descendant(
        of: find.byKey(LoginConnectionsScreen.googleRowKey),
        matching: find.text('연결됨'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(LoginConnectionsScreen.kakaoRowKey),
        matching: find.text('연결 안 됨'),
      ),
      findsOneWidget,
    );
    expect(_inKakaoRow('연결하기'), findsOneWidget);
    expect(find.text('준비 중'), findsOneWidget); // 애플
  });

  testWidgets('connecting Kakao sends the token and refreshes', (tester) async {
    final api = _FakeIdentityApi(['google']);
    await _pump(tester, api);

    await tester.tap(find.byKey(LoginConnectionsScreen.kakaoActionKey));
    await tester.pumpAndSettle();
    expect(find.textContaining('달림이'), findsOneWidget);
    expect(find.textContaining('1,200'), findsOneWidget);

    await tester.tap(find.byKey(const Key('link-confirm-yes')));
    await tester.pumpAndSettle();

    expect(api.calls, ['list', 'preview', 'link:kakao-token-12345', 'list']);
    expect(_inKakaoRow('해제'), findsOneWidget);
    expect(find.text('카카오가 연결됐어요. 이제 어느 쪽으로 들어와도 같은 계정이에요.'), findsOneWidget);
  });

  testWidgets('closing the Kakao window changes nothing', (tester) async {
    final api = _FakeIdentityApi(['google']);
    await _pump(tester, api, kakaoToken: () async => null);

    await tester.tap(find.byKey(LoginConnectionsScreen.kakaoActionKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('link-confirm-yes')));
    await tester.pumpAndSettle();

    expect(api.calls, ['list', 'preview']);
    expect(_inKakaoRow('연결하기'), findsOneWidget);
  });

  testWidgets('a Kakao account owned by someone else is refused kindly',
      (tester) async {
    final api = _FakeIdentityApi(['google'])
      ..linkError = const ApiException(
        statusCode: 409,
        detail: 'identity_belongs_to_another_account',
      );
    await _pump(tester, api);

    await tester.tap(find.byKey(LoginConnectionsScreen.kakaoActionKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('link-confirm-yes')));
    await tester.pumpAndSettle();

    expect(find.text('이 계정은 이미 다른 쉐어런 계정에 연결돼 있어요.'), findsOneWidget);
    expect(_inKakaoRow('연결하기'), findsOneWidget);
  });

  testWidgets('disconnecting asks first and then unlinks', (tester) async {
    final api = _FakeIdentityApi(['google', 'kakao']);
    await _pump(tester, api);

    await tester.tap(find.byKey(LoginConnectionsScreen.kakaoActionKey));
    await tester.pumpAndSettle();
    expect(find.text('카카오 연결 해제'), findsOneWidget);
    expect(api.calls, ['list']); // 확인 전에는 아무것도 보내지 않는다

    await tester.tap(find.byKey(LoginConnectionsScreen.unlinkConfirmKey));
    await tester.pumpAndSettle();

    expect(api.calls, ['list', 'unlink', 'list']);
    expect(_inKakaoRow('연결하기'), findsOneWidget);
  });

  testWidgets('cancelling the disconnect dialog sends nothing', (tester) async {
    final api = _FakeIdentityApi(['google', 'kakao']);
    await _pump(tester, api);

    await tester.tap(find.byKey(LoginConnectionsScreen.kakaoActionKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(api.calls, ['list']);
    expect(_inKakaoRow('해제'), findsOneWidget);
  });

  testWidgets('Naver connects and disconnects like Kakao', (tester) async {
    final api = _FakeIdentityApi(['google', 'kakao']);
    await _pump(tester, api);
    expect(
      find.descendant(
        of: find.byKey(LoginConnectionsScreen.naverRowKey),
        matching: find.text('연결 안 됨'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(LoginConnectionsScreen.naverActionKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('link-confirm-yes')));
    await tester.pumpAndSettle();
    expect(api.calls, ['list', 'preview', 'link-naver:naver-token-12345', 'list']);
    expect(
      find.text('네이버가 연결됐어요. 이제 어느 쪽으로 들어와도 같은 계정이에요.'),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(LoginConnectionsScreen.naverRowKey),
        matching: find.text('연결됨'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(LoginConnectionsScreen.naverActionKey));
    await tester.pumpAndSettle();
    expect(find.text('네이버 연결 해제'), findsOneWidget);
    await tester.tap(find.byKey(LoginConnectionsScreen.unlinkConfirmKey));
    await tester.pumpAndSettle();
    expect(api.calls.last, 'list');
    expect(api.calls, contains('unlink-naver'));
    // 해제 뒤 네이버 줄이 다시 "연결 안 됨"이 된다.
    expect(
      find.descendant(
        of: find.byKey(LoginConnectionsScreen.naverRowKey),
        matching: find.text('연결 안 됨'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the last login method cannot be removed', (tester) async {
    final api = _FakeIdentityApi(['kakao']);
    await _pump(tester, api);

    final button = tester.widget<TextButton>(
      find.byKey(LoginConnectionsScreen.kakaoActionKey),
    );
    expect(button.onPressed, isNull);
    expect(api.calls, ['list']);
  });

  testWidgets('an empty account is not linked', (tester) async {
    final api = _FakeIdentityApi(['google'])
      ..preview = const AccountLinkPreview(
        nickname: '',
        shareBalance: 0,
        canLink: false,
      );
    await _pump(tester, api);

    await tester.tap(find.byKey(LoginConnectionsScreen.kakaoActionKey));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.existingAccountEmpty), findsOneWidget);
    expect(api.calls, ['list', 'preview']);
    expect(_inKakaoRow('연결하기'), findsOneWidget);
  });

  testWidgets('Google can be unlinked when another method remains', (tester) async {
    final api = _FakeIdentityApi(['google', 'kakao']);
    await _pump(tester, api);

    await tester.tap(find.byKey(LoginConnectionsScreen.googleActionKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(LoginConnectionsScreen.unlinkConfirmKey));
    await tester.pumpAndSettle();

    expect(api.calls, contains('unlink-google'));
    expect(
      find.descendant(
        of: find.byKey(LoginConnectionsScreen.googleRowKey),
        matching: find.text('연결 안 됨'),
      ),
      findsOneWidget,
    );
  });
}
