import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
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
            child: const Text('환불 신청하기'),
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

  String _why(DiaPurchase p) => switch (p.reason) {
        'already_refunded' => p.status == 'refunded' ? '환불이 끝났어요.' : '환불을 신청했어요. 확인 중이에요.',
        'nothing_left' => '쓰지 않은 유료 DIA가 없어서 환불할 금액이 없어요.',
        'period_over' => '환불 기간이 지났어요.',
        _ => '환불할 수 없어요.',
      };

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
        title: const Text('환불 신청'),
        content: Text(
          '쓰지 않은 유료 DIA ${p.paidDia}개'
          '${p.bonusRevoked > 0 ? '와 덤 ${p.bonusRevoked}개' : ''}가 빠지고 '
          '${_won(p.refundKrw)}원이 환불돼요.'
          '${p.bonusSpent > 0 ? '\n이미 쓴 덤 ${p.bonusSpent}개는 ${_won(p.bonusSpent * 100)}원을 뺐어요.' : ''}'
          '\n신청하면 되돌릴 수 없어요.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(
            key: DiaRefundSheet.confirmKey,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('환불 신청'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final result = await api.requestDiaRefund(p.purchaseId);
      ref.invalidate(diaPurchasesProvider);
      _toast(result.done
          ? '${_won(result.refundKrw)}원이 환불됐어요.'
          : '환불을 신청했어요. 담당자가 확인해 환불해 드려요.');
    } on ApiException catch (error) {
      _toast(error.statusCode == 409 ? '이미 환불을 신청한 구매예요.' : '환불하지 못했어요. 잠시 뒤 다시 해 주세요.');
      ref.invalidate(diaPurchasesProvider);
    } catch (_) {
      _toast('환불하지 못했어요. 잠시 뒤 다시 해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
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
            Text('DIA 환불', style: storeText(20, c.ink, w: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(
              '산 날부터 $days일 안, 쓰지 않은 유료 DIA만 환불돼요.',
              style: storeText(12, c.muted),
            ),
            const SizedBox(height: 12),
            if (data.asData?.value == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  data.isLoading ? '불러오는 중이에요…' : '서버에 연결되면 환불할 수 있어요.',
                  textAlign: TextAlign.center,
                  style: storeText(14, c.muted),
                ),
              )
            else if (purchases.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  '$days일 안에 산 DIA 팩이 없어요.',
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
                      'DIA ${p.packDia}개 팩 · ${_won(p.priceKrw)}원',
                      style: storeText(15, c.ink, w: FontWeight.w800),
                    ),
                    if (p.createdAt != null)
                      Text(
                        '${p.createdAt!.toLocal().month}월 ${p.createdAt!.toLocal().day}일에 샀어요',
                        style: storeText(12, c.muted),
                      ),
                    const SizedBox(height: 8),
                    if (p.eligible) ...[
                      Text(
                        '환불 ${_won(p.refundKrw)}원 · 유료 DIA ${p.paidDia}개'
                        '${p.bonusRevoked > 0 ? ' + 덤 ${p.bonusRevoked}개 회수' : ''}',
                        style: storeText(13, c.ink),
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        key: DiaRefundSheet.refundKey(p.purchaseId),
                        onPressed: _busy ? null : () => _refund(p),
                        child: Text('${_won(p.refundKrw)}원 환불 신청'),
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
