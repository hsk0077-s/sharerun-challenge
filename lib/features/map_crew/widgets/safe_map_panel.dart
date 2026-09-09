import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/config/app_env.dart';

enum SafeMapPanelStatus { loading, ready, unavailable }

/// Renders GoogleMap only when API config and location access are ready.
/// Falls back to a non-crashing placeholder instead of mounting the native map view.
class SafeMapPanel extends StatefulWidget {
  const SafeMapPanel({
    required this.markers,
    this.height = 300,
    this.onPositionChanged,
    super.key,
  });

  final double height;
  final Set<Marker> markers;
  final ValueChanged<Position?>? onPositionChanged;

  @override
  State<SafeMapPanel> createState() => SafeMapPanelState();
}

class SafeMapPanelState extends State<SafeMapPanel> {
  SafeMapPanelStatus _status = SafeMapPanelStatus.loading;
  Position? _position;
  var _locationPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_prepareMap);
  }

  Future<void> retry() => _prepareMap();

  Future<void> _prepareMap() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _status = SafeMapPanelStatus.loading;
    });
    widget.onPositionChanged?.call(null);

    try {
      if (!AppEnv.isGoogleMapsConfigured) {
        _markUnavailable();
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _markUnavailable();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        try {
          permission = await Geolocator.requestPermission();
        } catch (_) {
          _markUnavailable();
          return;
        }
      }

      _locationPermissionGranted =
          permission == LocationPermission.always ||
              permission == LocationPermission.whileInUse;

      if (!_locationPermissionGranted) {
        _markUnavailable();
        return;
      }

      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
          ),
        );
      } catch (_) {
        _markUnavailable();
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _position = position;
        _status = SafeMapPanelStatus.ready;
      });
      widget.onPositionChanged?.call(position);
    } catch (_) {
      _markUnavailable();
    }
  }

  void _markUnavailable() {
    if (!mounted) {
      return;
    }
    setState(() => _status = SafeMapPanelStatus.unavailable);
    widget.onPositionChanged?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        border: Border.all(color: AppColors.electricBlue.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(28),
      ),
      clipBehavior: Clip.antiAlias,
      child: switch (_status) {
        SafeMapPanelStatus.loading => const _MapPlaceholder(showProgress: true),
        SafeMapPanelStatus.unavailable => const _MapPlaceholder(),
        SafeMapPanelStatus.ready => _buildMap(),
      },
    );
  }

  Widget _buildMap() {
    final position = _position;
    if (position == null) {
      return const _MapPlaceholder();
    }

    try {
      return GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 16,
        ),
        myLocationEnabled: _locationPermissionGranted,
        myLocationButtonEnabled: _locationPermissionGranted,
        markers: widget.markers,
        onMapCreated: (_) {},
      );
    } catch (_) {
      return const _MapPlaceholder();
    }
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({this.showProgress = false});

  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showProgress) ...[
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(height: 14),
          ] else ...[
            Icon(
              Icons.map_outlined,
              size: 40,
              color: AppColors.textSecondary.withOpacity(0.7),
            ),
            const SizedBox(height: 12),
          ],
          const Text(
            '지도 준비 중',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
