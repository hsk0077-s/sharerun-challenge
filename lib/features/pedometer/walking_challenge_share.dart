import 'dart:async';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:share_run_challenge/core/theme/theme.dart';

import 'walking_look.dart';

/// Walking Challenge OS share sheet — Korean promo or daily-goal brag text.
///
/// Kakao / SMS / Telegram appear through the system sheet (`ACTION_SEND` /
/// `UIActivityViewController`). No Kakao Share SDK. Other brag surfaces
/// (race finish, PR, donation, tier-up, lobby, stamp, HoF) are later PRs.
abstract final class WalkingChallengeShare {
  static const buttonKey = Key('walking-system-share');
  static const buttonTooltip = '공유';
  static const subject = 'SRC 워킹챌린지';

  static const promoText =
      'SRC 워킹챌린지에서 함께 걷고 SHARE를 모아보세요!\n'
      '걸을수록 쌓이는 SHARE, 친구와 같이 시작해요.\n'
      '#SRC #워킹챌린지 #ShareRunChallenge';

  static const dailyGoalBragKey = Key('walking-daily-goal-brag');
  static const dailyGoalBragButtonLabel = '자랑하기';
  static const dailyGoalBragSubject = 'SRC 오늘의 목표 달성';

  static const dailyGoalBragText =
      '오늘의 목표 달성! 🎉\n'
      'SRC 워킹챌린지에서 오늘 하루 목표를 채웠어요.\n'
      '걷고 SHARE 모으고, 내일도 같이 걸어요!\n'
      '#SRC #워킹챌린지 #오늘의목표달성';

  /// Test hook. Production always uses [SharePlus.instance].
  @visibleForTesting
  static Future<ShareResult> Function(ShareParams params)? debugShareOverride;

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
}

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
                  onPressed: () => unawaited(_shareDailyGoalBrag(buttonContext)),
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
    await WalkingChallengeShare.openDailyGoalBrag(
      sharePositionOrigin: WalkingChallengeShare.originFrom(buttonContext),
    );
  } catch (e, st) {
    debugPrint('WalkingChallengeShare.dailyGoalBrag: $e\n$st');
  }
}
