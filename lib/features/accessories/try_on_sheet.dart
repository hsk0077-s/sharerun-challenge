import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../onboarding/src_onboarding_controller.dart';
import 'accessory_catalog.dart';
import 'dressed_mascot.dart';

/// 티어 도감에서 동물에게 소품을 입혀 보는 구경용 창.
/// 사거나 저장하지 않는다. 닫으면 처음 모습으로 돌아간다.
class TryOnSheet extends StatefulWidget {
  const TryOnSheet({super.key, required this.animal, required this.title});

  final TierAnimal animal;
  final String title;

  static Future<void> show(
    BuildContext context, {
    required TierAnimal animal,
    required String title,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surfaceWhite,
      showDragHandle: true,
      builder: (_) => TryOnSheet(animal: animal, title: title),
    );
  }

  static Key slotKey(AccessorySlot s) => Key('try-on-slot-${s.name}');
  static Key chipKey(Accessory a) => Key('try-on-${a.id}');

  @override
  State<TryOnSheet> createState() => _TryOnSheetState();
}

class _TryOnSheetState extends State<TryOnSheet> {
  var _worn = <Accessory>{};
  var _slot = AccessorySlot.head;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final stage = (width - 40).clamp(200.0, 340.0);
    final items = accessoriesIn(_slot);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${widget.title} 입혀 보기',
              style: AppTextStyles.header1.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              '구경용이에요. 저장되거나 구매되지 않아요.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textGrey),
            ),
            const SizedBox(height: 12),
            DressedMascot(
              key: Key('dressed-mascot-${widget.animal.code}'),
              animal: widget.animal,
              worn: _worn,
              size: stage,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final slot in AccessorySlot.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        key: TryOnSheet.slotKey(slot),
                        label: Text(slot.labelKo),
                        selected: _slot == slot,
                        onSelected: (_) => setState(() => _slot = slot),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 128,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final acc = items[i];
                  return _ItemCard(
                    key: TryOnSheet.chipKey(acc),
                    animal: widget.animal,
                    acc: acc,
                    selected: _worn.contains(acc),
                    onTap: () =>
                        setState(() => _worn = toggleAccessory(_worn, acc)),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('try-on-clear'),
              onPressed:
                  _worn.isEmpty ? null : () => setState(() => _worn = {}),
              child: const Text('모두 벗기'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 소품 하나. 그 소품만 입은 모습을 칸에 맞게 확대해서 보여 준다.
class _ItemCard extends StatelessWidget {
  const _ItemCard({
    super.key,
    required this.animal,
    required this.acc,
    required this.selected,
    required this.onTap,
  });

  final TierAnimal animal;
  final Accessory acc;
  final bool selected;
  final VoidCallback onTap;

  static const double _thumb = 72;

  @override
  Widget build(BuildContext context) {
    final focus = accessoryFocus(acc.slot);
    final lock = acc.tierLock;
    final sub =
        lock != null && lock != animal ? '${lock.labelKo} 티어' : acc.priceLabel;
    return Semantics(
      button: true,
      selected: selected,
      label: acc.nameKo,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 84,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.14)
                : AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.borderLight,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                width: _thumb,
                height: _thumb,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ColoredBox(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    child: Transform(
                      transform: Matrix4.identity()
                        ..translateByDouble(
                          (0.5 - focus.cx * focus.zoom) * _thumb,
                          (0.5 - focus.cy * focus.zoom) * _thumb,
                          0,
                          1,
                        )
                        ..scaleByDouble(focus.zoom, focus.zoom, 1, 1),
                      child: DressedMascot(
                        animal: animal,
                        worn: {acc},
                        size: _thumb,
                        detail: focus.zoom,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                acc.nameKo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (sub.isNotEmpty)
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 10,
                    color: AppColors.textGrey,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 칸마다 어디를 확대해서 보여 줄지. (cx, cy)는 1024 판에서 0~1로 잰 중심, zoom은 배수.
@visibleForTesting
({double cx, double cy, double zoom}) accessoryFocus(AccessorySlot slot) {
  return switch (slot) {
    AccessorySlot.head => (cx: 0.54, cy: 0.20, zoom: 2.3),
    AccessorySlot.eyes => (cx: 0.58, cy: 0.30, zoom: 2.8),
    AccessorySlot.hand => (cx: 0.68, cy: 0.52, zoom: 2.2),
    AccessorySlot.back => (cx: 0.36, cy: 0.52, zoom: 1.5),
    AccessorySlot.top => (cx: 0.50, cy: 0.56, zoom: 2.0),
    AccessorySlot.bottom => (cx: 0.50, cy: 0.70, zoom: 2.2),
    AccessorySlot.feet => (cx: 0.50, cy: 0.76, zoom: 1.7),
    AccessorySlot.skin => (cx: 0.50, cy: 0.50, zoom: 1.0),
  };
}
