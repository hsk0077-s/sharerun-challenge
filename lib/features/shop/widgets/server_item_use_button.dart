import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/api/api_exception.dart';
import '../../../l10n/remaining_surface.dart';
import '../providers/server_shop_inventory_provider.dart';
import '../streak_item_message.dart';

/// Spends one owned item through `POST /actions/shop/use`.
/// The label count is the server inventory stream, not a local decrement.
class ServerItemUseButton extends ConsumerStatefulWidget {
  const ServerItemUseButton({
    super.key,
    required this.itemId,
    required this.label,
    this.emptyHint,
    this.maxUses,
    this.alignment = Alignment.centerLeft,
    this.spend,
  });

  final String itemId;
  final String label;

  /// Disables the button at quantity 0 and replaces the count with this hint.
  final String? emptyHint;

  /// Stops further taps after this many confirmed uses.
  /// The label uses the server count, and never prints a count above this.
  final int? maxUses;
  final Alignment alignment;

  /// Defaults to `POST /actions/shop/use`. Tests pass a fake spend.
  final Future<void> Function(String itemId)? spend;

  @override
  ConsumerState<ServerItemUseButton> createState() =>
      _ServerItemUseButtonState();
}

class _ServerItemUseButtonState extends ConsumerState<ServerItemUseButton> {
  var _used = 0;
  var _busy = false;

  @override
  Widget build(BuildContext context) {
    final count = ref
            .watch(serverShopInventoryProvider)
            .asData
            ?.value
            .countFor(widget.itemId) ??
        0;
    final cap = widget.maxUses;
    final atCap = cap != null && _used >= cap;
    final showBuyHint = count <= 0 && widget.emptyHint != null;
    final shown = cap == null || count <= cap ? count : cap;
    final text = showBuyHint
        ? '${widget.label} · ${widget.emptyHint}'
        : cap == null
            ? RemainingSurface.tr(
                context,
                'shop.server_item_use_button.body',
                '${widget.label} · 보유 $count',
                {'widget.label': widget.label, 'count': count},
              )
            : RemainingSurface.tr(
                context,
                'shop.server_item_use_button.button',
                '${widget.label} · 보유 $shown/$cap',
                {'widget.label': widget.label, 'shown': shown, 'cap': cap},
              );
    final blocked = atCap || showBuyHint;
    return Align(
      alignment: widget.alignment,
      child: TextButton(
        key: Key('use-${widget.itemId}'),
        onPressed: blocked ? null : () => _use(count),
        child: Text(text),
      ),
    );
  }

  Future<void> _use(int count) async {
    if (_busy) return;
    if (widget.maxUses != null && _used >= widget.maxUses!) return;
    if (count <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            RemainingSurface.tr(
              context,
              'shop.server_item_use_button.toast',
              '${widget.label} 보유량이 없습니다.',
              {'widget.label': widget.label},
            ),
          ),
        ),
      );
      return;
    }
    _busy = true;
    try {
      final spend =
          widget.spend ?? ref.read(securedActionApiClientProvider).useShopItem;
      await spend(widget.itemId);
      if (!mounted) return;
      if (widget.maxUses != null) setState(() => _used += 1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            RemainingSurface.tr(
              context,
              'shop.server_item_use_button.toast.2',
              '${widget.label} 사용 완료',
              {'widget.label': widget.label},
            ),
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            streakItemMessage(
              error,
              fallback: RemainingSurface.tr(
                context,
                'shop.server_item_use_button.toast',
                '${widget.label} 보유량이 없습니다.',
                {'widget.label': widget.label},
              ),
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            RemainingSurface.tr(
              context,
              'shop.server_item_use_button.toast.3',
              '${widget.label} 을 사용하지 못했습니다.',
              {'widget.label': widget.label},
            ),
          ),
        ),
      );
    } finally {
      _busy = false;
    }
  }
}
