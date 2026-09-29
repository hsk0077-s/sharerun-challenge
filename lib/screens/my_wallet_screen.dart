import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/providers/app_providers.dart';
import '../app/router/route_names.dart';
import '../core/config/app_env.dart';
import '../core/constants/economy_constants.dart';
import '../core/constants/firestore_paths.dart';
import '../core/navigation/app_route_nav.dart';
import '../core/navigation/dashboard_tab_navigation.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shapes.dart';
import '../core/widgets/src_dashboard_bottom_nav.dart';
import '../features/onboarding/src_onboarding_controller.dart';
import '../features/profile/widgets/gender_profile_avatar.dart';
import '../features/shop/providers/shop_tab_provider.dart';
import '../features/wallet/debug_local_wallet_store.dart';
import '../features/wallet/providers/debug_local_share_history_provider.dart';
import '../features/wallet/providers/wallet_provider.dart';
import '../features/wallet/widgets/wallet_inventory_section.dart';
import 'in_app_billing_screen.dart';
import 'preliminary_eval_screen.dart';
import 'settings_screen.dart';

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
    final nickname = ref.watch(userNicknameProvider);
    final displayName = SrcOnboardingController.isUnsetNickname(nickname)
        ? AppStrings.dashboardNickname
        : nickname;
    final onboarding = ref.watch(onboardingProvider);
    final gradeDone = onboarding.preliminaryPaceSeconds.length
        .clamp(0, EconomyConstants.trialRunsRequired);
    final walletState = ref.watch(walletProvider);
    final shop = ref.watch(shopTabProvider);
    final share = walletState.shareBalance;
    final diamond = walletState.diamondBalance;
    final value = walletState.valueBalance;

    return Scaffold(
      backgroundColor: AppColors.myWalletBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppShapes.termsHorizontalPadding,
                  12,
                  AppShapes.termsHorizontalPadding,
                  28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _WalletScreenHeader(
                      onSettings: () => _openSettings(context),
                    ),
                    const SizedBox(height: 16),
                    _WalletProfileRow(nickname: displayName),
                    const SizedBox(height: 20),
                    _MainAssetCard(
                      share: share,
                      diamond: diamond,
                      value: value,
                      gradeCompleted: gradeDone,
                      gradeTotal: EconomyConstants.trialRunsRequired,
                      onGradeTap: () => _openGradeEval(context),
                      onCharge: () => _openBilling(context),
                      onUse: () => _openStore(context, ref),
                    ),
                    const SizedBox(height: 24),
                    WalletInventorySection(shop: shop),
                    const SizedBox(height: 24),
                    const Text(
                      AppStrings.myWalletRecentTransactions,
                      style: MyWalletText.title18,
                    ),
                    const SizedBox(height: 12),
                    const _WalletRecentHistory(),
                  ],
                ),
              ),
            ),
          ],
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

  void _openSettings(BuildContext context) {
    AppRouteNav.push<void>(
      context,
      RouteNames.settings,
      materialBuilder: (_) => const SettingsScreen(),
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
    ref.read(storeFocusProvider.notifier).setFocus(StoreFocus.donate);
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

/// My Wallet 전용 타이포 — 이미지 분석 수치/웨이트.
abstract final class MyWalletText {
  static const title24 = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.myWalletInk,
    height: 1.3,
  );

  static const title18 = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: AppColors.myWalletInk,
    height: 1.3,
  );

  static const shareMint = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: AppColors.myWalletMint,
    height: 1.3,
  );

  static const body16 = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.15,
    color: AppColors.myWalletInk,
    height: 1.35,
  );

  static const muted14 = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColors.myWalletMuted,
    height: 1.4,
  );

  static const button = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
    color: AppColors.textWhite,
    height: 1.2,
  );
}

class _WalletScreenHeader extends StatelessWidget {
  const _WalletScreenHeader({required this.onSettings});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(AppStrings.dashboardMyWallet, style: MyWalletText.title24),
        const SizedBox(width: 4),
        IconButton(
          onPressed: onSettings,
          tooltip: AppStrings.myPageSettings,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          icon: const Icon(
            Icons.settings_outlined,
            size: 22,
            color: AppColors.myWalletInk,
          ),
        ),
      ],
    );
  }
}

class _WalletProfileRow extends StatelessWidget {
  const _WalletProfileRow({required this.nickname});

  final String nickname;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const GenderProfileAvatar(size: 56),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MyWalletText.title18,
                ),
              ),
              const SizedBox(width: 8),
              const _GoldBadge(),
            ],
          ),
        ),
      ],
    );
  }
}

class _GoldBadge extends StatelessWidget {
  const _GoldBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.goldBadge,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.angelGold.withValues(alpha: 0.28),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium_rounded,
            size: 14,
            color: Color(0xFFB45309),
          ),
          SizedBox(width: 3),
          Text(
            AppStrings.dashboardGoldBadge,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF92400E),
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class WalletNeoCard extends StatelessWidget {
  const WalletNeoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppShapes.oauthCardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.myWalletInk.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: AppColors.textWhite.withValues(alpha: 0.85),
            blurRadius: 8,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MainAssetCard extends StatelessWidget {
  const _MainAssetCard({
    required this.share,
    required this.diamond,
    required this.value,
    required this.gradeCompleted,
    required this.gradeTotal,
    required this.onGradeTap,
    required this.onCharge,
    required this.onUse,
  });

  final int share;
  final int diamond;
  final int value;
  final int gradeCompleted;
  final int gradeTotal;
  final VoidCallback onGradeTap;
  final VoidCallback onCharge;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final progress = (gradeCompleted / gradeTotal).clamp(0.0, 1.0);
    final krw = share;

    return WalletNeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.myWalletShareLabel(_comma(share)),
            style: MyWalletText.shareMint,
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.myWalletShareKrw(_comma(krw)),
            style: MyWalletText.muted14,
          ),
          const SizedBox(height: 16),
          _AssetLine(
            icon: Icons.diamond_rounded,
            iconColor: AppColors.myWalletDiamond,
            label: AppStrings.myWalletDiamondLabel(diamond),
          ),
          const SizedBox(height: 10),
          _AssetLine(
            icon: Icons.eco_rounded,
            iconColor: AppColors.myWalletMint,
            label: AppStrings.myWalletValueLabel(_comma(value)),
          ),
          const SizedBox(height: 18),
          _GradeProgressBar(progress: progress),
          const SizedBox(height: 10),
          InkWell(
            onTap: onGradeTap,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                AppStrings.myWalletGradeProgress(gradeCompleted, gradeTotal),
                style: MyWalletText.muted14,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MintActionButton(
                  label: AppStrings.myWalletCharge,
                  onTap: onCharge,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MintActionButton(
                  label: AppStrings.myWalletUse,
                  onTap: onUse,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssetLine extends StatelessWidget {
  const _AssetLine({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: MyWalletText.body16),
        ),
      ],
    );
  }
}

class _GradeProgressBar extends StatelessWidget {
  const _GradeProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 10,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFFEDEDED)),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.myWalletProgressOrange,
                      AppColors.progressYellow,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MintActionButton extends StatelessWidget {
  const _MintActionButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.myWalletMint,
          foregroundColor: AppColors.textWhite,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label, style: MyWalletText.button),
      ),
    );
  }
}

/// Recent receipts from the same read path as the notification payment tab:
/// Firestore `users/{uid}/wallet_transactions` merged with the local ledger.
/// Does not write balances or history.
class _WalletRecentHistory extends ConsumerStatefulWidget {
  const _WalletRecentHistory();

  @override
  ConsumerState<_WalletRecentHistory> createState() =>
      _WalletRecentHistoryState();
}

class _WalletRecentHistoryState extends ConsumerState<_WalletRecentHistory> {
  List<DebugLocalShareTx> _prefsHistory = const [];
  String? _prefsUid;

  void _schedulePrefsRead(String uid) {
    if (_prefsUid == uid) return;
    _prefsUid = uid;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _prefsUid != uid) return;
      try {
        final prefs = await SharedPreferences.getInstance();
        final rows = DebugLocalWalletStore.parseHistory(
          prefs.getString(DebugLocalWalletStore.historyKey(uid)),
        );
        if (!mounted || _prefsUid != uid) return;
        setState(() => _prefsHistory = rows);
      } catch (e) {
        debugPrint('[WALLET] history prefs read: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = _historyUid(ref);
    final providerLocal = ref.watch(debugLocalShareHistoryProvider);
    if (AppEnv.useLocalMockData || uid.isEmpty) {
      return const _WalletHistoryEmpty();
    }
    _schedulePrefsRead(uid);
    final local = DebugLocalWalletStore.mergeHistory(
      remote: providerLocal,
      local: _prefsHistory,
    );
    if (Firebase.apps.isEmpty) {
      return _historyBody(local);
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(FirestorePaths.users)
          .doc(uid)
          .collection('wallet_transactions')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        final remote = <DebugLocalShareTx>[];
        final snapData = snapshot.data;
        if (snapData != null) {
          for (final doc in snapData.docs) {
            remote.add(_txFromFirestore(doc.id, doc.data()));
          }
        }
        final rows = DebugLocalWalletStore.mergeHistory(
          remote: remote,
          local: local,
        );
        final waiting = snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData &&
            local.isEmpty;
        if (waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.pulseCyan,
                ),
              ),
            ),
          );
        }
        return _historyBody(rows);
      },
    );
  }

  static DebugLocalShareTx _txFromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final titleRaw = data['title'];
    final title = titleRaw is String && titleRaw.isNotEmpty
        ? titleRaw
        : AppStrings.notificationPaymentUnknown;
    final amountRaw = data['amount'];
    final amount = amountRaw is num ? amountRaw.toInt() : 0;
    final assetRaw = data['assetType'];
    final assetType =
        assetRaw is String && assetRaw.isNotEmpty ? assetRaw : 'SHARE';
    final tsRaw = data['timestamp'];
    final timestampMs =
        tsRaw is Timestamp ? tsRaw.toDate().millisecondsSinceEpoch : 0;
    return DebugLocalShareTx(
      id: id,
      title: title,
      amount: amount,
      assetType: assetType,
      timestampMs: timestampMs,
    );
  }
}

class _WalletHistoryEmpty extends StatelessWidget {
  const _WalletHistoryEmpty();

  @override
  Widget build(BuildContext context) {
    return const Text(
      AppStrings.notificationPaymentEmpty,
      style: MyWalletText.muted14,
    );
  }
}

Widget _historyBody(List<DebugLocalShareTx> rows) {
  if (rows.isEmpty) return const _WalletHistoryEmpty();
  return Column(
    children: [
      for (var i = 0; i < rows.length; i++) ...[
        if (i > 0) const SizedBox(height: 10),
        WalletTransactionCard(
          title: rows[i].title,
          date: rows[i].timestampMs > 0
              ? _formatWalletHistoryDate(rows[i].timestamp.toLocal())
              : AppStrings.notificationPaymentJustNow,
          amount: _historyAmount(rows[i]),
          status: AppStrings.notificationPaymentReceipt,
          leading: Icons.receipt_long_outlined,
        ),
      ],
    ],
  );
}

String _historyAmount(DebugLocalShareTx tx) {
  final sign = tx.amount < 0 ? '' : '+';
  return '$sign${tx.amount} ${tx.assetType}';
}

String _formatWalletHistoryDate(DateTime date) {
  final mm = date.month.toString().padLeft(2, '0');
  final dd = date.day.toString().padLeft(2, '0');
  final hh = date.hour.toString().padLeft(2, '0');
  final min = date.minute.toString().padLeft(2, '0');
  return '${date.year}-$mm-$dd $hh:$min';
}

String _historyUid(WidgetRef ref) {
  final authUid = ref.watch(authStateChangesProvider).asData?.value?.uid ?? '';
  if (authUid.isNotEmpty) return authUid;
  return ref.watch(persistedAuthSessionProvider)?.uid ?? '';
}

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
    return WalletNeoCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(leading, size: 22, color: AppColors.myWalletInk),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: MyWalletText.body16),
                const SizedBox(height: 4),
                Text(date, style: MyWalletText.muted14),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: MyWalletText.title18),
              const SizedBox(height: 4),
              Text(status, style: MyWalletText.muted14),
            ],
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
