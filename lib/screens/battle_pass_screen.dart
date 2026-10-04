import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers/app_providers.dart';
import '../core/api/api_exception.dart';
import '../core/navigation/dashboard_tab_navigation.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shapes.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/src_dashboard_bottom_nav.dart';
import '../core/widgets/src_gradient_background.dart';
import '../data/models/shop_item_model.dart';
import '../features/shop/battle_pass_grant.dart';
import '../features/shop/providers/server_shop_inventory_provider.dart';
import '../features/shop/providers/shop_catalog_provider.dart';
import '../features/shop/streak_item_message.dart';
import '../features/wallet/providers/wallet_provider.dart';

/// 배틀런 패스. Purchase and cosmetics come from the server.
class BattlePassScreen extends ConsumerStatefulWidget {
  const BattlePassScreen({super.key});

  @override
  ConsumerState<BattlePassScreen> createState() => _BattlePassScreenState();
}

class _BattlePassScreenState extends ConsumerState<BattlePassScreen> {
  static const _currentNavIndex = DashboardTabNavigation.challenge;
  static const _screenGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE0F7FA), Colors.white],
  );

  var _busy = false;

  void _onNavTap(int index) {
    if (index == _currentNavIndex) {
      Navigator.pop(context);
      return;
    }
    DashboardTabNavigation.go(context, index);
  }

  int _dia(String id, int fallback) {
    final server = ref.watch(shopCatalogProvider).asData?.value[id];
    if (server != null && server > 0) return server;
    for (final item in ShopItemModel.catalog) {
      if (item.id == id) return item.diamondCost;
    }
    return fallback;
  }

  Future<void> _buy(String itemId) async {
    if (_busy) return;
    _busy = true;
    try {
      final result = await ref
          .read(securedActionApiClientProvider)
          .purchaseShopItem(itemId);
      if (!mounted) return;
      ref.read(walletProvider.notifier).applyWalletSnapshot(
            shareBalance: result.shareBalance,
            diamondBalance: result.diamondBalance,
            valueBalance: result.valueTokenBalance,
          );
      final title = serverShopItemTitle(itemId) ?? itemId;
      _toast(
        result.status == 'already_purchased'
            ? '이미 처리된 구매입니다. DIA는 한 번만 차감됩니다.'
            : '$title을 구매했습니다.',
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      _toast(streakItemMessage(error, fallback: '구매하지 못했습니다.'));
    } catch (_) {
      if (!mounted) return;
      _toast('구매하지 못했습니다.');
    } finally {
      _busy = false;
    }
  }

  void _toast(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final grant =
        ref.watch(serverShopInventoryProvider).asData?.value.battlePass ??
            const BattlePassGrant();
    final diamond = ref.watch(walletProvider).diamondBalance;
    final passCost = _dia(battlePassItemId, 120);
    final plusCost = _dia(battlePassPlusItemId, 200);
    final upgrade = plusCost > passCost ? plusCost - passCost : plusCost;
    final status = grant.ownsPlus
        ? AppStrings.battlePassPlusOwned
        : grant.ownsPass
            ? AppStrings.battlePassOwned
            : AppStrings.battlePassNone;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SRCGradientBackground(
          gradient: _screenGradient,
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _BattlePassHeader(
                    diamondBalance: diamond,
                    onBack: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _StatusCard(status: status),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _BuyRow(
                    grant: grant,
                    passCost: passCost,
                    plusCost: plusCost,
                    upgradeCost: upgrade,
                    onBuy: _buy,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      for (final reward in battlePassRewards) ...[
                        _RewardRow(
                            reward: reward, owned: grant.owned(reward.id)),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: DashboardBottomNav(
          currentIndex: _currentNavIndex,
          onTap: _onNavTap,
        ),
      ),
    );
  }
}

class _BattlePassHeader extends StatelessWidget {
  const _BattlePassHeader({
    required this.diamondBalance,
    required this.onBack,
  });

  final int diamondBalance;
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
          Text(
            AppStrings.battlePassTitle,
            style: AppTextStyles.header1.copyWith(fontSize: 17),
            textAlign: TextAlign.center,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.diamond_rounded,
                  color: Color(0xFF42A5F5),
                  size: 18,
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 72,
                  child: Text(
                    '$diamondBalance',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: AppTextStyles.agreementLabel.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
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

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status});

  final String status;

  static const _navy = Color(0xFF1A2B4A);
  static const _gold = Color(0xFFFFD54F);

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('battle-pass-tier'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            status,
            key: const Key('battle-pass-status'),
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _gold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            AppStrings.battlePassCosmeticNote,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textWhite,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _BuyRow extends StatelessWidget {
  const _BuyRow({
    required this.grant,
    required this.passCost,
    required this.plusCost,
    required this.upgradeCost,
    required this.onBuy,
  });

  final BattlePassGrant grant;
  final int passCost;
  final int plusCost;
  final int upgradeCost;
  final Future<void> Function(String itemId) onBuy;

  @override
  Widget build(BuildContext context) {
    if (grant.ownsPlus) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      children: [
        if (!grant.ownsPass)
          TextButton(
            key: const Key('battle-pass-buy-pass'),
            onPressed: () => onBuy(battlePassItemId),
            child: Text('배틀런 패스 · $passCost DIA'),
          ),
        TextButton(
          key: const Key('battle-pass-buy-plus'),
          onPressed: () => onBuy(battlePassPlusItemId),
          child: Text(
            grant.ownsPass
                ? '패스+ 업그레이드 · $upgradeCost DIA'
                : '패스+ · $plusCost DIA',
          ),
        ),
      ],
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({required this.reward, required this.owned});

  final BattlePassReward reward;
  final bool owned;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('battle-pass-reward-${reward.id}'),
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        border: Border.all(
          color: owned ? Colors.amber : AppColors.borderLight,
          width: owned ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            owned ? Icons.check_rounded : Icons.lock_outline_rounded,
            color: owned ? AppColors.textBlack : AppColors.textGreyLight,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              reward.title,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            reward.plusOnly
                ? AppStrings.battlePassPremiumReward
                : AppStrings.battlePassFreeReward,
            style: AppTextStyles.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }
}
