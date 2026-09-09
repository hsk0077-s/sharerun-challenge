import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers/app_providers.dart';
import '../app/router/route_names.dart';
import '../app/theme/app_colors.dart';
import '../core/config/app_env.dart';
import '../core/api/api_exception.dart';
import '../core/auth/email_verification_guard.dart';
import '../core/constants/impact_constants.dart';
import '../core/constants/payment_constants.dart';
import '../core/widgets/async_value_section.dart';
import '../core/widgets/currency_badge.dart';
import '../data/models/shop_item_model.dart';
import '../data/models/wallet_model.dart';
import '../data/models/wallet_transaction_model.dart';
import '../features/wallet/widgets/economy_status_card.dart';
import '../features/wallet/widgets/shop_section.dart';
import '../features/wallet/widgets/web3_transfer_section.dart';
import 'in_app_billing_screen.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  bool refunding = false;
  bool creatingTopUp = false;
  bool buyingDiamonds = false;
  String? purchasingItemId;
  bool transferringWeb3 = false;

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(activeWalletProvider).value ?? WalletModel.empty();
    final profile = ref.watch(activeUserProfileProvider).value;
    final economy = profile?.economy;
    final authUser = ref.watch(authStateChangesProvider).value;
    final donationProgress = wallet.totalDonationValue <= 0
        ? 0.0
        : (wallet.totalDonationValue / ImpactConstants.donationMilestoneValue)
            .clamp(0.0, 1.0);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('지갑 & 기부', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        CurrencyBadge(
          label: 'Share - 환불 가능 충전금',
          amount: wallet.shareBalance,
          color: AppColors.electricBlue,
        ),
        const SizedBox(height: 12),
        CurrencyBadge(
          label: 'Diamond - 유료 아이템 재화',
          amount: wallet.diamondBalance,
          color: Colors.purpleAccent,
        ),
        const SizedBox(height: 12),
        CurrencyBadge(
          label: 'SRV (Value Token) - 노력 기반 명예 토큰',
          amount: wallet.valueTokenBalance,
          color: AppColors.neonLime,
        ),
        const SizedBox(height: 24),
        Web3TransferSection(
          valueTokenBalance: wallet.valueTokenBalance,
          transferring: transferringWeb3,
          onTransfer: _transferValueToWeb3,
        ),
        if (economy != null) ...[
          const SizedBox(height: 24),
          EconomyStatusCard(economy: economy),
        ],
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBlack,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('누적 기부'),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: donationProgress,
                color: AppColors.neonLime,
                backgroundColor: Colors.white12,
                minHeight: 12,
              ),
              const SizedBox(height: 12),
              Text(
                '${wallet.totalDonationValue} / ${ImpactConstants.donationMilestoneValue} Value donated',
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        ShopSection(
          diamondBalance: wallet.diamondBalance,
          buyingDiamonds: buyingDiamonds,
          purchasingItemId: purchasingItemId,
          onBuyDiamonds: () => _buyDiamonds(uid: authUser?.uid),
          onPurchase: _purchaseShopItem,
        ),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: authUser == null || creatingTopUp
              ? null
              : () => _createShareTopUp(uid: authUser.uid),
          icon: creatingTopUp
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_card_rounded),
          label: Text(
            creatingTopUp
                ? '결제 생성 중...'
                : 'Share ${PaymentConstants.shareTopUpAmountKrw}원 충전하기',
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.dangerRed,
            side: const BorderSide(color: AppColors.dangerRed),
            padding: const EdgeInsets.symmetric(vertical: 18),
          ),
          onPressed: authUser == null || wallet.shareBalance <= 0 || refunding
              ? null
              : () => _requestRefund(
                    shareAmount: wallet.shareBalance,
                  ),
          icon: refunding
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.undo_rounded),
          label: Text(
            refunding
                ? '환불 요청 중...'
                : '결제 취소 (현금 환불) - ${wallet.shareBalance} Share',
          ),
        ),
        const SizedBox(height: 28),
        Text('최근 거래', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        AsyncValueSection<List<WalletTransactionModel>>(
          asyncValue: ref.watch(recentWalletTransactionsProvider),
          dataBuilder: (context, transactions) {
            if (transactions.isEmpty) {
              return const Text('아직 지갑 거래 내역이 없습니다.');
            }

            return Column(
              children: transactions
                  .map(
                    (transaction) => Card(
                      child: ListTile(
                        title: Text(transaction.displayLabel),
                        subtitle: Text(
                          _formatTransactionSubtitle(transaction),
                        ),
                        trailing: Text(
                          transaction.amountSummary,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Future<void> _transferValueToWeb3({
    required String destinationAddress,
    required int amountSrv,
    required Web3TransferChannel channel,
  }) async {
    setState(() => transferringWeb3 = true);
    try {
      if (AppEnv.useLocalMockData) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '[Mock] $amountSrv SRV → ${channel.label} '
              '(${destinationAddress.substring(0, 10)}...) 전송 UI 미리보기',
            ),
          ),
        );
        return;
      }

      await ref.read(walletRepositoryProvider).transferValueToWeb3(
            destinationAddress: destinationAddress,
            amountSrv: amountSrv,
            transferChannel: channel.apiValue,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$amountSrv SRV가 ${channel.label}(으)로 전송 요청되었습니다. '
            '앱 내 현금 환전은 제공하지 않습니다.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Web3 전송 실패: ${ApiErrorMessage.from(error)}')),
      );
    } finally {
      if (mounted) {
        setState(() => transferringWeb3 = false);
      }
    }
  }

  Future<void> _buyDiamonds({required String? uid}) async {
    if (uid == null) {
      return;
    }
    setState(() => buyingDiamonds = true);
    try {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Diamond 충전 결제는 Mock 모드에서 UI 미리보기만 제공됩니다.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => buyingDiamonds = false);
      }
    }
  }

  Future<void> _purchaseShopItem(ShopItemModel item) async {
    setState(() => purchasingItemId = item.id);
    try {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.title} 구매는 Mock 모드에서 UI만 표시됩니다.')),
      );
    } finally {
      if (mounted) {
        setState(() => purchasingItemId = null);
      }
    }
  }

  Future<void> _createShareTopUp({
    required String uid,
  }) async {
    final authUser = ref.read(authStateChangesProvider).value;
    if (authUser == null) {
      return;
    }
    final verified = await ensureEmailVerified(
      context: context,
      user: authUser,
    );
    if (!verified) {
      return;
    }

    setState(() => creatingTopUp = true);
    try {
      if (!mounted) {
        return;
      }
      final credited = await context.push<bool>(
        RouteNames.inAppBilling,
        extra: PaymentConstants.shareTopUpAmountKrw,
      );
      if (!mounted) return;
      if (credited != true) {
        await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => const InAppBillingScreen(
              highlightAmountWon: PaymentConstants.shareTopUpAmountKrw,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Share 충전이 Wallet에 반영되었습니다.')),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('충전 결제 생성 실패: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => creatingTopUp = false);
      }
    }
  }

  Future<void> _requestRefund({
    required int shareAmount,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('현금 환불 요청'),
          content: Text('$shareAmount Share를 전액 환불 요청하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('환불 요청'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() => refunding = true);
    try {
      await ref.read(walletRepositoryProvider).requestCashRefund(
            shareAmount: shareAmount,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('현금 환불 요청이 접수되었습니다.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('환불 요청 실패: ${ApiErrorMessage.from(error)}')),
      );
    } finally {
      if (mounted) {
        setState(() => refunding = false);
      }
    }
  }

  String _formatTransactionSubtitle(WalletTransactionModel transaction) {
    final createdAt = transaction.createdAt;
    final dateLabel = createdAt == null
        ? '날짜 미확인'
        : '${createdAt.year}.${createdAt.month.toString().padLeft(2, '0')}.'
            '${createdAt.day.toString().padLeft(2, '0')}';
    if (transaction.tournamentId != null) {
      return '$dateLabel · ${transaction.tournamentId}';
    }
    return dateLabel;
  }
}
