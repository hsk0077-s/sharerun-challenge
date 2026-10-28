import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../l10n/dia_refund_copy.dart';
import '../../../l10n/guidance_copy.dart';
import '../../../core/theme/theme.dart';
import '../../crew/crew_membership.dart';
import '../../shop/widgets/store_look.dart';
import '../dia_refund.dart';

/// DIA 안내: 유료/보너스, 쓰는 순서, 환불. 충전하는 화면 아래에 둔다.
class DiaNoticeCard extends StatelessWidget {
  const DiaNoticeCard({super.key});

  static const noticeKey = Key('dia-notice');
  static const refundButtonKey = Key('dia-refund-open');

  /// 화면에 그대로 보이는 안내 문구. 약관·달팽이 봇 답변과 같은 내용을 쓴다.
  static const lines = <String>[
    '1 DIA는 100원이에요.',
    '돈으로 산 DIA(유료)와 무료로 받은 DIA(보너스)가 있어요. 쓸 때는 보너스 DIA를 먼저 써요.',
    '보너스 DIA는 현금으로 바꿀 수 없어요.',
    '배틀패스와 패스+는 유료 DIA로만 살 수 있어요.',
    '산 날부터 7일 안에, 쓰지 않은 유료 DIA는 환불할 수 있어요. 함께 받은 덤(보너스)은 같이 빠지고, 이미 쓴 덤은 환불 금액에서 DIA당 100원씩 빼요.',
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    final copy = DiaNoticeGuidance.of(Localizations.localeOf(context));
    return Container(
      key: noticeKey,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(copy.title, style: storeText(15, c.ink, w: FontWeight.w900)),
          const SizedBox(height: 8),
          for (final line in copy.lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $line', style: storeText(12, c.muted, h: 1.45)),
            ),
          const SizedBox(height: 6),
          OutlinedButton(
            key: refundButtonKey,
            onPressed: () => DiaRefundSheet.show(context),
            child: Text(DiaRefundCopy.of(Localizations.localeOf(context)).openButton),
          ),
        ],
      ),
    );
  }
}

/// 7일 안에 산 DIA 팩 목록과 환불 신청.
class DiaRefundSheet extends ConsumerStatefulWidget {
  const DiaRefundSheet({super.key});

  static Key refundKey(String id) => Key('dia-refund-$id');
  static const confirmKey = Key('dia-refund-confirm');

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.srcTokens.colors.canvas,
      showDragHandle: true,
      builder: (_) => const DiaRefundSheet(),
    );
  }

  @override
  ConsumerState<DiaRefundSheet> createState() => _DiaRefundSheetState();
}

class _DiaRefundSheetState extends ConsumerState<DiaRefundSheet> {
  var _busy = false;

  static String _won(int v) => v.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => ',',
      );

  DiaRefundCopy get _copy => DiaRefundCopy.of(Localizations.localeOf(context));

  String _why(DiaPurchase p) => _copy.why(p.reason, p.status);

  void _toast(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _refund(DiaPurchase p) async {
    final api = ref.read(crewApiProvider);
    if (api == null || _busy) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_copy.dialogTitle),
        content: Text(
          _copy.confirmBody(
            paidDia: p.paidDia,
            bonusRevoked: p.bonusRevoked,
            refund: _won(p.refundKrw),
            bonusSpent: p.bonusSpent,
            spent: _won(p.bonusSpent * 100),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_copy.cancel)),
          FilledButton(
            key: DiaRefundSheet.confirmKey,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_copy.confirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final result = await api.requestDiaRefund(p.purchaseId);
      ref.invalidate(diaPurchasesProvider);
      _toast(result.done ? _copy.done(_won(result.refundKrw)) : _copy.pending);
    } on ApiException catch (error) {
      _toast(error.statusCode == 409 ? _copy.already : _copy.failed);
      ref.invalidate(diaPurchasesProvider);
    } catch (_) {
      _toast(_copy.failed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    final copy = _copy;
    final data = ref.watch(diaPurchasesProvider);
    final days = data.asData?.value?.refundDays ?? 7;
    final purchases = data.asData?.value?.purchases ?? const <DiaPurchase>[];
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            Text(copy.sheetTitle, style: storeText(20, c.ink, w: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(
              copy.window(days),
              style: storeText(12, c.muted),
            ),
            const SizedBox(height: 12),
            if (data.asData?.value == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  data.isLoading ? copy.loading : copy.offline,
                  textAlign: TextAlign.center,
                  style: storeText(14, c.muted),
                ),
              )
            else if (purchases.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  copy.empty(days),
                  textAlign: TextAlign.center,
                  style: storeText(14, c.muted),
                ),
              ),
            for (final p in purchases)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      copy.pack(p.packDia, _won(p.priceKrw)),
                      style: storeText(15, c.ink, w: FontWeight.w800),
                    ),
                    if (p.createdAt != null)
                      Text(
                        copy.boughtOn(p.createdAt!.toLocal().month, p.createdAt!.toLocal().day),
                        style: storeText(12, c.muted),
                      ),
                    const SizedBox(height: 8),
                    if (p.eligible) ...[
                      Text(
                        copy.eligible(
                          refund: _won(p.refundKrw),
                          paidDia: p.paidDia,
                          bonusRevoked: p.bonusRevoked,
                        ),
                        style: storeText(13, c.ink),
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        key: DiaRefundSheet.refundKey(p.purchaseId),
                        onPressed: _busy ? null : () => _refund(p),
                        child: Text(copy.apply(_won(p.refundKrw))),
                      ),
                    ] else
                      Text(_why(p), style: storeText(13, c.muted)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
