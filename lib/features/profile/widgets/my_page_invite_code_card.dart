import 'dart:async' show unawaited;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/social_brand_icons.dart';
import '../../pedometer/walking_challenge_share.dart';

/// Play Store listing. Package id is `applicationId` in
/// `android/app/build.gradle.kts`.
const myPageInvitePlayStoreUrl =
    'https://play.google.com/store/apps/details?id=com.sharerun.share_run_challenge';

/// Short invite body. No reward amounts — payout copy is a later step.
String myPageInviteShareText(String code) {
  return '쉐어런에 초대해요!\n'
      '초대 코드: $code\n'
      '$myPageInvitePlayStoreUrl';
}

/// Loads the signed-in user's stable invite code.
///
/// Widget tests override this. Without Firebase the loader fails immediately
/// so My Page never paints a placeholder code.
final myPageInviteCodeLoaderProvider =
    Provider<Future<String> Function()>((ref) {
  if (Firebase.apps.isEmpty) {
    return () => Future<String>.error(
          StateError('Firebase is not initialized.'),
        );
  }
  return ref.watch(securedActionApiClientProvider).getOrCreateInviteCode;
});

/// My Page card: the user's invite code, copy, and Kakao invite.
class MyPageInviteCodeCard extends ConsumerStatefulWidget {
  const MyPageInviteCodeCard({super.key});

  static const cardKey = Key('my-page-invite-card');
  static const loadingKey = Key('my-page-invite-loading');
  static const codeKey = Key('my-page-invite-code');
  static const copyKey = Key('my-page-invite-copy');
  static const retryKey = Key('my-page-invite-retry');
  static const kakaoKey = Key('my-page-invite-kakao');

  static const title = '내 초대 코드';
  static const copyLabel = '복사';
  static const copiedMessage = '복사했어요';
  static const loadFailedMessage = '초대 코드를 불러오지 못했어요. 다시 시도';
  static const kakaoButtonLabel = '카카오톡으로 초대하기';
  static const shareSubject = '쉐어런 초대';

  @override
  ConsumerState<MyPageInviteCodeCard> createState() =>
      _MyPageInviteCodeCardState();
}

class _MyPageInviteCodeCardState extends ConsumerState<MyPageInviteCodeCard> {
  var _loading = true;
  var _failed = false;
  String? _code;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_load());
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final code = await ref.read(myPageInviteCodeLoaderProvider)();
      if (code.trim().isEmpty) {
        throw StateError('Invite code missing from server response.');
      }
      if (!mounted) return;
      setState(() {
        _code = code;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _code = null;
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _copy() async {
    final code = _code;
    if (code == null) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(MyPageInviteCodeCard.copiedMessage)),
    );
  }

  Future<void> _shareInvite(BuildContext buttonContext) async {
    final code = _code;
    if (code == null) return;
    try {
      await WalkingChallengeShare.openChooser(
        buttonContext,
        text: myPageInviteShareText(code),
        subject: MyPageInviteCodeCard.shareSubject,
        sharePositionOrigin: WalkingChallengeShare.originFrom(buttonContext),
      );
    } catch (e, st) {
      debugPrint('MyPageInviteCodeCard.share: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    final code = _code;

    return SrcSurfaceCard(
      key: MyPageInviteCodeCard.cardKey,
      padding: EdgeInsets.all(tokens.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            MyPageInviteCodeCard.title,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: tokens.colors.ink,
            ),
          ),
          SizedBox(height: tokens.spacing.sm),
          if (_loading)
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                key: MyPageInviteCodeCard.loadingKey,
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: tokens.colors.primary,
                ),
              ),
            )
          else if (_failed || code == null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: MyPageInviteCodeCard.retryKey,
                onPressed: () => unawaited(_load()),
                style: TextButton.styleFrom(
                  foregroundColor: tokens.colors.accent,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(MyPageInviteCodeCard.loadFailedMessage),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: Text(
                    code,
                    key: MyPageInviteCodeCard.codeKey,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: tokens.colors.ink,
                    ),
                  ),
                ),
                TextButton(
                  key: MyPageInviteCodeCard.copyKey,
                  onPressed: () => unawaited(_copy()),
                  style: TextButton.styleFrom(
                    foregroundColor: tokens.colors.accent,
                  ),
                  child: const Text(MyPageInviteCodeCard.copyLabel),
                ),
              ],
            ),
          SizedBox(height: tokens.spacing.sm),
          Builder(
            builder: (buttonContext) {
              return FilledButton.icon(
                key: MyPageInviteCodeCard.kakaoKey,
                onPressed: code == null
                    ? null
                    : () => unawaited(_shareInvite(buttonContext)),
                icon: const KakaoIcon(size: 18),
                label: const Text(MyPageInviteCodeCard.kakaoButtonLabel),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.kakaoYellow,
                  foregroundColor: AppColors.textBlack,
                  disabledBackgroundColor:
                      AppColors.kakaoYellow.withValues(alpha: 0.45),
                  disabledForegroundColor:
                      AppColors.textBlack.withValues(alpha: 0.45),
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: tokens.radii.capsule,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
