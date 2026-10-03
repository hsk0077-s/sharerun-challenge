import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_exception.dart';
import '../core/navigation/app_route_nav.dart';
import '../core/theme/app_colors.dart';
import '../data/models/share_to_dia_view.dart';
import '../features/wallet/providers/wallet_provider.dart';
import '../features/wallet/share_to_dia_actions.dart';

/// SHARE → DIA. Reached from the wallet charge DIA option.
class ShareDiaExchangeScreen extends ConsumerStatefulWidget {
  const ShareDiaExchangeScreen({super.key});

  @override
  ConsumerState<ShareDiaExchangeScreen> createState() =>
      _ShareDiaExchangeScreenState();
}

class _ShareDiaExchangeScreenState extends ConsumerState<ShareDiaExchangeScreen> {
  ShareToDiaView? _quote;
  var _loading = true;
  var _exchanging = false;
  var _dia = 10;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final quote = await ref.read(shareToDiaQuoteProvider)();
      if (!mounted) return;
      setState(() {
        _quote = quote;
        _dia = quote.unitDia;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = ApiErrorMessage.from(error);
      });
    }
  }

  Future<void> _exchange() async {
    final quote = _quote;
    if (quote == null || _exchanging || !quote.canExchange) return;
    setState(() => _exchanging = true);
    try {
      final result = await ref.read(shareToDiaExchangeProvider)(_dia);
      if (!mounted) return;
      ref.read(walletProvider.notifier).applyWalletSnapshot(
            shareBalance: result.shareBalance,
            diamondBalance: result.diamondBalance,
            valueBalance: result.valueTokenBalance,
          );
      setState(() {
        _quote = result;
        _dia = result.remainingDia >= result.unitDia
            ? result.unitDia
            : result.remainingDia;
        _exchanging = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${result.rateSharePerDia} SHARE = 1 DIA 교환이 반영되었습니다.')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _exchanging = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.detail)),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _exchanging = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiErrorMessage.from(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final quote = _quote;
    final locked = quote == null || !quote.canExchange;
    return Scaffold(
      backgroundColor: AppColors.bgGradientEnd,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('SHARE → DIA 교환'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => AppRouteNav.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: AppColors.error)),
                if (quote != null) ...[
                  Text(
                    '${quote.rateSharePerDia} SHARE = 1 DIA',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text('이번 주 남은 한도 ${quote.remainingDia} / ${quote.weeklyCapDia} DIA'),
                  const SizedBox(height: 4),
                  Text('${quote.unitDia} DIA 단위 · 교환 가능 SHARE ${quote.spendableShare}'),
                  if (quote.lockedShare > 0) ...[
                    const SizedBox(height: 4),
                    Text('추천 보상 잠금 ${quote.lockedShare} SHARE'),
                  ],
                  if (quote.lockReason != null && quote.lockReason!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      quote.lockReason!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      IconButton(
                        onPressed: locked || _dia <= quote.unitDia
                            ? null
                            : () => setState(() => _dia -= quote.unitDia),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('$_dia DIA', style: const TextStyle(fontWeight: FontWeight.w800)),
                      IconButton(
                        onPressed: locked || _dia + quote.unitDia > quote.remainingDia
                            ? null
                            : () => setState(() => _dia += quote.unitDia),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: locked || _exchanging ? null : _exchange,
                    child: Text(_exchanging ? '교환 중...' : '교환'),
                  ),
                ],
              ],
            ),
    );
  }
}
