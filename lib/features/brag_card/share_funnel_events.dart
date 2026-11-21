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
  success('success'),
  dismissed('dismissed'),
  unavailable('unavailable'),
  failed('failed');

  const BragShareStatus(this.wireName);
  final String wireName;

  /// `ShareResult.status` from share_plus. Some platforms always answer
  /// `unavailable`, so this is a best effort, not proof of a post.
  static BragShareStatus fromShareResult(ShareResultStatus status) {
    return switch (status) {
      ShareResultStatus.success => BragShareStatus.success,
      ShareResultStatus.dismissed => BragShareStatus.dismissed,
      ShareResultStatus.unavailable => BragShareStatus.unavailable,
    };
  }
}

/// The four brag-card funnel events. Nothing here carries a person: no uid,
/// nickname, invite code, device id or advertising id.
///
/// Call order for one share: shown → qrIncluded (when the picture is made)
/// → shareTapped (when a target is opened) → shareResult.
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
