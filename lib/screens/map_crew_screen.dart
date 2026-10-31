import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../app/providers/app_providers.dart';
import '../core/api/api_exception.dart';
import '../app/theme/app_colors.dart';
import '../features/map_crew/widgets/crew_member_ranking_board.dart';
import '../features/map_crew/widgets/safe_map_panel.dart';
import '../data/models/diamond_box_model.dart';
import '../l10n/remaining_surface.dart';

class MapCrewScreen extends ConsumerStatefulWidget {
  const MapCrewScreen({super.key});

  @override
  ConsumerState<MapCrewScreen> createState() => _MapCrewScreenState();
}

class _MapCrewScreenState extends ConsumerState<MapCrewScreen> {
  static const collectRadiusMeters = 80.0;

  final _mapPanelKey = GlobalKey<SafeMapPanelState>();

  Position? currentPosition;
  DiamondBoxModel? selectedBox;

  @override
  Widget build(BuildContext context) {
    final boxes = ref.watch(activeDiamondBoxesProvider).value ?? const [];
    final crews = ref.watch(topCrewsProvider).value ?? const [];
    final crewMembers = ref.watch(crewMemberRankingsProvider).value ?? const [];
    final authUser = ref.watch(authStateChangesProvider).value;
    final selectedDistance = _selectedDistanceMeters();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          RemainingSurface.tr(context, 'map_crew.body', '지도 & 크루'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => _mapPanelKey.currentState?.retry(),
            icon: const Icon(Icons.my_location_rounded),
            label: Text(
              RemainingSurface.tr(context, 'map_crew.button', '내 위치 새로고침'),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SafeMapPanel(
          key: _mapPanelKey,
          markers: _buildDiamondMarkers(boxes),
          onPositionChanged: (position) {
            if (!mounted) {
              return;
            }
            setState(() => currentPosition = position);
          },
        ),
        if (selectedBox != null) ...[
          const SizedBox(height: 16),
          _DiamondCollectCard(
            box: selectedBox!,
            distanceMeters: selectedDistance,
            canCollect: selectedDistance != null &&
                selectedDistance <= collectRadiusMeters &&
                authUser != null,
            onCollect: authUser == null
                ? null
                : () => _collectSelectedBox(selectedBox!),
          ),
        ],
        const SizedBox(height: 24),
        CrewMemberRankingBoard(members: crewMembers),
        const SizedBox(height: 24),
        Text(
          RemainingSurface.tr(context, 'map_crew.body.2', '크루 종합 랭킹'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < crews.length; index++)
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    index == 0 ? AppColors.neonLime : AppColors.electricBlue,
                foregroundColor: Colors.black,
                child: Text('${index + 1}'),
              ),
              title: Text(crews[index].name),
              subtitle: Text(
                RemainingSurface.tr(
                  context,
                  'map_crew.body.3',
                  '${crews[index].memberCount}명',
                  {'crews[index].memberCount': crews[index].memberCount},
                ),
              ),
              trailing: Text('${crews[index].totalValue} VALUE'),
            ),
          ),
        if (crews.isEmpty)
          Card(
            child: ListTile(
              title: Text(
                RemainingSurface.tr(context, 'map_crew.body.4', '아직 크루 순위가 없어요'),
              ),
              subtitle: Text(
                RemainingSurface.tr(
                  context,
                  'map_crew.body.5',
                  '크루 순위가 쌓이면 여기에 나타나요.',
                ),
              ),
            ),
          ),
      ],
    );
  }

  Set<Marker> _buildDiamondMarkers(List<DiamondBoxModel> boxes) {
    try {
      return boxes
          .map(
            (box) => Marker(
              markerId: MarkerId(box.id),
              position: LatLng(box.latitude, box.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueViolet,
              ),
              infoWindow: InfoWindow(
                title: box.title,
                snippet: '+${box.rewardDiamond} DIA',
              ),
              onTap: () => setState(() => selectedBox = box),
            ),
          )
          .toSet();
    } catch (_) {
      return const {};
    }
  }

  double? _selectedDistanceMeters() {
    final position = currentPosition;
    final box = selectedBox;
    if (position == null || box == null) {
      return null;
    }

    try {
      return Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        box.latitude,
        box.longitude,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _collectSelectedBox(DiamondBoxModel box) async {
    final position = currentPosition;
    final distance = _selectedDistanceMeters();
    if (position == null || distance == null || distance > collectRadiusMeters) {
      _showSnack(
        RemainingSurface.tr(
          context,
          'map_crew.body.6',
          '${collectRadiusMeters.round()}m 안으로 가까이 가야 받을 수 있어요.',
          {'collectRadiusMeters.round()': collectRadiusMeters.round()},
        ),
      );
      return;
    }

    try {
      await ref.read(diamondBoxRepositoryProvider).collectBox(
            box: box,
            latitude: position.latitude,
            longitude: position.longitude,
          );
      if (!mounted) {
        return;
      }
      setState(() => selectedBox = null);
      _showSnack(
        RemainingSurface.tr(
          context,
          'map_crew.body.7',
          '+${box.rewardDiamond} DIA를 받았어요.',
          {'box.rewardDiamond': box.rewardDiamond},
        ),
      );
    } catch (error) {
      _showSnack(ApiErrorMessage.from(error));
    }
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _DiamondCollectCard extends StatelessWidget {
  const _DiamondCollectCard({
    required this.box,
    required this.distanceMeters,
    required this.canCollect,
    required this.onCollect,
  });

  final DiamondBoxModel box;
  final double? distanceMeters;
  final bool canCollect;
  final VoidCallback? onCollect;

  @override
  Widget build(BuildContext context) {
    final distanceLabel = distanceMeters == null
        ? '--'
        : RemainingSurface.tr(
            context,
            'map_crew.body.8',
            '${distanceMeters!.toStringAsFixed(0)}m 떨어져 있어요',
            {
              'distanceMeters!.toStringAsFixed(0)':
                  distanceMeters!.toStringAsFixed(0),
            },
          );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        border: Border.all(color: AppColors.neonLime.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(box.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('+${box.rewardDiamond} DIA / $distanceLabel'),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: canCollect ? onCollect : null,
            icon: const Icon(Icons.diamond_rounded),
            label: Text(
              canCollect
                  ? RemainingSurface.tr(
                      context,
                      'map_crew.button.2',
                      '다이아 상자 받기',
                    )
                  : RemainingSurface.tr(
                      context,
                      'map_crew.button.3',
                      '더 가까이 가 주세요',
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
