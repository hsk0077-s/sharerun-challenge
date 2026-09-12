import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/data/models/user_model.dart';
import 'package:share_run_challenge/data/models/wallet_model.dart';
import 'package:share_run_challenge/features/stamp/providers/stamp_tour_provider.dart';
import 'package:share_run_challenge/features/wallet/providers/wallet_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _wallet = WalletModel(
  shareBalance: 1000,
  diamondBalance: 5,
  valueTokenBalance: 0,
  totalDonationValue: 0,
);

class _SeededWalletNotifier extends WalletNotifier {
  @override
  WalletState build() => WalletState.fromModel(_wallet);

  @override
  void creditDia(int amount) {
    if (amount <= 0) return;
    state = state.copyWith(diamondBalance: state.diamondBalance + amount);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('stamp DIA claim credits the local wallet instead of a no-op', () async {
    final profile = UserModel.dashboardDefault(uid: 'stamp-user');
    final container = ProviderContainer(
      overrides: [
        activeUserProfileProvider.overrideWith(
          (ref) => Stream<UserModel>.value(profile),
        ),
        activeWalletProvider.overrideWith(
          (ref) => Stream<WalletModel>.value(_wallet),
        ),
        walletProvider.overrideWith(_SeededWalletNotifier.new),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(walletProvider).diamondBalance, 5);
    await container
        .read(stampTourProvider.notifier)
        .claimDiamondReward(diamondAmount: 1);
    expect(container.read(walletProvider).diamondBalance, 6);
  });
}
