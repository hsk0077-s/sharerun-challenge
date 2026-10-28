import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../../core/api/api_exception.dart';
import '../../accessories/accessory_catalog.dart';
import '../../accessories/accessory_names.dart';
import '../../accessories/accessory_inventory.dart';
import '../../accessories/dressed_mascot.dart';
import '../../accessories/try_on_sheet.dart';
import '../../crew/crew_membership.dart';
import '../../onboarding/src_onboarding_controller.dart';
import '../../wallet/providers/wallet_provider.dart';
import 'store_look.dart';

/// 상점 '꾸미기' 탭의 소품 목록. 칸(머리·눈·…)을 고르면 두 줄 카드가 보인다.
/// 카드를 누르면 자세히 보기 창이 열리고, 거기서 입혀 보기·사기·입기를 한다.
class AccessoryShopGrid extends ConsumerStatefulWidget {
  const AccessoryShopGrid(
      {required this.animal, required this.tier, super.key});

  /// 입혀서 보여 줄 동물(내 티어 동물, 등급 전이면 늑대).
  final TierAnimal animal;
  final UserTier tier;

  @override
  ConsumerState<AccessoryShopGrid> createState() => _AccessoryShopGridState();
}

class _AccessoryShopGridState extends ConsumerState<AccessoryShopGrid> {
  var _slot = AccessorySlot.head;

  bool _locked(Accessory a) {
    final need = a.tierLock;
    if (need == null) return false;
    return widget.tier.animalUnlockRank <
        UserTier(animal: need).animalUnlockRank;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    final items = accessoriesIn(_slot).where((a) => a.ready).toList();
    final inventory =
        ref.watch(accessoryInventoryProvider).asData?.value ?? const AccessoryInventory();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final s in AccessorySlot.values)
                InkWell(
                  key: Key('store-slot-${s.name}'),
                  onTap: () => setState(() => _slot = s),
                  child: Container(
                    margin: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: s == _slot ? c.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        s.labelKo,
                        style: storeText(
                          14,
                          s == _slot ? c.ink : c.muted,
                          w: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text('아직 준비 중이에요', style: storeText(14, c.muted)),
            ),
          )
        else
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.86,
            padding: EdgeInsets.zero,
            children: [
              for (final a in items)
                _AccessoryCard(
                  accessory: a,
                  animal: widget.animal,
                  locked: _locked(a),
                  owned: inventory.owns(a.id),
                  onTap: () => AccessoryDetailSheet.show(
                    context,
                    accessory: a,
                    animal: widget.animal,
                    tier: widget.tier,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _AccessoryCard extends StatelessWidget {
  const _AccessoryCard({
    required this.accessory,
    required this.animal,
    required this.locked,
    required this.owned,
    required this.onTap,
  });

  final Accessory accessory;
  final TierAnimal animal;
  final bool locked;
  final bool owned;
  final VoidCallback onTap;

  Widget _rarity(BuildContext context) {
    final c = context.srcTokens.colors;
    final strong = accessory.rarity == AccessoryRarity.legend ||
        accessory.rarity == AccessoryRarity.hero;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: strong ? c.primary : Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: strong ? null : Border.all(color: c.outline, width: 1.2),
      ),
      child: Text(
        accessory.rarity.labelKo,
        style:
            storeText(10, strong ? c.onPrimary : c.muted, w: FontWeight.w900),
      ),
    );
  }

  Widget _price(BuildContext context) {
    final c = context.srcTokens.colors;
    final a = accessory;
    if (owned) {
      return Text('보유', style: storeText(14, c.primary, w: FontWeight.w900));
    }
    if (a.rarity == AccessoryRarity.tierReward) {
      return Text('티어 보상', style: storeText(14, c.muted, w: FontWeight.w800));
    }
    final dia = a.currency == AccessoryCurrency.dia;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dia)
          Icon(Icons.diamond_rounded, size: 15, color: c.primary)
        else
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: c.primary, width: 1.6),
            ),
            alignment: Alignment.center,
            child: Text(
              'S',
              style: storeText(9, c.primary, w: FontWeight.w900, h: 1),
            ),
          ),
        const SizedBox(width: 5),
        Text('${a.price ?? 0}',
            style: storeText(14, c.ink, w: FontWeight.w900)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    final focus = accessoryFocus(accessory.slot);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: c.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) {
                  final s = box.maxWidth;
                  return Stack(
                    children: [
                      SizedBox(
                        width: s,
                        height: s,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: ColoredBox(
                            color: c.ink.withValues(alpha: 0.05),
                            child: Transform(
                              transform: Matrix4.identity()
                                ..translateByDouble(
                                  (0.5 - focus.cx * focus.zoom) * s,
                                  (0.5 - focus.cy * focus.zoom) * s,
                                  0,
                                  1,
                                )
                                ..scaleByDouble(focus.zoom, focus.zoom, 1, 1),
                              child: DressedMascot(
                                animal: animal,
                                worn: {accessory},
                                size: s,
                                detail: focus.zoom,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(top: 6, left: 6, child: _rarity(context)),
                      if (locked && accessory.tierLock != null)
                        Positioned(
                          bottom: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.72),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.lock_rounded,
                                  size: 12,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${accessory.tierLock!.labelKo} 티어',
                                  style: storeText(
                                    10,
                                    Colors.white,
                                    w: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              accessory.displayName(Localizations.localeOf(context)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: storeText(14, c.ink, w: FontWeight.w800),
            ),
            const SizedBox(height: 3),
            _price(context),
          ],
        ),
      ),
    );
  }
}


/// 소품 하나의 자세히 보기. 입혀 보기 · 사기 · 입기/벗기.
class AccessoryDetailSheet extends ConsumerStatefulWidget {
  const AccessoryDetailSheet({
    required this.accessory,
    required this.animal,
    required this.tier,
    super.key,
  });

  final Accessory accessory;
  final TierAnimal animal;
  final UserTier tier;

  static const buyKey = Key('accessory-buy');
  static const buyConfirmKey = Key('accessory-buy-confirm');
  static const wearKey = Key('accessory-wear');
  static const tryOnKey = Key('accessory-try-on');

  static Future<void> show(
    BuildContext context, {
    required Accessory accessory,
    required TierAnimal animal,
    required UserTier tier,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.srcTokens.colors.canvas,
      showDragHandle: true,
      builder: (_) => AccessoryDetailSheet(
        accessory: accessory,
        animal: animal,
        tier: tier,
      ),
    );
  }

  @override
  ConsumerState<AccessoryDetailSheet> createState() =>
      _AccessoryDetailSheetState();
}

class _AccessoryDetailSheetState extends ConsumerState<AccessoryDetailSheet> {
  var _busy = false;

  bool get _locked {
    final need = widget.accessory.tierLock;
    if (need == null) return false;
    return widget.tier.animalUnlockRank < UserTier(animal: need).animalUnlockRank;
  }

  bool get _forSale =>
      widget.accessory.rarity != AccessoryRarity.tierReward &&
      widget.accessory.price != null &&
      widget.accessory.currency != AccessoryCurrency.none;

  void _toast(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _buy() async {
    final a = widget.accessory;
    final api = ref.read(crewApiProvider);
    if (api == null) {
      _toast('서버에 연결되면 살 수 있어요.');
      return;
    }
    final dia = a.currency == AccessoryCurrency.dia;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('소품 사기'),
        content: Text(
          () {
            final locale = Localizations.localeOf(context);
            final ask = accessoryPhrase(
              locale,
              'buy',
              name: a.displayName(locale),
              price: a.priceLabel,
            );
            final bonus = !dia
                ? ''
                : locale.languageCode == 'ko'
                    ? '\n보너스 DIA가 있으면 먼저 써요.'
                    : '\nBonus DIA is spent first.';
            return '$ask$bonus';
          }(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            key: AccessoryDetailSheet.buyConfirmKey,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('사기'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted || _busy) return;
    setState(() => _busy = true);
    try {
      final result = await api.purchaseAccessory(a.id);
      ref.read(walletProvider.notifier).applyWalletSnapshot(
            shareBalance: result.shareBalance,
            diamondBalance: result.diamondBalance,
            valueBalance: result.valueTokenBalance,
          );
      _toast(accessoryPhrase(
        Localizations.localeOf(context),
        'bought',
        name: a.displayName(Localizations.localeOf(context)),
      ));
    } on ApiException catch (error) {
      _toast(switch (error.statusCode) {
        400 => '${dia ? 'DIA' : 'SHARE'}가 모자라거나 이미 가진 소품이에요.',
        403 => '아직 티어가 모자라요.',
        _ => '사지 못했어요. 잠시 뒤 다시 해 주세요.',
      });
    } catch (_) {
      _toast('사지 못했어요. 잠시 뒤 다시 해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _wear(bool wearing) async {
    final a = widget.accessory;
    final api = ref.read(crewApiProvider);
    if (api == null || _busy) return;
    setState(() => _busy = true);
    try {
      await api.equipAccessory(slot: a.slot.name, itemId: wearing ? a.id : '');
      final locale = Localizations.localeOf(context);
      _toast(accessoryPhrase(
        locale,
        wearing ? 'wore' : 'off',
        name: a.displayName(locale),
      ));
    } catch (_) {
      _toast('바꾸지 못했어요. 잠시 뒤 다시 해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    final a = widget.accessory;
    final inventory =
        ref.watch(accessoryInventoryProvider).asData?.value ?? const AccessoryInventory();
    final owned = inventory.owns(a.id);
    final worn = inventory.isWorn(a.id);
    final rewardReady =
        a.rarity == AccessoryRarity.tierReward && widget.tier.animalUnlockRank >= 1;
    final stage = (MediaQuery.sizeOf(context).width - 80).clamp(180.0, 300.0);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: SizedBox(
                width: stage,
                height: stage,
                child: DressedMascot(
                  animal: widget.animal,
                  worn: {a},
                  size: stage,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              a.displayName(Localizations.localeOf(context)),
              style: storeText(22, c.ink, w: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              '${a.rarity.labelKo} · ${a.slot.labelKo}'
              '${a.priceLabel.isEmpty ? '' : ' · ${a.priceLabel}'}',
              style: storeText(13, c.muted),
            ),
            if (a.provisional)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('가격은 바뀔 수 있어요.', style: storeText(12, c.muted)),
              ),
            const SizedBox(height: 16),
            OutlinedButton(
              key: AccessoryDetailSheet.tryOnKey,
              onPressed: () => TryOnSheet.show(
                context,
                animal: widget.animal,
                title: widget.animal.labelKo,
              ),
              child: const Text('입혀 보기'),
            ),
            const SizedBox(height: 8),
            if (owned || rewardReady)
              FilledButton(
                key: AccessoryDetailSheet.wearKey,
                onPressed: _busy ? null : () => _wear(!worn),
                child: Text(worn ? '벗기' : '입기'),
              )
            else if (_forSale && _locked)
              FilledButton(
                onPressed: null,
                child: Text('${a.tierLock!.labelKo} 티어가 되면 살 수 있어요'),
              )
            else if (_forSale)
              FilledButton(
                key: AccessoryDetailSheet.buyKey,
                onPressed: _busy ? null : _buy,
                child: Text('사기 · ${a.priceLabel}'),
              )
            else
              const FilledButton(onPressed: null, child: Text('티어 보상이에요')),
          ],
        ),
      ),
    );
  }
}
