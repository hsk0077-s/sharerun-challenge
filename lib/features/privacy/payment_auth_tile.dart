import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../iap/payment_auth.dart';
import '../iap/providers/iap_providers.dart';

/// 결제 전 본인 확인 스위치. 기본은 켬이고, 끌 때도 본인 확인을 한 번 거친다.
class PaymentAuthTile extends ConsumerStatefulWidget {
  const PaymentAuthTile({super.key});

  static const switchKey = Key('payment-auth-switch');

  @override
  ConsumerState<PaymentAuthTile> createState() => _PaymentAuthTileState();
}

class _PaymentAuthTileState extends ConsumerState<PaymentAuthTile> {
  bool _on = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final on = await ref.read(paymentAuthGateProvider).isEnabled();
    if (mounted) setState(() => _on = on);
  }

  Future<void> _change(bool next) async {
    setState(() => _busy = true);
    try {
      final gate = ref.read(paymentAuthGateProvider);
      if (!next) {
        // 끄는 것도 본인 확인 뒤에만. 확인 방법 자체가 없는 폰은 끌 수 있게 둔다.
        final result = await gate.confirm(
          reason: '결제 전 본인 확인을 끄려면 본인 확인이 필요해요.',
          ignoreSetting: true,
        );
        if (result != PaymentAuthResult.approved &&
            result != PaymentAuthResult.unavailable) {
          _say(paymentAuthMessage(result));
          return;
        }
      }
      await gate.setEnabled(next);
      if (mounted) setState(() => _on = next);
    } catch (_) {
      _say('설정을 바꾸지 못했어요. 잠시 후 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(
        Icons.fingerprint,
        color: AppColors.tealAccent,
      ),
      title: Text(
        '결제 전 본인 확인',
        style: AppTextStyles.agreementLabel.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: const Text(
        '다이아 구매와 Coach+ 결제창을 열기 전에 지문이나 화면 잠금으로 확인해요. '
        '결제 승인은 구글 플레이가 하고, 이 확인은 한 번 더 걸러 주는 단계예요.',
        style: AppTextStyles.caption,
      ),
      trailing: Switch(
        key: PaymentAuthTile.switchKey,
        value: _on,
        onChanged: _busy ? null : _change,
      ),
    );
  }
}
