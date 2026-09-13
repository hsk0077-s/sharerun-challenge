import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// Walking Challenge OS share sheet — Korean promo text only.
///
/// Kakao / SMS / Telegram appear through the system sheet (`ACTION_SEND` /
/// `UIActivityViewController`). No Kakao Share SDK. Brag cards are later.
abstract final class WalkingChallengeShare {
  static const buttonKey = Key('walking-system-share');
  static const buttonTooltip = '공유';
  static const subject = 'SRC 워킹챌린지';

  static const promoText =
      'SRC 워킹챌린지에서 함께 걷고 SHARE를 모아보세요!\n'
      '걸을수록 쌓이는 SHARE, 친구와 같이 시작해요.\n'
      '#SRC #워킹챌린지 #ShareRunChallenge';

  /// Test hook. Production always uses [SharePlus.instance].
  @visibleForTesting
  static Future<ShareResult> Function(ShareParams params)? debugShareOverride;

  static Future<ShareResult> openSystemSheet({
    Rect? sharePositionOrigin,
  }) {
    final params = ShareParams(
      text: promoText,
      subject: subject,
      title: subject,
      sharePositionOrigin: sharePositionOrigin,
    );
    final send = debugShareOverride ?? SharePlus.instance.share;
    return send(params);
  }

  static Rect? originFrom(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}
