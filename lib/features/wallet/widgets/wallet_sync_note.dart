import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/theme.dart';
import '../providers/wallet_sync_provider.dart';

/// 서버 확인 전의 지갑 숫자임을 알리는 한 줄. 확인되면 아무것도 그리지 않는다.
class WalletSyncNote extends ConsumerWidget {
  const WalletSyncNote({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(walletServerConfirmedProvider)) return const SizedBox.shrink();
    final colors = context.srcTokens.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2, color: colors.muted),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppStrings.walletUnconfirmedNote,
              key: const Key('wallet-unconfirmed-note'),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colors.muted),
            ),
          ),
        ],
      ),
    );
  }
}
