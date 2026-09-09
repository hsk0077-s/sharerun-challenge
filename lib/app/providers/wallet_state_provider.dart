import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/wallet_model.dart';

final walletProvider = NotifierProvider<WalletController, WalletModel>(
  WalletController.new,
);

class WalletController extends Notifier<WalletModel> {
  @override
  WalletModel build() => WalletModel.empty();

  void replace(WalletModel wallet) {
    state = wallet;
  }

  void creditShare(int amount) {
    state = state.copyWith(shareBalance: state.shareBalance + amount);
  }

  void debitShare(int amount) {
    state = state.copyWith(shareBalance: state.shareBalance - amount);
  }

  void creditValueToken(int amount) {
    state = state.copyWith(valueTokenBalance: state.valueTokenBalance + amount);
  }

  void donateValueToken(int amount) {
    state = state.copyWith(
      valueTokenBalance: state.valueTokenBalance - amount,
      totalDonationValue: state.totalDonationValue + amount,
    );
  }
}
