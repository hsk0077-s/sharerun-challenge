import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers/app_providers.dart';
import '../app/router/route_names.dart';
import '../core/config/app_env.dart';
import '../core/constants/economy_constants.dart';
import '../core/navigation/app_route_nav.dart';
import '../core/navigation/dashboard_tab_navigation.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/theme.dart';
import '../core/widgets/src_dashboard_bottom_nav.dart';
import '../features/onboarding/src_onboarding_controller.dart';
import '../features/shop/providers/server_shop_inventory_provider.dart';
import '../features/shop/widgets/store_look.dart';
import '../data/models/wallet_transaction_model.dart';
import '../features/shop/providers/shop_tab_provider.dart';
import '../features/wallet/providers/wallet_provider.dart';
import '../features/wallet/widgets/wallet_inventory_section.dart';
import 'in_app_billing_screen.dart';
import 'preliminary_eval_screen.dart';
import 'settings_screen.dart';
import 'wallet_history_screen.dart';

/// 나의 지갑 — 마이페이지 헤더 + 홈 지갑 카드 + 거래 카드 DS.
class MyWalletScreen extends ConsumerWidget {
  const MyWalletScreen({super.key});

  static void open(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      try {
        context.pushNamed(RouteNames.myWalletName);
        return;
      } catch (_) {
        context.push(RouteNames.myWallet);
        return;
      }
    }
    AppRouteNav.push<void>(
      context,
      RouteNames.myWallet,
      materialBuilder: (_) => const MyWalletScreen(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.srcTokens.colors;
    final onboarding = ref.watch(onboardingProvider);
    final gradeDone = onboarding.preliminaryPaceSeconds.length
        .clamp(0, EconomyConstants.trialRunsRequired);
    final walletState = ref.watch(walletProvider);
    final share = walletState.shareBalance;
    final diamond = walletState.diamondBalance;
    final value = walletState.valueBalance;
    final inventory = ref.watch(serverShopInventoryProvider).asData?.value ??
        const ServerShopInventory();
    final itemCount = inventory.cprCount +
        inventory.safeGuardCount +
        inventory.coachOnePointCount +
        inventory.extraEntryCount +
        inventory.friendGhostCount +
        inventory.crewCheerCount +
        inventory.boostRunCount +
        inventory.stepIncubatorCount +
        inventory.restDayCount +
        inventory.ghostPaceCount +
        inventory.battlePassCount;

    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const StoreTag('WALLET'),
                  const Spacer(),
                  IconButton(
                    key: const Key('wallet-history-open'),
                    onPressed: () => _openHistory(context),
                    tooltip: AppStrings.myWalletRecentTransactions,
                    icon: Icon(
                      Icons.receipt_long_outlined,
                      size: 22,
                      color: c.muted,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _openSettings(context),
                    tooltip: AppStrings.myPageSettings,
                    icon: Icon(
                      Icons.settings_outlined,
                      size: 22,
                      color: c.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                AppStrings.dashboardMyWallet,
                style: storeText(36, c.ink, w: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              _ShareCard(
                share: share,
                gradeCompleted: gradeDone,
                gradeTotal: EconomyConstants.trialRunsRequired,
                onGradeTap: () => _openGradeEval(context),
                onCharge: () => _openChargePicker(context),
                onUse: () => _openStore(context, ref),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      icon: Icons.diamond_rounded,
                      iconColor: c.primary,
                      value: _comma(diamond),
                      label: 'DIA',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.favorite_rounded,
                      iconColor: c.donation,
                      value: _comma(value),
                      label: 'VALUE',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.inventory_2_outlined,
                      iconColor: Colors.white70,
                      value: '$itemCount',
                      label: 'ITEMS',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const WalletInventorySection(),
              const SizedBox(height: 20),
              Text(
                '최근 내역',
                style: storeText(18, c.ink, w: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              const _WalletRecentHistory(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: DashboardBottomNav(
        currentIndex: DashboardTabNavigation.shop,
        walletTabSelected: true,
        onTap: (index) {
          if (index == DashboardTabNavigation.shop) return;
          DashboardTabNavigation.go(context, index);
        },
      ),
    );
  }

  void _openHistory(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      context.push(RouteNames.walletHistory);
      return;
    }
    AppRouteNav.push<void>(
      context,
      RouteNames.walletHistory,
      materialBuilder: (_) => const WalletHistoryScreen(),
    );
  }

  void _openSettings(BuildContext context) {
    AppRouteNav.push<void>(
      context,
      RouteNames.settings,
      materialBuilder: (_) => const SettingsScreen(),
    );
  }

  void _openChargePicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(AppStrings.myWalletChargeShare),
                subtitle: Text(AppStrings.myWalletChargeShareHint),
              ),
              ListTile(
                title: const Text(AppStrings.myWalletChargeDia),
                subtitle: const Text(AppStrings.myWalletChargeDiaHint),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openBilling(context);
                },
              ),
              const ListTile(
                title: Text(AppStrings.myWalletChargeValue),
                subtitle: Text(AppStrings.myWalletChargeValueHint),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openBilling(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      try {
        context.pushNamed(RouteNames.inAppBilling);
        return;
      } catch (_) {
        context.push(RouteNames.inAppBilling);
        return;
      }
    }
    AppRouteNav.push<void>(
      context,
      RouteNames.inAppBilling,
      materialBuilder: (_) => const InAppBillingScreen(),
    );
  }

  void _openStore(BuildContext context, WidgetRef ref) {
    ref.read(storeFocusProvider.notifier).setFocus(StoreFocus.items);
    DashboardTabNavigation.go(context, DashboardTabNavigation.shop);
  }

  void _openGradeEval(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      try {
        context.pushNamed(RouteNames.preliminaryEvalName);
        return;
      } catch (_) {
        context.push(RouteNames.preliminaryRuns);
        return;
      }
    }
    AppRouteNav.push<void>(
      context,
      RouteNames.preliminaryEval,
      materialBuilder: (_) => const PreliminaryEvalScreen(),
    );
  }
}

/// SHARE 큰 카드. 라임 빛이 도는 바탕에 큰 숫자와 알약 버튼.
class _ShareCard extends StatelessWidget {
  const _ShareCard({
    required this.share,
    required this.gradeCompleted,
    required this.gradeTotal,
    required this.onGradeTap,
    required this.onCharge,
    required this.onUse,
  });

  final int share;
  final int gradeCompleted;
  final int gradeTotal;
  final VoidCallback onGradeTap;
  final VoidCallback onCharge;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    final progress = (gradeCompleted / gradeTotal).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.primary.withValues(alpha: 0.22), c.surface],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StoreTag('SHARE', color: c.primary),
          const SizedBox(height: 8),
          Text(
            _comma(share),
            key: const Key('wallet-share-total'),
            style: storeText(36, c.ink, w: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            '걷고 뛰면 쌓여요. 상점에서 쓸 수 있어요.',
            style: storeText(14, c.muted),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: onGradeTap,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 3,
                    color: c.outline,
                    child: FractionallySizedBox(
                      widthFactor: progress,
                      alignment: Alignment.centerLeft,
                      child: Container(color: c.primary),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppStrings.myWalletGradeProgress(
                        gradeCompleted, gradeTotal),
                    style: storeText(12, c.muted, w: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          StorePillButton(
            key: const Key('wallet-use-share'),
            label: '상점에서 쓰기',
            icon: Icons.shopping_bag_outlined,
            onPressed: onUse,
          ),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              key: const Key('wallet-charge-info'),
              onPressed: onCharge,
              child: Text(
                AppStrings.myWalletCharge,
                style: storeText(13, c.muted, w: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.outline),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: storeText(22, c.ink, w: FontWeight.w900, h: 1.05),
                  ),
                ),
                const SizedBox(height: 4),
                StoreTag(label),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Recent receipts from the server ledger `walletTransactions` for this uid.
/// Does not merge client `wallet_transactions` or debug history.
class _WalletRecentHistory extends ConsumerWidget {
  const _WalletRecentHistory();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (AppEnv.useLocalMockData) {
      return const _WalletHistoryEmpty();
    }
    final history = ref.watch(recentWalletTransactionsProvider);
    return history.when(
      data: (rows) {
        if (rows.isEmpty) return const _WalletHistoryEmpty();
        return Column(
          children: [
            for (var i = 0; i < rows.length; i++)
              WalletTransactionCard(
                title: rows[i].displayLabel,
                date: _historyDate(rows[i]),
                amount: rows[i].amountSummary,
                status: AppStrings.notificationPaymentReceipt,
                leading: Icons.receipt_long_outlined,
              ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => const _WalletHistoryEmpty(),
    );
  }

  static String _historyDate(WalletTransactionModel row) {
    final createdAt = row.createdAt;
    if (createdAt == null) return AppStrings.notificationPaymentJustNow;
    return _formatWalletHistoryDate(createdAt.toLocal());
  }
}

class _WalletHistoryEmpty extends StatelessWidget {
  const _WalletHistoryEmpty();

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        AppStrings.notificationPaymentEmpty,
        style: storeText(14, c.muted),
      ),
    );
  }
}

String _formatWalletHistoryDate(DateTime date) {
  final mm = date.month.toString().padLeft(2, '0');
  final dd = date.day.toString().padLeft(2, '0');
  final hh = date.hour.toString().padLeft(2, '0');
  final min = date.minute.toString().padLeft(2, '0');
  return '${date.year}-$mm-$dd $hh:$min';
}

/// 내역 한 줄: 왼쪽에 이름과 날짜, 오른쪽에 금액. 들어온 돈(+)은 라임색이다.
class WalletTransactionCard extends StatelessWidget {
  const WalletTransactionCard({
    super.key,
    required this.title,
    required this.date,
    required this.amount,
    required this.status,
    required this.leading,
  });

  final String title;
  final String date;
  final String amount;
  final String status;
  final IconData leading;

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    final income = amount.trim().startsWith('+');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.outline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: storeText(16, c.ink, w: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(date, style: storeText(14, c.muted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amount,
            style: storeText(
              18,
              income ? c.primary : c.ink,
              w: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

String _comma(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  final formatted = buffer.toString();
  return value < 0 ? '-$formatted' : formatted;
}
