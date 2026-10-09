import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/strings/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../data/models/wallet_transaction_model.dart';
import '../features/wallet/providers/wallet_history_provider.dart';
import 'my_wallet_screen.dart';

/// 내 거래 내역. 서버 원장(`walletTransactions`)을 최신순으로 읽어 보여 준다.
/// 앱은 아무것도 계산하거나 쓰지 않고, 원장에 있는 행만 보여 준다.
class WalletHistoryScreen extends ConsumerStatefulWidget {
  const WalletHistoryScreen({super.key});

  static const moreButtonKey = Key('wallet-history-more');
  static const retryButtonKey = Key('wallet-history-retry');

  @override
  ConsumerState<WalletHistoryScreen> createState() =>
      _WalletHistoryScreenState();
}

class _WalletHistoryScreenState extends ConsumerState<WalletHistoryScreen> {
  final List<WalletTransactionModel> _rows = [];
  Object? _cursor;
  bool _hasMore = false;
  bool _loading = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final page = await ref.read(walletHistoryLoaderProvider)(cursor: _cursor);
      if (!mounted) return;
      setState(() {
        _rows.addAll(page.rows);
        _cursor = page.cursor ?? _cursor;
        _hasMore = page.hasMore;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  static String _date(WalletTransactionModel row) {
    final at = row.createdAt?.toLocal();
    if (at == null) return AppStrings.notificationPaymentJustNow;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${at.year}-${two(at.month)}-${two(at.day)} ${two(at.hour)}:${two(at.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.settingsBackground,
      appBar: AppBar(
        backgroundColor: AppColors.settingsBackground,
        elevation: 0,
        foregroundColor: AppColors.textBlack,
        title: Text(
          '내 거래 내역',
          style: AppTextStyles.header1.copyWith(fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            '서버 원장에 기록된 내역이에요. 한 번 기록된 내역은 지워지지 않아요.',
            style: AppTextStyles.caption.copyWith(color: AppColors.textGrey),
          ),
          const SizedBox(height: 14),
          if (_rows.isEmpty && _loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_rows.isEmpty && _failed)
            _Retry(onRetry: _load)
          else if (_rows.isEmpty)
            Text(
              AppStrings.notificationPaymentEmpty,
              style: AppTextStyles.caption.copyWith(color: AppColors.textGrey),
            )
          else ...[
            for (final row in _rows) ...[
              WalletTransactionCard(
                title: row.displayLabel,
                date: _date(row),
                amount: row.amountSummary,
                status: AppStrings.notificationPaymentReceipt,
                leading: Icons.receipt_long_outlined,
              ),
              const SizedBox(height: 10),
            ],
            if (_failed) _Retry(onRetry: _load),
            if (_hasMore && !_failed)
              Center(
                child: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : OutlinedButton(
                        key: WalletHistoryScreen.moreButtonKey,
                        onPressed: _load,
                        child: const Text('더 보기'),
                      ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Retry extends StatelessWidget {
  const _Retry({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '내역을 불러오지 못했어요. 잠시 뒤 다시 시도해 주세요.',
          style: AppTextStyles.caption.copyWith(color: AppColors.textGrey),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          key: WalletHistoryScreen.retryButtonKey,
          onPressed: onRetry,
          child: const Text('다시 시도'),
        ),
      ],
    );
  }
}
