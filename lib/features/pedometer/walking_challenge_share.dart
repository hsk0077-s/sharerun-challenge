import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart';
import 'package:share_plus/share_plus.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/core/widgets/social_brand_icons.dart';

import '../../core/constants/store_links.dart';
import '../../l10n/remaining_surface.dart';
import '../run_result/run_finish_image_share.dart';
import '../run_result/run_finish_share_card.dart';
import 'pedometer_harvest_ledger.dart';
import 'walking_goal_share_card.dart';
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
  static String get buttonTooltip => RemainingSurface.trNow(
        'pedometer.walking_challenge_share.body',
        '공유',
      );
  static String get subject => RemainingSurface.trNow(
        'pedometer.walking_challenge_share.body.2',
        '쉐어런 워킹챌린지',
      );

  static const kakaoChoiceKey = Key('share-kakao-talk');
  static const systemChoiceKey = Key('share-other-apps');
  static String get kakaoChoiceLabel => RemainingSurface.trNow(
        'pedometer.walking_challenge_share.body.3',
        '카카오톡',
      );
  static String get otherAppsChoiceLabel => RemainingSurface.trNow(
        'pedometer.walking_challenge_share.body.4',
        '다른 앱으로 공유',
      );
  static String get kakaoShareFailedMessage => RemainingSurface.trNow(
        'pedometer.walking_challenge_share.body.5',
        '카카오톡으로 공유하지 못했어요.',
      );

  /// Kakao text templates reject bodies longer than this.
  static const kakaoTextLimit = 200;

  static String get promoText =>
      '${RemainingSurface.trNow('pedometer.walking_challenge_share.promo_line1', '쉐어런 워킹챌린지에서 함께 걷고 SHARE를 모아보세요!')}\n'
      '${RemainingSurface.trNow('pedometer.walking_challenge_share.promo_line2', '걸을수록 쌓이는 SHARE, 친구와 같이 시작해요.')}\n'
      '${RemainingSurface.trNow('pedometer.walking_challenge_share.body.7', '#쉐어런 #워킹챌린지 #ShareRun')}';

  static const dailyGoalBragKey = Key('walking-daily-goal-brag');
  static String get dailyGoalBragButtonLabel => RemainingSurface.trNow(
        'pedometer.walking_challenge_share.body.8',
        '자랑하기',
      );
  static String get dailyGoalBragSubject => RemainingSurface.trNow(
        'pedometer.walking_challenge_share.body.9',
        '쉐어런 오늘의 목표 달성',
      );

  static String get dailyGoalBragText =>
      '${RemainingSurface.trNow('pedometer.walking_challenge_share.goal_brag_text', '오늘의 목표 달성! 🎉\n쉐어런 워킹챌린지에서 오늘 하루 목표를 채웠어요.\n걷고 SHARE 모으고, 내일도 같이 걸어요!')}\n'
      '${RemainingSurface.trNow('pedometer.walking_challenge_share.goal_brag_tags', '#쉐어런 #워킹챌린지 #오늘의목표달성')}\n'
      '$kPlayStoreUrl';

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

    final choice = await _askRoute(context);
    if (!context.mounted || choice == null) return;
    switch (choice) {
      case _ShareRoute.kakao:
        final status = await shareToKakao(text: text);
        if (status == KakaoDirectShareStatus.failed && context.mounted) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(content: Text(kakaoShareFailedMessage)),
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

  static Future<_ShareRoute?> _askRoute(BuildContext context) {
    return showModalBottomSheet<_ShareRoute>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                key: kakaoChoiceKey,
                leading: const KakaoIcon(size: 22),
                title: Text(kakaoChoiceLabel),
                onTap: () => Navigator.pop(sheetContext, _ShareRoute.kakao),
              ),
              ListTile(
                key: systemChoiceKey,
                leading: const Icon(Icons.ios_share),
                title: Text(otherAppsChoiceLabel),
                onTap: () => Navigator.pop(sheetContext, _ShareRoute.system),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Image + text share. KakaoTalk when installed (the card file with the
  /// sentence and link as `EXTRA_TEXT`), otherwise the system sheet with
  /// `ShareParams(files, text)`. Falls back to the sheet when KakaoTalk
  /// refuses the file.
  static Future<void> openImageChooser(
    BuildContext context, {
    required File image,
    required String text,
    String? subject,
    Rect? sharePositionOrigin,
  }) async {
    final kakaoInstalled = await isKakaoTalkInstalled();
    if (!context.mounted) return;
    var route = _ShareRoute.system;
    if (kakaoInstalled) {
      final choice = await _askRoute(context);
      if (!context.mounted || choice == null) return;
      route = choice;
    }
    if (route == _ShareRoute.kakao) {
      final sent = await RunFinishImageShare.shareTarget(
        id: 'kakao',
        path: image.path,
        text: text,
      );
      if (sent) return;
    }
    await openSystemSheetWithImage(
      image: image,
      text: text,
      subject: subject,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  static Future<ShareResult> openSystemSheetWithImage({
    required File image,
    required String text,
    String? subject,
    Rect? sharePositionOrigin,
  }) {
    final resolvedSubject = subject ?? WalkingChallengeShare.subject;
    final params = ShareParams(
      files: [
        XFile(image.path, mimeType: 'image/png', name: 'share_run_goal.png'),
      ],
      text: text,
      subject: resolvedSubject,
      title: resolvedSubject,
      sharePositionOrigin: sharePositionOrigin,
    );
    final send = debugShareOverride ?? SharePlus.instance.share;
    return send(params);
  }

  static String _textForKakao(String text) {
    if (text.length <= kakaoTextLimit) return text;
    // Cut the sentence, never the store link at the end.
    final lines = text.split('\n');
    final link = lines.isNotEmpty && lines.last.startsWith('http')
        ? lines.removeLast()
        : '';
    final head = lines.join('\n');
    final room = kakaoTextLimit - (link.isEmpty ? 0 : link.length + 1) - 1;
    final cut = room <= 0
        ? ''
        : '${head.substring(0, head.length < room ? head.length : room)}…';
    return link.isEmpty ? cut : '$cut\n$link';
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

/// Walking "오늘의 목표 달성!" dock + 자랑하기. With [steps] it shares the image card
/// and the brag text with the store link; without, text only.
class WalkingDailyGoalCompleteCard extends StatefulWidget {
  const WalkingDailyGoalCompleteCard({
    super.key,
    this.steps,
    this.goalSteps = PedometerHarvestLedger.stepsForDailyCap,
    this.badges,
    this.now,
  });

  static const cardKey = Key('walking-goal-complete');

  /// Today's step count from the walking screen. Null keeps the old text-only
  /// brag (no image), e.g. where the screen has no step value to show.
  final int? steps;

  /// Step goal printed on the image card. The dock appears when the daily
  /// SHARE cap is reached, which is [PedometerHarvestLedger.stepsForDailyCap].
  final int goalSteps;

  /// 동물 티어·천사 등급 원. 아직 등급이 없으면 비워 둔다.
  final RunFinishTierBadges? badges;

  /// Test hook for the date printed on the card.
  final DateTime Function()? now;

  /// Off-screen capture boundary of the image card.
  static const captureKey = Key('walking-goal-capture');

  @override
  State<WalkingDailyGoalCompleteCard> createState() =>
      _WalkingDailyGoalCompleteCardState();
}

class _WalkingDailyGoalCompleteCardState
    extends State<WalkingDailyGoalCompleteCard> {
  final _captureBoundaryKey = GlobalKey();
  var _sharing = false;

  Future<void> _share(BuildContext buttonContext) async {
    if (_sharing) return;
    final steps = widget.steps;
    if (steps == null) {
      await _shareDailyGoalBrag(buttonContext);
      return;
    }
    setState(() => _sharing = true);
    try {
      File image;
      try {
        image = await RunFinishImageShare.capture(_captureBoundaryKey);
      } catch (e, st) {
        // No image, still a share: the sentence and link go out as text.
        debugPrint('WalkingChallengeShare.goalCardCapture: $e\n$st');
        if (buttonContext.mounted) await _shareDailyGoalBrag(buttonContext);
        return;
      }
      if (!buttonContext.mounted) return;
      await WalkingChallengeShare.openImageChooser(
        buttonContext,
        image: image,
        text: WalkingChallengeShare.dailyGoalBragText,
        subject: WalkingChallengeShare.dailyGoalBragSubject,
        sharePositionOrigin: WalkingChallengeShare.originFrom(buttonContext),
      );
    } catch (e, st) {
      debugPrint('WalkingChallengeShare.dailyGoalBragImage: $e\n$st');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.steps;
    final card = _buildCard(context);
    if (steps == null) return card;
    // Full 1080×1350 card for export. The stack does not clip a zero-size
    // child, so it is shifted out of view; toImage reads the boundary before
    // the shift, at pixelRatio 1 (same trick as the run finish poster).
    return Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        card,
        Positioned(
          left: 0,
          top: 0,
          width: 0,
          height: 0,
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: WalkingGoalShareCard.canvasWidth,
                maxWidth: WalkingGoalShareCard.canvasWidth,
                minHeight: WalkingGoalShareCard.canvasHeight,
                maxHeight: WalkingGoalShareCard.canvasHeight,
                child: Transform.translate(
                  offset: const Offset(
                    -(WalkingGoalShareCard.canvasWidth + 8),
                    -(WalkingGoalShareCard.canvasHeight + 8),
                  ),
                  child: RepaintBoundary(
                    key: _captureBoundaryKey,
                    child: WalkingGoalShareCard(
                      key: WalkingDailyGoalCompleteCard.captureKey,
                      steps: steps,
                      goalSteps: widget.goalSteps,
                      date: (widget.now ?? DateTime.now)(),
                      badges: widget.badges,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      key: WalkingDailyGoalCompleteCard.cardKey,
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
            RemainingSurface.tr(
              context,
              'pedometer.walking_challenge_share.body.12',
              '오늘의 목표 달성!',
            ),
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: WalkingLook.onHero,
            ),
          ),
          SizedBox(height: tokens.spacing.xxs),
          Text(
            RemainingSurface.tr(
              context,
              'pedometer.walking_challenge_share.body.13',
              '오늘 하루도 열심히 달리셨네요.\n고생하셨습니다. 내일 다시 걸어보죠! 🏃‍♂️✨',
            ),
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
                  onPressed:
                      _sharing ? null : () => unawaited(_share(buttonContext)),
                  icon: const Icon(Icons.ios_share, size: 18),
                  label: Text(
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
