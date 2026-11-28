import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/app/router/route_names.dart';
import 'package:share_run_challenge/core/auth/local_auth_store.dart';
import 'package:share_run_challenge/core/config/app_env.dart';
import 'package:share_run_challenge/core/widgets/apple_login_button.dart';
import 'package:share_run_challenge/data/api/identity_api_client.dart';
import 'package:share_run_challenge/data/firebase/apple_id_token_fetcher.dart';
import 'package:share_run_challenge/data/firebase/apple_sign_in_handoff.dart';
import 'package:share_run_challenge/data/models/user_model.dart';
import 'package:share_run_challenge/data/repositories/auth_repository.dart';
import 'package:share_run_challenge/features/auth/apple_account_deletion.dart';
import 'package:share_run_challenge/features/auth/login_connection_providers.dart';
import 'package:share_run_challenge/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../support/ko_localization.dart';

AuthorizationCredentialAppleID _credential({
  String? token = 'apple-identity-token',
  String? givenName,
  String? familyName,
  String? email,
  String code = 'one-time-code',
}) =>
    AuthorizationCredentialAppleID(
      userIdentifier: 'apple-user',
      givenName: givenName,
      familyName: familyName,
      authorizationCode: code,
      email: email,
      identityToken: token,
      state: null,
    );

class _User extends Fake implements User {
  @override
  String get uid => 'firebase-uid-1';
}

class _Credential extends Fake implements UserCredential {
  @override
  User? get user => _User();
}

class _AuthRepository extends Fake implements AuthRepository {
  final customTokens = <String>[];

  @override
  Future<UserCredential> signInWithCustomToken(String token) async {
    customTokens.add(token);
    return _Credential();
  }
}

class _FirebaseAuth extends Fake implements FirebaseAuth {
  @override
  User? get currentUser => null;
}

class _LocalAuthStore extends Fake implements LocalAuthStore {
  final saved = <String>[];

  @override
  Future<void> saveSession({required String uid, required bool isGuest}) async {
    saved.add(uid);
  }
}

void main() {
  setUp(() {
    AppleSignInHandoff.debugReset();
    SharedPreferences.setMockInitialValues({});
  });

  group('when the Apple button is offered', () {
    test('always on iPhone and Mac, even when the switch is off', () {
      for (final platform in [TargetPlatform.iOS, TargetPlatform.macOS]) {
        expect(
          AppEnv.resolveAppleLoginEnabled(platform: platform, configured: false),
          isTrue,
          reason: '$platform',
        );
      }
    });

    test('Android keeps the old switch (off unless turned on)', () {
      expect(
        AppEnv.resolveAppleLoginEnabled(
            platform: TargetPlatform.android, configured: false),
        isFalse,
      );
      expect(
        AppEnv.resolveAppleLoginEnabled(
            platform: TargetPlatform.android, configured: true),
        isTrue,
      );
    });
  });

  group('AppleIdTokenFetcher', () {
    test('sends Apple only the SHA-256 of a fresh nonce and keeps the raw one',
        () async {
      String? sentNonce;
      List<AppleIDAuthorizationScopes>? sentScopes;
      final fetcher = AppleIdTokenFetcher(
        newRawNonce: () => 'raw-nonce-1',
        request: ({required scopes, nonce}) async {
          sentScopes = scopes;
          sentNonce = nonce;
          return _credential();
        },
      );

      final token = await fetcher.idToken();

      expect(token, 'apple-identity-token');
      expect(sentNonce, AppleSignInHandoff.sha256Of('raw-nonce-1'));
      expect(sentNonce, isNot('raw-nonce-1'));
      expect(sentScopes, contains(AppleIDAuthorizationScopes.email));
      expect(sentScopes, contains(AppleIDAuthorizationScopes.fullName));
      expect(AppleSignInHandoff.nonceFor('apple-identity-token'), 'raw-nonce-1');
    });

    test('a first sign-in name becomes a one-time nickname suggestion',
        () async {
      final fetcher = AppleIdTokenFetcher(
        newRawNonce: () => 'n',
        request: ({required scopes, nonce}) async =>
            _credential(givenName: '길 동', familyName: '홍'),
      );
      await fetcher.idToken();
      expect(AppleSignInHandoff.takeSuggestedNickname(), '길동');
      expect(AppleSignInHandoff.takeSuggestedNickname(), isNull);
    });

    test('later sign-ins without name or e-mail still give a token', () async {
      final fetcher = AppleIdTokenFetcher(
        newRawNonce: () => 'n2',
        request: ({required scopes, nonce}) async => _credential(),
      );
      expect(await fetcher.idToken(), 'apple-identity-token');
      expect(AppleSignInHandoff.takeSuggestedNickname(), isNull);
      expect(AppleSignInHandoff.nonceFor('apple-identity-token'), 'n2');
    });

    test('closing the Apple sheet is not an error', () async {
      final fetcher = AppleIdTokenFetcher(
        request: ({required scopes, nonce}) async =>
            throw const SignInWithAppleAuthorizationException(
          code: AuthorizationErrorCode.canceled,
          message: 'closed',
        ),
      );
      expect(await fetcher.idToken(), isNull);
      expect(await fetcher.authorizationCode(), isNull);
    });

    test('an answer without a token is reported', () async {
      final fetcher = AppleIdTokenFetcher(
        request: ({required scopes, nonce}) async => _credential(token: null),
      );
      expect(fetcher.idToken(), throwsA(isA<AppleTokenMissing>()));
    });

    test('nickname suggestion is trimmed to 12 characters', () {
      expect(AppleSignInHandoff.nicknameFrom(null, null), isNull);
      expect(AppleSignInHandoff.nicknameFrom('  ', '김'), '김');
      expect(AppleSignInHandoff.nicknameFrom('Alexandrina Victoria', null),
          'AlexandrinaV');
    });
  });

  group('IdentityApiClient', () {
    test('Apple login and link carry the raw nonce of that token', () async {
      final bodies = <String, Map<String, dynamic>>{};
      final api = IdentityApiClient(
        baseUri: Uri.parse('https://example.test'),
        idToken: () async => 'firebase-id',
        httpClient: MockClient((request) async {
          bodies[request.url.path] =
              jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(jsonEncode({'custom_token': 'ct'}), 200);
        }),
      );
      AppleSignInHandoff.remember(
        'tok-ios',
        const AppleSignInDetails(rawNonce: 'raw-9'),
      );

      await api.appleLogin('tok-ios', createAccount: true);
      await api.linkApple('tok-ios');
      await api.appleLogin('tok-android');

      expect(bodies['/auth/apple/link'],
          {'id_token': 'tok-ios', 'nonce': 'raw-9'});
      // The last login (an Android-style token) carries no nonce.
      expect(bodies['/auth/apple/login'], {'id_token': 'tok-android'});
    });
  });

  group('login screen', () {
    Future<
        ({
          _AuthRepository auth,
          List<Map<String, dynamic>> sent,
          _LocalAuthStore store,
          List<int> askedApple,
        })> pump(WidgetTester tester) async {
      final auth = _AuthRepository();
      final store = _LocalAuthStore();
      final sent = <Map<String, dynamic>>[];
      final askedApple = <int>[];
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appleIdTokenProvider.overrideWithValue(() async {
              askedApple.add(1);
              AppleSignInHandoff.remember(
                'apple-identity-token',
                const AppleSignInDetails(rawNonce: 'raw-login'),
              );
              return 'apple-identity-token';
            }),
            identityApiClientProvider.overrideWithValue(
              IdentityApiClient(
                baseUri: Uri.parse('https://example.test'),
                idToken: () async => null,
                httpClient: MockClient((request) async {
                  sent.add({
                    'path': request.url.path,
                    ...jsonDecode(request.body) as Map<String, dynamic>,
                  });
                  return http.Response(
                    jsonEncode({'custom_token': 'server-custom-token'}),
                    200,
                  );
                }),
              ),
            ),
            authRepositoryProvider.overrideWithValue(auth),
            firebaseAuthProvider.overrideWithValue(_FirebaseAuth()),
            localAuthStoreProvider.overrideWithValue(store),
            activeUserProfileProvider
                .overrideWith((ref) => const Stream<UserModel>.empty()),
          ],
          child: MaterialApp(
            locale: koTestLocale,
            supportedLocales: koTestSupportedLocales,
            localizationsDelegates: koTestDelegates,
            routes: {
              RouteNames.termsAgreement: (_) => const Text('terms-page'),
              RouteNames.home: (_) => const Text('home-page'),
            },
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pump();
      return (auth: auth, sent: sent, store: store, askedApple: askedApple);
    }

    testWidgets(
        'on iPhone, Apple credential goes to the server and its token signs '
        'in to Firebase', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        final s = await pump(tester);
        final button = find.byKey(AppleLoginButton.buttonKey);
        expect(button, findsOneWidget);
        expect(find.byKey(AppleLoginButton.logoKey), findsOneWidget);

        await tester.tap(button);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(s.askedApple, [1]);
        expect(s.sent, [
          {
            'path': '/auth/apple/login',
            'id_token': 'apple-identity-token',
            'nonce': 'raw-login',
          }
        ]);
        expect(s.auth.customTokens, ['server-custom-token']);
        expect(s.store.saved, ['firebase-uid-1']);
        await tester.pumpAndSettle();
        expect(find.text('terms-page'), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('on Android with the switch off it still says coming soon',
        (tester) async {
      final s = await pump(tester);
      await tester.tap(find.byKey(AppleLoginButton.buttonKey));
      await tester.pump();
      expect(s.askedApple, isEmpty);
      expect(s.sent, isEmpty);
      expect(s.auth.customTokens, isEmpty);
    });
  });

  group('account deletion', () {
    test('on iPhone with Apple linked it asks Apple for a fresh code', () async {
      var told = 0;
      final code = await appleCodeForAccountDeletion(
        platform: TargetPlatform.iOS,
        fetchProviders: () async => ['google', 'apple'],
        askAppleCode: () async => 'fresh-code',
        beforeAsking: () => told++,
      );
      expect(code, 'fresh-code');
      expect(told, 1);
    });

    test('no Apple link, Android, a closed sheet or an error give no code',
        () async {
      var asked = 0;
      Future<String?> ask() async {
        asked++;
        return 'x';
      }

      expect(
        await appleCodeForAccountDeletion(
          platform: TargetPlatform.iOS,
          fetchProviders: () async => ['kakao'],
          askAppleCode: ask,
        ),
        isNull,
      );
      expect(
        await appleCodeForAccountDeletion(
          platform: TargetPlatform.android,
          fetchProviders: () async => ['apple'],
          askAppleCode: ask,
        ),
        isNull,
      );
      expect(asked, 0);
      expect(
        await appleCodeForAccountDeletion(
          platform: TargetPlatform.iOS,
          fetchProviders: () async => ['apple'],
          askAppleCode: () async => null,
        ),
        isNull,
      );
      expect(
        await appleCodeForAccountDeletion(
          platform: TargetPlatform.iOS,
          fetchProviders: () async => throw StateError('offline'),
          askAppleCode: ask,
        ),
        isNull,
      );
    });
  });
}
