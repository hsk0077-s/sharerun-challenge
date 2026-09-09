import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers/app_providers.dart';
import '../core/api/api_exception.dart';
import '../core/config/app_env.dart';
import '../core/navigation/app_route_nav.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shapes.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/src_gradient_background.dart';
import '../features/wallet/providers/wallet_provider.dart';

/// Web3 지갑 연결 및 토큰 전송 화면 (Screen 22).
///
/// VALUE는 앱 내 Off-chain 마일리지로만 관리하며 원화 환전 API는 제공하지 않는다.
/// 전송하기는 외부 MetaMask 주소로 Transfer만 수행한다.
class Web3WalletScreen extends ConsumerStatefulWidget {
  const Web3WalletScreen({super.key});

  static const _saveNavy = Color(0xFF1A2B4A);
  static const _warningBrown = Color(0xFF8D4B1F);
  static const _externalAddress = '0x1A2b3C4d5E6f7081920aBcDeF1234567890a3C4d';
  static const _gasFeeValue = 10;

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

  void _onCopy(BuildContext context) {
    Clipboard.setData(
      const ClipboardData(text: Web3WalletScreen._externalAddress),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('주소가 복사되었습니다.')),
    );
  }

  Future<void> _onTransfer() async {
    if (_transferring) return;

    final wallet = ref.read(walletProvider);
    final remote = ref.read(activeWalletProvider).asData?.value;
    final balance = remote?.valueTokenBalance ?? wallet.valueBalance;
    final transferAmount = (balance - Web3WalletScreen._gasFeeValue)
        .clamp(0, 1 << 31)
        .toInt();

    if (transferAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('전송 가능한 VALUE가 부족합니다. (가스비 10 VALUE 필요)'),
        ),
      );
      return;
    }

    setState(() => _transferring = true);
    try {
      if (AppEnv.useLocalMockData) {
        ref.read(walletProvider.notifier).debitValue(
              transferAmount + Web3WalletScreen._gasFeeValue,
            );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '[Mock] ${_format(transferAmount)} VALUE 외부 전송 완료 '
              '(가스비 ${Web3WalletScreen._gasFeeValue} VALUE). '
              '앱 내 원화 환전은 제공하지 않습니다.',
            ),
          ),
        );
        return;
      }

      await ref.read(walletRepositoryProvider).transferValueToWeb3(
            destinationAddress: Web3WalletScreen._externalAddress,
            amountSrv: transferAmount,
            transferChannel: 'external_wallet',
          );
      ref.read(walletProvider.notifier).debitValue(
            transferAmount + Web3WalletScreen._gasFeeValue,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_format(transferAmount)} VALUE가 외부 지갑으로 전송 요청되었습니다. '
            '앱 내 현금 환전은 제공하지 않습니다.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Web3 전송 실패: ${ApiErrorMessage.from(error)}')),
      );
    } finally {
      if (mounted) setState(() => _transferring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);
    final remote = ref.watch(activeWalletProvider).asData?.value;
    final valueBalance = remote?.valueTokenBalance ?? wallet.valueBalance;
    final netTransfer =
        (valueBalance - Web3WalletScreen._gasFeeValue).clamp(0, 1 << 31);

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
                      _WalletConnectionCard(onCopy: () => _onCopy(context)),
                      const SizedBox(height: 14),
                      _TokenTransferCard(
                        valueBalanceLabel:
                            '보유 밸류(VALUE): ${_format(valueBalance)}',
                        transferAmountLabel:
                            '${_format(netTransfer)} VALUE',
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.sponsorBgGradientStart,
                          borderRadius:
                              BorderRadius.circular(AppShapes.cardRadius),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('⚠️', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                AppStrings.web3WalletVaspWarning,
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 12,
                                  color: Web3WalletScreen._warningBrown,
                                  height: 1.45,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
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

class _WalletConnectionCard extends StatelessWidget {
  const _WalletConnectionCard({required this.onCopy});

  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return _Web3WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('🦊', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppStrings.web3WalletConnected,
                  style: AppTextStyles.agreementLabel.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.borderLight.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.web3WalletAddress,
                    style: AppTextStyles.agreementLabel.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                InkWell(
                  onTap: onCopy,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      AppStrings.web3WalletCopy,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primaryMint,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TokenTransferCard extends StatelessWidget {
  const _TokenTransferCard({
    required this.valueBalanceLabel,
    required this.transferAmountLabel,
  });

  final String valueBalanceLabel;
  final String transferAmountLabel;

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
            transferAmountLabel,
            style: AppTextStyles.header1.copyWith(fontSize: 28),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.web3WalletGasFee,
            style: AppTextStyles.caption.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            '오프체인 마일리지 → 외부 Transfer 전용 (원화 환전 없음)',
            style: AppTextStyles.caption.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
