import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/api/api_exception.dart';
import '../providers/server_shop_inventory_provider.dart';

/// Spends one owned item through `POST /actions/shop/use`.
/// The label count is the server inventory stream, not a local decrement.
class ServerItemUseButton extends ConsumerWidget {
  const ServerItemUseButton({
    super.key,
    required this.itemId,
    required this.label,
  });

  final String itemId;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count =
        ref.watch(serverShopInventoryProvider).asData?.value.countFor(itemId) ??
            0;
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        key: Key('use-$itemId'),
        onPressed: () => _use(context, ref, count),
        child: Text('$label · 보유 $count'),
      ),
    );
  }

  Future<void> _use(BuildContext context, WidgetRef ref, int count) async {
    if (count <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label 보유량이 없습니다.')),
      );
      return;
    }
    try {
      await ref.read(securedActionApiClientProvider).useShopItem(itemId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label 사용 완료')),
      );
    } on ApiException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label 보유량이 없습니다.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label 을 사용하지 못했습니다.')),
      );
    }
  }
}
