import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/providers/app_providers.dart';
import '../app/router/route_names.dart';
import '../core/config/app_env.dart';
import '../core/constants/firestore_paths.dart';
import '../core/navigation/app_route_nav.dart';
import '../core/navigation/dashboard_tab_navigation.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shapes.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/src_dashboard_bottom_nav.dart';
import '../core/widgets/src_gradient_background.dart';
import '../features/profile/user_profile_notifier.dart';
import '../features/shop/providers/shop_tab_provider.dart';
import '../features/wallet/debug_local_wallet_store.dart';
import '../features/wallet/providers/debug_local_share_history_provider.dart';
import '../features/wallet/widgets/wallet_inventory_section.dart';
import 'appeal_center_screen.dart';
import 'solo_pedometer_screen.dart';

/// 알림 센터 및 재화 히스토리 화면 (Screen 28).
class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  /// 0: 시스템 알림, 1: 결제/히스토리 (src-28).
  final int initialTabIndex;

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen>
    with SingleTickerProviderStateMixin {
  static final _screenGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE0F7FA), Colors.white],
  );

  late TabController _tabController;
  static const _currentNavIndex = DashboardTabNavigation.home;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialTabIndex.clamp(0, 1);
    _tabController =
        TabController(length: 2, vsync: this, initialIndex: initial);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == _currentNavIndex) {
      Navigator.pop(context);
      return;
    }
    DashboardTabNavigation.go(context, index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SRCGradientBackground(
        gradient: _screenGradient,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth - 32;

            return SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: _NotificationHeader(
                      onBack: () => Navigator.pop(context),
                    ),
                  ),
                  SizedBox(height: 12),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: _NotificationTabBar(controller: _tabController),
                  ),
                  SizedBox(height: 12),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _RealtimeSystemNotificationList(
                          cardWidth: cardWidth,
                        ),
                        const _RealtimePaymentHistoryList(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: DashboardBottomNav(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

class _NotificationHeader extends StatelessWidget {
  _NotificationHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded),
            color: AppColors.textBlack,
            iconSize: 22,
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              AppStrings.notificationCenterTitle,
              style: AppTextStyles.header1.copyWith(fontSize: 17),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTabBar extends StatelessWidget {
  _NotificationTabBar({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      labelColor: AppColors.textBlack,
      unselectedLabelColor: AppColors.textGrey,
      indicatorColor: AppColors.primaryMint,
      indicatorWeight: 3,
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: AppColors.borderLight,
      labelStyle: AppTextStyles.agreementLabel.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
      unselectedLabelStyle: AppTextStyles.agreementLabel.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      tabs: [
        Tab(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🔔', style: TextStyle(fontSize: 14)),
              SizedBox(width: 6),
              Text(AppStrings.notificationTabSystem),
            ],
          ),
        ),
        Tab(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('💳', style: TextStyle(fontSize: 14)),
              SizedBox(width: 6),
              Text(AppStrings.notificationTabPayment),
            ],
          ),
        ),
      ],
    );
  }
}

class _RealtimeSystemNotificationList extends ConsumerWidget {
  const _RealtimeSystemNotificationList({required this.cardWidth});

  final double cardWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = _signedInUid(ref);
    if (AppEnv.useLocalMockData || uid.isEmpty) {
      return const _SystemNotificationEmpty();
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(FirestorePaths.users)
          .doc(uid)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.pulseCyan),
          );
        }
        if (snapshot.hasError) {
          return const _SystemNotificationEmpty();
        }
        final snapData = snapshot.data;
        if (snapData == null || snapData.docs.isEmpty) {
          return const _SystemNotificationEmpty();
        }
        final docs = snapData.docs;
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final titleRaw = data['title'];
            final title = titleRaw is String && titleRaw.isNotEmpty
                ? titleRaw
                : AppStrings.notificationSystemFallbackTitle;
            final bodyRaw = data['body'];
            final body = bodyRaw is String ? bodyRaw : '';
            final codeRaw = data['code'];
            final code = codeRaw is String ? codeRaw : '';
            final routeRaw = data['routeName'];
            final routeName = routeRaw is String ? routeRaw : '';
            final tsRaw = data['timestamp'];
            final timestamp = tsRaw is Timestamp ? tsRaw : null;
            final dateStr = timestamp != null
                ? _formatNotificationDay(timestamp.toDate().toLocal())
                : AppStrings.notificationPaymentJustNow;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _NotificationCard(
                width: cardWidth,
                icon: _systemNoticeIcon(code),
                title: title,
                onTap: () => _openRetentionRoute(
                  context,
                  code: code,
                  routeName: routeName,
                ),
                body: Text(
                  body,
                  textScaler: TextScaler.noScaling,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.textBlack.withValues(alpha: 0.85),
                  ),
                ),
                time: dateStr,
              ),
            );
          },
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.width,
    required this.icon,
    required this.title,
    required this.body,
    required this.time,
    this.onTap,
  });

  final double width;
  final String icon;
  final String title;
  final Widget body;
  final String time;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 110,
      child: Material(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
        padding: EdgeInsets.fromLTRB(14, 12, 14, 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppShapes.cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(icon, style: TextStyle(fontSize: 18)),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        textScaler: TextScaler.noScaling,
                        style: AppTextStyles.agreementLabel.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Expanded(child: body),
              ],
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Text(
                time,
                textScaler: TextScaler.noScaling,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textGreyLight,
                ),
              ),
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }
}

void _openRetentionRoute(
  BuildContext context, {
  required String code,
  required String routeName,
}) {
  final target = routeName.isNotEmpty
      ? routeName
      : switch (code) {
          'golden_hour' => RouteNames.soloPedometer,
          'jena_pending' => RouteNames.appealCenter,
          _ => '',
        };
  if (target.isEmpty) return;

  final router = GoRouter.maybeOf(context);
  if (router != null) {
    try {
      context.pushNamed(target);
      return;
    } catch (_) {
      if (target == RouteNames.soloPedometer ||
          target == RouteNames.soloPedometerPath) {
        context.push(RouteNames.soloPedometerPath);
        return;
      }
      if (target == RouteNames.appealCenter || target == RouteNames.appeal) {
        context.push(RouteNames.appeal);
        return;
      }
    }
  }

  if (target == RouteNames.soloPedometer ||
      target == RouteNames.soloPedometerPath) {
    AppRouteNav.push<void>(
      context,
      RouteNames.soloPedometerPath,
      materialBuilder: (_) => const SoloPedometerScreen(),
    );
    return;
  }
  if (target == RouteNames.appealCenter || target == RouteNames.appeal) {
    AppRouteNav.push<void>(
      context,
      RouteNames.appeal,
      materialBuilder: (_) => const AppealCenterScreen(),
    );
  }
}

class _RealtimePaymentHistoryList extends ConsumerStatefulWidget {
  const _RealtimePaymentHistoryList();

  static const _debitColor = Color(0xFFFF453A);
  static const _creditColor = Color(0xFF30D158);

  @override
  ConsumerState<_RealtimePaymentHistoryList> createState() =>
      _RealtimePaymentHistoryListState();
}

class _RealtimePaymentHistoryListState
    extends ConsumerState<_RealtimePaymentHistoryList> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hydrateLocalHistory();
    });
  }

  Future<void> _hydrateLocalHistory() async {
    final uid = _signedInUid(ref);
    if (uid.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final snap = DebugLocalWalletStore.hydrateFromPrefs(prefs, uid);
      if (!mounted || snap.history.isEmpty) return;
      ref.read(debugLocalShareHistoryProvider.notifier).replace(snap.history);
    } catch (e) {
      debugPrint('[HISTORY] local hydrate: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _signedInUid(ref);
    final local = ref.watch(debugLocalShareHistoryProvider);
    final shop = ref.watch(shopTabProvider);
    final history = (AppEnv.useLocalMockData || uid.isEmpty)
        ? const _PaymentHistoryEmpty()
        : _paymentHistoryStream(uid, local);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: WalletInventorySection(shop: shop, compact: true),
        ),
        Expanded(child: history),
      ],
    );
  }

  Widget _paymentHistoryStream(String uid, List<DebugLocalShareTx> local) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(FirestorePaths.users)
          .doc(uid)
          .collection('wallet_transactions')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData &&
            local.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.pulseCyan),
          );
        }
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
        if (rows.isEmpty) {
          return const _PaymentHistoryEmpty();
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          itemCount: rows.length,
          itemBuilder: (context, index) {
            return _PaymentHistoryTile(tx: rows[index]);
          },
        );
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

class _PaymentHistoryTile extends StatelessWidget {
  const _PaymentHistoryTile({required this.tx});

  final DebugLocalShareTx tx;

  @override
  Widget build(BuildContext context) {
    final dateStr = tx.timestampMs > 0
        ? _formatWalletTxDate(tx.timestamp.toLocal())
        : AppStrings.notificationPaymentJustNow;
    final isNegative = tx.amount < 0;
    final amountLabel = '${isNegative ? '' : '+'}${tx.amount} ${tx.assetType}';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderLight.withValues(alpha: 0.8),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textBlack.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.title,
                  style: AppTextStyles.agreementLabel.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  dateStr,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amountLabel,
                style: TextStyle(
                  color: isNegative
                      ? _RealtimePaymentHistoryList._debitColor
                      : _RealtimePaymentHistoryList._creditColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                AppStrings.notificationPaymentReceipt,
                style: TextStyle(
                  color: AppColors.tealAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentHistoryEmpty extends StatelessWidget {
  const _PaymentHistoryEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        AppStrings.notificationPaymentEmpty,
        textScaler: TextScaler.noScaling,
        style: AppTextStyles.caption.copyWith(
          fontSize: 14,
          color: AppColors.textGrey,
        ),
      ),
    );
  }
}

class _SystemNotificationEmpty extends StatelessWidget {
  const _SystemNotificationEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        AppStrings.notificationSystemEmpty,
        textScaler: TextScaler.noScaling,
        style: AppTextStyles.caption.copyWith(
          fontSize: 14,
          color: AppColors.textGrey,
        ),
      ),
    );
  }
}

String _signedInUid(WidgetRef ref) {
  final profileUid = ref.watch(userProfileProvider).uid;
  final authUid = ref.watch(authStateChangesProvider).asData?.value?.uid ?? '';
  return profileUid.isNotEmpty ? profileUid : authUid;
}

String _systemNoticeIcon(String code) {
  return switch (code) {
    'jena_pending' => '⚠️',
    'shoe_limit' || 'shoe_warn' => '👟',
    'golden_hour' => '👼',
    _ => '🔔',
  };
}

String _formatWalletTxDate(DateTime date) {
  final mm = date.month.toString().padLeft(2, '0');
  final dd = date.day.toString().padLeft(2, '0');
  final hh = date.hour.toString().padLeft(2, '0');
  final min = date.minute.toString().padLeft(2, '0');
  return '${date.year}-$mm-$dd $hh:$min';
}

String _formatNotificationDay(DateTime date) {
  return '${date.month}월 ${date.day}일';
}
