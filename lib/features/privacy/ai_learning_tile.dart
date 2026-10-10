import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// 서버에 저장된 "AI 학습 사용" 값. 기본은 끔이다.
final aiLearningProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(securedActionApiClientProvider).fetchAiLearning(),
  // 실패하면 계속 돌지 말고 바로 "다시 불러오기"를 보여준다.
  retry: (_, __) => null,
);

/// 값을 서버에 저장하고, 서버가 돌려준 값을 돌려준다.
final aiLearningSaverProvider = Provider<Future<bool> Function(bool)>(
  (ref) => ref.watch(securedActionApiClientProvider).setAiLearning,
);

class AiLearningTile extends ConsumerStatefulWidget {
  const AiLearningTile({super.key});

  static const switchKey = Key('ai-learning-switch');
  static const retryKey = Key('ai-learning-retry');

  @override
  ConsumerState<AiLearningTile> createState() => _AiLearningTileState();
}

class _AiLearningTileState extends ConsumerState<AiLearningTile> {
  bool _saving = false;

  /// 저장 응답으로 서버가 돌려준 값. 없으면 처음 불러온 서버 값을 쓴다.
  bool? _confirmed;

  Future<void> _change(bool next) async {
    setState(() => _saving = true);
    try {
      final saved = await ref.read(aiLearningSaverProvider)(next);
      if (mounted) setState(() => _confirmed = saved);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장하지 못했어요. 잠시 후 다시 시도해 주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(aiLearningProvider);
    const spinner = SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
    final Widget trailing = _saving
        ? spinner // 서버가 확인할 때까지 기존 값을 그대로 두고 저장 중만 알린다.
        : value.when(
            data: (on) => Switch(
              key: AiLearningTile.switchKey,
              value: _confirmed ?? on,
              onChanged: _change,
            ),
            loading: () => spinner,
            error: (_, __) => TextButton(
              key: AiLearningTile.retryKey,
              onPressed: () {
                _confirmed = null;
                ref.invalidate(aiLearningProvider);
              },
              child: const Text('다시 불러오기'),
            ),
          );
    return ListTile(
      leading: const Icon(
        Icons.psychology_alt_outlined,
        color: AppColors.tealAccent,
      ),
      title: Text(
        'AI 개선에 내 데이터 사용',
        style: AppTextStyles.agreementLabel.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '기본은 꺼짐이에요. 켜고 끈 기록은 서버에 남고, 어느 폰에서나 같게 보여요.',
        style: AppTextStyles.caption,
      ),
      trailing: trailing,
    );
  }
}
