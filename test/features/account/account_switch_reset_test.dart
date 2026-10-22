import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/data/models/wallet_model.dart';
import 'package:share_run_challenge/features/onboarding/src_onboarding_controller.dart';
import 'package:share_run_challenge/features/wallet/providers/wallet_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeUser extends Fake implements User {
  _FakeUser(this.uid);

  @override
  final String uid;
}

Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StreamController<User?> auth;
  late StreamController<WalletModel> wallet;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'username': 'old-name',
    });
    auth = StreamController<User?>();
    wallet = StreamController<WalletModel>();
    container = ProviderContainer(
      overrides: [
        authStateChangesProvider.overrideWith((ref) => auth.stream),
        activeWalletProvider.overrideWith((ref) => wallet.stream),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await auth.close();
    await wallet.close();
  });

  test('a new account does not inherit the previous wallet', () async {
    container.listen(walletProvider, (_, __) {});
    auth.add(_FakeUser('uid-old'));
    wallet.add(
      const WalletModel(
        shareBalance: 922626,
        diamondBalance: 999635,
        valueTokenBalance: 999850,
        totalDonationValue: 0,
      ),
    );
    await _settle();
    expect(container.read(walletProvider).diamondBalance, 999635);

    // Log out, then sign in as a different account whose wallet is empty.
    auth.add(null);
    await _settle();
    auth.add(_FakeUser('uid-new'));
    wallet.add(
      const WalletModel(
        shareBalance: 0,
        diamondBalance: 0,
        valueTokenBalance: 0,
        totalDonationValue: 0,
      ),
    );
    await _settle();

    final state = container.read(walletProvider);
    expect(state.shareBalance, 0);
    expect(state.diamondBalance, 0);
    expect(state.valueBalance, 0);
  });

  test('the saved nickname is cleared when the account changes', () async {
    container.listen(persistedUsernameProvider, (_, __) {});
    auth.add(_FakeUser('uid-old'));
    await _settle();
    expect(container.read(persistedUsernameProvider).value, 'old-name');

    auth.add(null);
    await _settle();

    expect(container.read(persistedUsernameProvider).value, isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('username'), isNull);
  });

  test('the first sign-in keeps the saved nickname', () async {
    container.listen(persistedUsernameProvider, (_, __) {});
    await _settle();
    auth.add(_FakeUser('uid-old'));
    await _settle();

    expect(container.read(persistedUsernameProvider).value, 'old-name');
  });
}
