import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../core/theme/theme.dart';
import '../../../l10n/remaining_surface.dart';
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

  static const width = 1080.0;
  static const height = 1920.0;

  final WorldTourLandmark landmark;
  final WorldTourArrivalArgs args;
  final Widget avatar;

  @override
  Widget build(BuildContext context) {
    final name = landmark.shortName(context);
    const ink = Color(0xFF101820);
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(color: landmark.color.withValues(alpha: 0.18)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(72, 120, 72, 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    WorldTourLandmarkArt(
                      landmark: landmark,
                      height: double.infinity,
                      radius: 56,
                    ),
                    Positioned(
                      left: 48,
                      bottom: -90,
                      child: SizedBox(width: 240, height: 240, child: avatar),
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
              const SizedBox(height: 150),
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
              const SizedBox(height: 40),
              Text(
                '${formatTourKm(args.distanceKm)} km  ·  '
                '${formatTourDuration(args.durationSeconds)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
              const Spacer(),
              Text(
                RemainingSurface.tr(context, 'wt.virtual', '가상 여행 거리'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 36, color: Color(0xFF55616B)),
              ),
              const SizedBox(height: 16),
              Text(
                RemainingSurface.tr(context, 'wt.brand', '쉐어런'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: ink,
                ),
              ),
            ],
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
  final GlobalKey _captureKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    try {
      final file = await RunFinishImageShare.capture(_captureKey);
      await RunFinishImageShare.shareImageFile(
        path: file.path,
        sharePositionOrigin: origin,
      );
    } catch (_) {
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
              onPressed: () => context.pushReplacement(RouteNames.worldTourPassport),
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
