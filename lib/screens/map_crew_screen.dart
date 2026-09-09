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
        Text('Map & Crew', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => _mapPanelKey.currentState?.retry(),
            icon: const Icon(Icons.my_location_rounded),
            label: const Text('Refresh Location'),
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
        Text('크루 종합 랭킹', style: Theme.of(context).textTheme.titleLarge),
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
              subtitle: Text('${crews[index].memberCount} members'),
              trailing: Text('${crews[index].totalValue} Value'),
            ),
          ),
        if (crews.isEmpty)
          const Card(
            child: ListTile(
              title: Text('No crew rankings yet'),
              subtitle: Text('Firestore crewRankings data will appear here.'),
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
                snippet: '+${box.rewardDiamond} Diamond',
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
      _showSnack('Move within ${collectRadiusMeters.round()}m to collect this box.');
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
      _showSnack('+${box.rewardDiamond} Diamond collected.');
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
        : '${distanceMeters!.toStringAsFixed(0)}m away';

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
          Text('+${box.rewardDiamond} Diamond / $distanceLabel'),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: canCollect ? onCollect : null,
            icon: const Icon(Icons.diamond_rounded),
            label: Text(canCollect ? 'Collect Diamond Box' : 'Move closer to collect'),
          ),
        ],
      ),
    );
  }
}
