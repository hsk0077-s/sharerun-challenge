import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../core/theme/theme.dart';
import '../../../l10n/remaining_surface.dart';
import '../../brag_card/brag_card_frame.dart';
import '../../brag_card/share_funnel_events.dart';
import '../../run_result/run_finish_image_share.dart';
import '../widgets/world_tour_widgets.dart';
import '../world_tour_format.dart';
import '../world_tour_landmarks.dart';
import '../world_tour_providers.dart';
import '../world_tour_run_end.dart';

/// The picture that is shared: "에펠탑 도착!". Drawn at 1080 x 1920 so the
/// captured image is a story-sized poster; the screen only scales it down.
class WorldTourArrivalPoster extends StatelessWidget {
  const WorldTourArrivalPoster({
    required this.landmark,
    required this.args,
    required this.avatar,
    super.key,
  });

  static const width = BragCardSpec.canvasWidth;
  static const height = BragCardSpec.canvasHeight;

  static const _ink = Color(0xFF101820);
  static const _muted = Color(0xFF55616B);

  final WorldTourLandmark landmark;
  final WorldTourArrivalArgs args;
  final Widget avatar;

  @override
  Widget build(BuildContext context) {
    final name = landmark.shortName(context);
    const ink = _ink;
    // 공유 그림이라 휴대폰 글자 크기 설정에 따라 달라지지 않게 고정한다.
    final media = MediaQuery.maybeOf(context) ?? const MediaQueryData();
    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.noScaling),
      child: DefaultTextStyle(
        style: const TextStyle(
          decoration: TextDecoration.none,
          fontFamily: BragCardSpec.fontFamily,
        ),
        child: SizedBox(
          width: width,
          height: height,
          child: DecoratedBox(
            // 캡처 PNG가 비치지 않게 불투명 한 색(흰 바탕 위 18%)으로 둔다.
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                landmark.color.withValues(alpha: 0.18),
                Colors.white,
              ),
            ),
            // Always carries the install QR. The tour card has no off switch.
            child: BragCardLayout(
              showQr: true,
              ink: const BragCardInk(
                title: _ink,
                caption: _muted,
                hairline: Color(0x33101820),
              ),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Art slot: landmark picture (WorldTourLandmarkArt).
                        WorldTourLandmarkArt(
                          landmark: landmark,
                          scene: WorldTourArtScene.poster,
                          height: double.infinity,
                          radius: 56,
                        ),
                        // Art slot: the runner's own avatar.
                        Positioned(
                          left: 48,
                          bottom: -90,
                          child:
                              SizedBox(width: 240, height: 240, child: avatar),
                        ),
                        Positioned(
                          right: 48,
                          bottom: -70,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 36, vertical: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Art slot: stamp mark (placeholder check icon).
                                const Icon(Icons.verified,
                                    size: 56, color: Color(0xFF2E9E6B)),
                                const SizedBox(width: 16),
                                Text(
                                  RemainingSurface.tr(
                                      context, 'wt.arrival.stamp', '스탬프를 받았어요'),
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w800,
                                    color: ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 130),
                  Text(
                    RemainingSurface.tr(
                      context,
                      'wt.arrival.title',
                      '\$name 도착!',
                      {'name': name},
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 120,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    '${formatTourKm(args.distanceKm)} km  ·  '
                    '${formatTourDuration(args.durationSeconds)}',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    RemainingSurface.tr(context, 'wt.virtual', '가상 여행 거리'),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 36, color: _muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Arrival: landmark, avatar, real distance and time, the stamp, a share
/// button and the next trip. Sharing wraps the existing image-share helper.
class WorldTourArrivalScreen extends ConsumerStatefulWidget {
  const WorldTourArrivalScreen({required this.args, super.key});

  final WorldTourArrivalArgs args;

  static const shareKey = Key('world-tour-share');
  static const passportKey = Key('world-tour-arrival-passport');
  static const nextKey = Key('world-tour-next');
  static const closeKey = Key('world-tour-arrival-close');
  static const posterKey = Key('world-tour-poster');

  @override
  ConsumerState<WorldTourArrivalScreen> createState() =>
      _WorldTourArrivalScreenState();
}

class _WorldTourArrivalScreenState
    extends ConsumerState<WorldTourArrivalScreen> {
  static const _systemSheetTarget = 'system_sheet';

  final GlobalKey _captureKey = GlobalKey();
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(shareFunnelEventsProvider).cardShown(BragSurface.worldTour);
    });
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final events = ref.read(shareFunnelEventsProvider);
    final box = context.findRenderObject() as RenderBox?;
    final origin =
        box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    events.qrIncluded(BragSurface.worldTour, included: true);
    events.shareTapped(BragSurface.worldTour, _systemSheetTarget);
    try {
      final file = await RunFinishImageShare.capture(_captureKey);
      final result = await RunFinishImageShare.shareImageFile(
        path: file.path,
        sharePositionOrigin: origin,
      );
      events.shareResult(
        BragSurface.worldTour,
        _systemSheetTarget,
        BragShareStatus.fromShareResult(result.status),
      );
    } catch (_) {
      events.shareResult(
        BragSurface.worldTour,
        _systemSheetTarget,
        BragShareStatus.failed,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(RunFinishImageShare.captureFailedMessage)),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final args = widget.args;
    final landmark = WorldTourLandmark.of(args.landmarkId);
    final next = ref.watch(worldTourMeProvider).maybeWhen(
          data: (me) => me.nextAfter(args.missionId),
          orElse: () => null,
        );
    return Scaffold(
      appBar: AppBar(
        title: const Text('World Tour'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            key: WorldTourArrivalScreen.closeKey,
            icon: const Icon(Icons.close),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(RouteNames.home);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(tokens.spacing.page),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: AspectRatio(
                  key: WorldTourArrivalScreen.posterKey,
                  aspectRatio: WorldTourArrivalPoster.width /
                      WorldTourArrivalPoster.height,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: RepaintBoundary(
                      key: _captureKey,
                      child: WorldTourArrivalPoster(
                        landmark: landmark,
                        args: args,
                        avatar: const WorldTourAvatar(size: 240),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: tokens.spacing.md),
            FilledButton.icon(
              key: WorldTourArrivalScreen.shareKey,
              onPressed: _sharing ? null : _share,
              icon: const Icon(Icons.ios_share),
              label: Text(
                RemainingSurface.tr(context, 'wt.arrival.share', '공유하기'),
              ),
            ),
            SizedBox(height: tokens.spacing.xs),
            OutlinedButton(
              key: WorldTourArrivalScreen.passportKey,
              onPressed: () =>
                  context.pushReplacement(RouteNames.worldTourPassport),
              child: Text(
                RemainingSurface.tr(context, 'wt.arrival.passport', '여권 보기'),
              ),
            ),
            if (next != null) ...[
              SizedBox(height: tokens.spacing.xs),
              OutlinedButton(
                key: WorldTourArrivalScreen.nextKey,
                onPressed: () => context.pushReplacement(
                  RouteNames.worldTourMission(next.missionId),
                ),
                child: Text(
                  RemainingSurface.tr(
                    context,
                    'wt.arrival.next',
                    '다음 여행: \$name',
                    {
                      'name': WorldTourLandmark.of(next.landmarkId)
                          .shortName(context, fallback: next.title),
                    },
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
