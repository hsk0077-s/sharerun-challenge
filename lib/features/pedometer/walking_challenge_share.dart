import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart';
import 'package:share_plus/share_plus.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/core/widgets/social_brand_icons.dart';

import 'walking_look.dart';

/// Outcome of a direct KakaoTalk share. The system sheet is a separate path.
enum KakaoDirectShareStatus { sent, notInstalled, failed }

/// Walking Challenge share — OS sheet, plus KakaoTalk when it is installed.
///
/// [openSystemSheet] is unchanged (`share_plus`). [shareToKakao] uses Kakao's
/// default text template with the app key already passed to [KakaoSdk.init].
/// No custom template id. Rich feed cards need a Kakao console template later.
abstract final class WalkingChallengeShare {
  static const buttonKey = Key('walking-system-share');
  static const buttonTooltip = '공유';
  static const subject = 'SRC 워킹챌린지';

  static const kakaoChoiceKey = Key('share-kakao-talk');
  static const systemChoiceKey = Key('share-other-apps');
  static const kakaoChoiceLabel = '카카오톡';
  static const otherAppsChoiceLabel = '다른 앱으로 공유';
  static const kakaoShareFailedMessage = '카카오톡으로 공유하지 못했어요.';

  /// Kakao text templates reject bodies longer than this.
  static const kakaoTextLimit = 200;

  static const promoText = 'SRC 워킹챌린지에서 함께 걷고 SHARE를 모아보세요!\n'
      '걸을수록 쌓이는 SHARE, 친구와 같이 시작해요.\n'
      '#SRC #워킹챌린지 #ShareRunChallenge';

  static const dailyGoalBragKey = Key('walking-daily-goal-brag');
  static const dailyGoalBragButtonLabel = '자랑하기';
  static const dailyGoalBragSubject = 'SRC 오늘의 목표 달성';

  static const dailyGoalBragText = '오늘의 목표 달성! 🎉\n'
      'SRC 워킹챌린지에서 오늘 하루 목표를 채웠어요.\n'
      '걷고 SHARE 모으고, 내일도 같이 걸어요!\n'
      '#SRC #워킹챌린지 #오늘의목표달성';

  /// Test hook. Production always uses [SharePlus.instance].
  @visibleForTesting
  static Future<ShareResult> Function(ShareParams params)? debugShareOverride;

  /// Test hook. Null uses [ShareClient.isKakaoTalkSharingAvailable].
  @visibleForTesting
  static Future<bool> Function()? debugKakaoInstalledOverride;

  /// Test hook. Null uses [ShareClient.shareDefault] with a text template.
  @visibleForTesting
  static Future<void> Function(String text)? debugKakaoShareOverride;

  static Future<ShareResult> openSystemSheet({
    Rect? sharePositionOrigin,
    String? text,
    String? subject,
  }) {
    final resolvedSubject = subject ?? WalkingChallengeShare.subject;
    final params = ShareParams(
      text: text ?? promoText,
      subject: resolvedSubject,
      title: resolvedSubject,
      sharePositionOrigin: sharePositionOrigin,
    );
    final send = debugShareOverride ?? SharePlus.instance.share;
    return send(params);
  }

  /// Daily-goal brag — same OS sheet as the header, different Korean copy.
  static Future<ShareResult> openDailyGoalBrag({
    Rect? sharePositionOrigin,
  }) {
    return openSystemSheet(
      sharePositionOrigin: sharePositionOrigin,
      text: dailyGoalBragText,
      subject: dailyGoalBragSubject,
    );
  }

  static Rect? originFrom(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  static Future<bool> isKakaoTalkInstalled() async {
    final override = debugKakaoInstalledOverride;
    if (override != null) return override();
    try {
      return await ShareClient.instance.isKakaoTalkSharingAvailable();
    } catch (e, st) {
      debugPrint('WalkingChallengeShare.isKakaoTalkInstalled: $e\n$st');
      return false;
    }
  }

  /// Direct KakaoTalk share of [text] (promo text when omitted).
  ///
  /// Hidden from the chooser when KakaoTalk is not installed. Does not open
  /// the system sheet.
  static Future<KakaoDirectShareStatus> shareToKakao({String? text}) async {
    if (!await isKakaoTalkInstalled()) {
      return KakaoDirectShareStatus.notInstalled;
    }
    final resolved = _textForKakao(text ?? promoText);
    final send = debugKakaoShareOverride ?? _shareKakaoTextTemplate;
    try {
      await send(resolved);
      return KakaoDirectShareStatus.sent;
    } catch (e, st) {
      debugPrint('WalkingChallengeShare.shareToKakao: $e\n$st');
      return KakaoDirectShareStatus.failed;
    }
  }

  /// KakaoTalk when installed, otherwise the system sheet directly.
  static Future<void> openChooser(
    BuildContext context, {
    Rect? sharePositionOrigin,
    String? text,
    String? subject,
  }) async {
    final kakaoInstalled = await isKakaoTalkInstalled();
    if (!context.mounted) return;
    if (!kakaoInstalled) {
      await openSystemSheet(
        sharePositionOrigin: sharePositionOrigin,
        text: text,
        subject: subject,
      );
      return;
    }

    final choice = await showModalBottomSheet<_ShareRoute>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                key: kakaoChoiceKey,
                leading: const KakaoIcon(size: 22),
                title: const Text(kakaoChoiceLabel),
                onTap: () => Navigator.pop(sheetContext, _ShareRoute.kakao),
              ),
              ListTile(
                key: systemChoiceKey,
                leading: const Icon(Icons.ios_share),
                title: const Text(otherAppsChoiceLabel),
                onTap: () => Navigator.pop(sheetContext, _ShareRoute.system),
              ),
            ],
          ),
        );
      },
    );
    if (!context.mounted || choice == null) return;
    switch (choice) {
      case _ShareRoute.kakao:
        final status = await shareToKakao(text: text);
        if (status == KakaoDirectShareStatus.failed && context.mounted) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            const SnackBar(content: Text(kakaoShareFailedMessage)),
          );
        }
      case _ShareRoute.system:
        await openSystemSheet(
          sharePositionOrigin: sharePositionOrigin,
          text: text,
          subject: subject,
        );
    }
  }

  static String _textForKakao(String text) {
    if (text.length <= kakaoTextLimit) return text;
    return '${text.substring(0, kakaoTextLimit - 1)}…';
  }

  /// Default text template. App-execution params avoid a web domain this
  /// repo does not register. A console template id is only needed for rich cards.
  static Future<void> _shareKakaoTextTemplate(String text) {
    return ShareClient.instance.shareDefault(
      template: TextTemplate(
        text: text,
        link: Link(
          androidExecutionParams: const {'src': 'share'},
          iosExecutionParams: const {'src': 'share'},
        ),
      ),
    );
  }
}

enum _ShareRoute { kakao, system }

/// Existing walking "오늘의 목표 달성!" dock + 자랑하기. Text share only.
class WalkingDailyGoalCompleteCard extends StatelessWidget {
  const WalkingDailyGoalCompleteCard({super.key});

  static const cardKey = Key('walking-goal-complete');

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      key: cardKey,
      padding: EdgeInsets.all(tokens.spacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [WalkingLook.heroMid, WalkingLook.heroLift],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: tokens.radii.panel,
        boxShadow: WalkingLook.glassLift,
      ),
      child: Column(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 36)),
          SizedBox(height: tokens.spacing.xs),
          Text(
            '오늘의 목표 달성!',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: WalkingLook.onHero,
            ),
          ),
          SizedBox(height: tokens.spacing.xxs),
          Text(
            '오늘 하루도 열심히 달리셨네요.\n고생하셨습니다. 내일 다시 걸어보죠! 🏃‍♂️✨',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: WalkingLook.onHero,
              height: 1.45,
            ),
          ),
          SizedBox(height: tokens.spacing.md),
          Builder(
            builder: (buttonContext) {
              return SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: WalkingChallengeShare.dailyGoalBragKey,
                  onPressed: () =>
                      unawaited(_shareDailyGoalBrag(buttonContext)),
                  icon: const Icon(Icons.ios_share, size: 18),
                  label: const Text(
                    WalkingChallengeShare.dailyGoalBragButtonLabel,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: WalkingLook.onHero,
                    foregroundColor: WalkingLook.heroMid,
                    disabledBackgroundColor: WalkingLook.onHero,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: tokens.radii.capsule,
                    ),
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

Future<void> _shareDailyGoalBrag(BuildContext buttonContext) async {
  try {
    await WalkingChallengeShare.openChooser(
      buttonContext,
      sharePositionOrigin: WalkingChallengeShare.originFrom(buttonContext),
      text: WalkingChallengeShare.dailyGoalBragText,
      subject: WalkingChallengeShare.dailyGoalBragSubject,
    );
  } catch (e, st) {
    debugPrint('WalkingChallengeShare.dailyGoalBrag: $e\n$st');
  }
}
