import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/data/models/user_model.dart';
import 'package:share_run_challenge/data/models/wallet_model.dart';
import 'package:share_run_challenge/features/stamp/providers/stamp_tour_provider.dart';
import 'package:share_run_challenge/features/stamp/stamp_landmark_catalog.dart';
import 'package:share_run_challenge/features/stamp/stamp_tour_progress_store.dart';
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

ProviderContainer _container() {
  final profile = UserModel.dashboardDefault(uid: 'stamp-user');
  return ProviderContainer(
    overrides: [
      activeUserProfileProvider.overrideWith(
        (ref) => Stream<UserModel>.value(profile),
      ),
      activeWalletProvider.overrideWith(
        (ref) => Stream<WalletModel>.value(_wallet),
      ),
      walletProvider.overrideWith(_SeededWalletNotifier.new),
      stampLandmarkCatalogProvider.overrideWith(
        (ref) => const StampLandmarkCatalog(
          remote: MemoryOfficialLandmarkSource([]),
        ),
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('official DIA stays pending and does not fake-mint the wallet', () async {
    final container = _container();
    addTearDown(container.dispose);

    expect(container.read(walletProvider).diamondBalance, 5);
    await container
        .read(stampTourProvider.notifier)
        .enqueueOfficialDiaPending(rewardId: 'gangbyeon');

    expect(container.read(walletProvider).diamondBalance, 5);
    expect(
      container.read(stampTourProvider).pendingOfficialRewardIds,
      contains('gangbyeon'),
    );

    final stored = await const StampTourProgressStore().read();
    expect(stored.rewardedLandmarkIds, contains('gangbyeon'));
  });

  test('walk official DIA pending does not credit DIA', () async {
    final container = _container();
    addTearDown(container.dispose);

    await container
        .read(stampTourProvider.notifier)
        .enqueueOfficialDiaPending(rewardId: StampTourNotifier.walkRewardId);

    expect(container.read(walletProvider).diamondBalance, 5);
    expect(container.read(stampTourProvider).walkOfficialDiaPending, isTrue);
    expect(
      container.read(stampTourProvider).pendingOfficialRewardIds,
      isEmpty,
    );
  });
}
