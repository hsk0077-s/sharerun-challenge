import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Which brag card the event is about.
enum BragSurface {
  runFinish('run_finish'),
  worldTour('world_tour');

  const BragSurface(this.wireName);
  final String wireName;
}

/// How a share ended, as far as the platform tells us.
enum BragShareStatus {
  /// 공유창에서 사용자가 앱을 골랐다(share_plus `success`).
  /// 실제로 올라갔다는 뜻은 아니다.
  appChosen('app_chosen'),

  /// 공유창을 그냥 닫았다.
  dismissed('dismissed'),

  /// 플랫폼이 결과를 알려주지 않는다(share_plus `unavailable`).
  unknown('unknown'),

  /// 직접 공유 버튼(인스타 스토리·틱톡 등)이 그 앱을 여는 데 성공했다.
  /// 그 뒤 실제로 올렸는지는 모른다.
  handedOff('handed_off'),

  /// 그림을 만들지 못했거나, 앱이 없거나, 예외가 났다.
  failed('failed');

  const BragShareStatus(this.wireName);
  final String wireName;

  /// `ShareResult.status` from share_plus. Only the status is used; the
  /// `raw` text (chosen app package) is never recorded.
  static BragShareStatus fromShareResult(ShareResultStatus status) {
    return switch (status) {
      ShareResultStatus.success => BragShareStatus.appChosen,
      ShareResultStatus.dismissed => BragShareStatus.dismissed,
      ShareResultStatus.unavailable => BragShareStatus.unknown,
    };
  }
}

/// The four brag-card funnel events. Nothing here carries a person: no uid,
/// nickname, invite code, device id or advertising id.
///
/// Call order for one share: shown → qrIncluded → shareTapped → (the picture
/// is made) → shareResult. `target` is our own id (story, kakao, more ...),
/// never an app package name.
abstract interface class ShareFunnelEvents {
  /// `brag_card_shown {surface}`
  void cardShown(BragSurface surface);

  /// `brag_share_tapped {surface, target}`
  void shareTapped(BragSurface surface, String target);

  /// `brag_share_result {surface, target, status}`
  void shareResult(BragSurface surface, String target, BragShareStatus status);

  /// `brag_qr_included {surface, included}`
  void qrIncluded(BragSurface surface, {required bool included});
}

/// Default: sends nothing, stores nothing. Debug builds print one line.
///
/// A real sender (Firebase Analytics, server, Firestore, local storage) needs
/// the owner's consent review plus Play Data safety and privacy policy changes
/// first. See docs/brag-card-v1.md.
class NoopShareFunnelEvents implements ShareFunnelEvents {
  const NoopShareFunnelEvents();

  void _log(String line) {
    if (kDebugMode) debugPrint('[share-funnel] $line');
  }

  @override
  void cardShown(BragSurface surface) =>
      _log('brag_card_shown surface=${surface.wireName}');

  @override
  void shareTapped(BragSurface surface, String target) => _log(
      'brag_share_tapped surface=${surface.wireName} target=$target');

  @override
  void shareResult(
          BragSurface surface, String target, BragShareStatus status) =>
      _log('brag_share_result surface=${surface.wireName} target=$target '
          'status=${status.wireName}');

  @override
  void qrIncluded(BragSurface surface, {required bool included}) => _log(
      'brag_qr_included surface=${surface.wireName} included=$included');
}

/// Widget tests override this with a recording fake.
final shareFunnelEventsProvider = Provider<ShareFunnelEvents>(
  (ref) => const NoopShareFunnelEvents(),
);
