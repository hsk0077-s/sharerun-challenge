import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../onboarding/src_onboarding_controller.dart';
import 'accessory_catalog.dart';
import 'dressed_mascot.dart';

/// 티어 도감에서 동물에게 액세서리를 입혀 보는 구경용 창.
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

  static Key chipKey(Accessory a) => Key('try-on-${a.name}');

  @override
  State<TryOnSheet> createState() => _TryOnSheetState();
}

class _TryOnSheetState extends State<TryOnSheet> {
  var _worn = <Accessory>{};

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final stage = (width - 40).clamp(200.0, 360.0);
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
            DressedMascot(animal: widget.animal, worn: _worn, size: stage),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final acc in Accessory.values)
                  FilterChip(
                    key: TryOnSheet.chipKey(acc),
                    label: Text(acc.nameKo),
                    selected: _worn.contains(acc),
                    onSelected: (_) =>
                        setState(() => _worn = toggleAccessory(_worn, acc)),
                  ),
              ],
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
