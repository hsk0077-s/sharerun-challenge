import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/api/api_exception.dart';
import 'package:share_run_challenge/data/api/identity_api_client.dart';
import 'package:share_run_challenge/features/auth/login_connection_providers.dart';
import 'package:share_run_challenge/screens/login_connections_screen.dart';

class _FakeIdentityApi implements IdentityApiClient {
  _FakeIdentityApi(this.providers);

  List<String> providers;
  ApiException? linkError;
  final calls = <String>[];

  @override
  Future<List<String>> fetchProviders() async {
    calls.add('list');
    return List.of(providers);
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
  Future<KakaoLoginResult> kakaoLogin(String accessToken) =>
      throw UnimplementedError();

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
      ],
      child: const MaterialApp(home: LoginConnectionsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

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
    expect(find.text('연결하기'), findsOneWidget);
    expect(find.text('준비 중'), findsNWidgets(2)); // 네이버, 애플
  });

  testWidgets('connecting Kakao sends the token and refreshes', (tester) async {
    final api = _FakeIdentityApi(['google']);
    await _pump(tester, api);

    await tester.tap(find.byKey(LoginConnectionsScreen.kakaoActionKey));
    await tester.pumpAndSettle();

    expect(api.calls, ['list', 'link:kakao-token-12345', 'list']);
    expect(find.text('해제'), findsOneWidget);
    expect(find.text('카카오 계정을 연결했어요.'), findsOneWidget);
  });

  testWidgets('closing the Kakao window changes nothing', (tester) async {
    final api = _FakeIdentityApi(['google']);
    await _pump(tester, api, kakaoToken: () async => null);

    await tester.tap(find.byKey(LoginConnectionsScreen.kakaoActionKey));
    await tester.pumpAndSettle();

    expect(api.calls, ['list']);
    expect(find.text('연결하기'), findsOneWidget);
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

    expect(find.text('이 계정은 이미 다른 쉐어런 계정에 연결돼 있어요.'), findsOneWidget);
    expect(find.text('연결하기'), findsOneWidget);
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
    expect(find.text('연결하기'), findsOneWidget);
  });

  testWidgets('cancelling the disconnect dialog sends nothing', (tester) async {
    final api = _FakeIdentityApi(['google', 'kakao']);
    await _pump(tester, api);

    await tester.tap(find.byKey(LoginConnectionsScreen.kakaoActionKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(api.calls, ['list']);
    expect(find.text('해제'), findsOneWidget);
  });
}
