import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/api/api_exception.dart';
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

  /// Stops further taps after this many confirmed uses. Display stays server-side.
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
    final atCap = widget.maxUses != null && _used >= widget.maxUses!;
    final showBuyHint = count <= 0 && widget.emptyHint != null;
    final text = showBuyHint
        ? '${widget.label} · ${widget.emptyHint}'
        : widget.maxUses == null
            ? '${widget.label} · 보유 $count'
            : '${widget.label} · 보유 $count/${widget.maxUses}';
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
        SnackBar(content: Text('${widget.label} 보유량이 없습니다.')),
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
        SnackBar(content: Text('${widget.label} 사용 완료')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            streakItemMessage(
              error,
              fallback: '${widget.label} 보유량이 없습니다.',
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.label} 을 사용하지 못했습니다.')),
      );
    } finally {
      _busy = false;
    }
  }
}
