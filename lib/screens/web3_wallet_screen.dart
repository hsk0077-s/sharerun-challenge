import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers/app_providers.dart';
import '../core/navigation/app_route_nav.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shapes.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/src_gradient_background.dart';
import '../features/wallet/providers/wallet_provider.dart';

/// 외부 지갑 전송 안내 (Screen 22).
///
/// VALUE는 앱 내 Off-chain 마일리지로만 관리한다.
/// MetaMask 전송은 출시 빌드에서 준비 중이며 VALUE를 차감하지 않는다.
class Web3WalletScreen extends ConsumerStatefulWidget {
  const Web3WalletScreen({super.key});

  static const _saveNavy = Color(0xFF1A2B4A);

  @override
  ConsumerState<Web3WalletScreen> createState() => _Web3WalletScreenState();
}

class _Web3WalletScreenState extends ConsumerState<Web3WalletScreen> {
  var _transferring = false;

  String _format(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  Future<void> _onTransfer() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.web3WalletTransferCta)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);
    final remote = ref.watch(activeWalletProvider).asData?.value;
    final valueBalance = remote?.valueTokenBalance ?? wallet.valueBalance;

    return Scaffold(
      backgroundColor: AppColors.bgGradientEnd,
      body: SRCGradientBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppShapes.termsHorizontalPadding,
                    8,
                    AppShapes.termsHorizontalPadding,
                    16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Web3WalletHeader(
                        onBack: () => AppRouteNav.pop(context),
                      ),
                      const SizedBox(height: 20),
                      _TokenTransferCard(
                        valueBalanceLabel:
                            '보유 밸류(VALUE): ${_format(valueBalance)}',
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppShapes.termsHorizontalPadding,
                    4,
                    AppShapes.termsHorizontalPadding,
                    12,
                  ),
                  child: Center(
                    child: SizedBox(
                      width: MediaQuery.sizeOf(context).width * 0.9,
                      height: AppShapes.buttonHeight,
                      child: Material(
                        color: Web3WalletScreen._saveNavy,
                        borderRadius: BorderRadius.circular(
                          AppShapes.cardRadius,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: _transferring ? null : _onTransfer,
                          child: Center(
                            child: _transferring
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: AppColors.textWhite,
                                    ),
                                  )
                                : Text(
                                    AppStrings.web3WalletTransferCta,
                                    style: AppTextStyles.buttonText.copyWith(
                                      color: AppColors.textWhite,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Web3WalletHeader extends StatelessWidget {
  const _Web3WalletHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: AppColors.textBlack,
              iconSize: 22,
              onPressed: onBack,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              AppStrings.web3WalletTitle,
              style: AppTextStyles.header1.copyWith(fontSize: 17),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _Web3WhiteCard extends StatelessWidget {
  const _Web3WhiteCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.textBlack.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _TokenTransferCard extends StatelessWidget {
  const _TokenTransferCard({required this.valueBalanceLabel});

  final String valueBalanceLabel;

  @override
  Widget build(BuildContext context) {
    return _Web3WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            valueBalanceLabel,
            style: AppTextStyles.agreementLabel.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.web3WalletPendingNote,
            style: AppTextStyles.caption.copyWith(
              fontSize: 13,
              height: 1.45,
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }
}
