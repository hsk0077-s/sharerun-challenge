import 'package:flutter/foundation.dart';

import '../../core/config/app_env.dart';
import '../../core/constants/firestore_paths.dart';
import '../../data/firebase/firestore_service.dart';
import 'stamp_landmark.dart';
import 'stamp_landmark_catalog.dart';

/// Reads official landmarks from `config/stamp_tour` or `stampLandmarks`.
/// Empty / error → caller falls back to the Seoul seed catalog.
class FirestoreStampLandmarkSource implements StampOfficialLandmarkSource {
  const FirestoreStampLandmarkSource(this._firestore);

  final FirestoreService _firestore;

  @override
  Future<List<StampLandmark>> loadOfficial() async {
    if (AppEnv.useLocalMockData) return const [];
    try {
      final fromConfig = await _loadConfigDoc();
      if (fromConfig.isNotEmpty) return fromConfig;
      return await _loadCollection();
    } catch (e) {
      debugPrint('FirestoreStampLandmarkSource: $e');
      return const [];
    }
  }

  Future<List<StampLandmark>> _loadConfigDoc() async {
    final snap = await _firestore.doc(FirestorePaths.stampTourConfig).get();
    if (!snap.exists) return const [];
    final data = snap.data();
    if (data == null) return const [];
    final raw = data['landmarks'];
    if (raw is! List) return const [];
    return _parseList(raw, StampLandmarkOrigin.officialRemote);
  }

  Future<List<StampLandmark>> _loadCollection() async {
    final snap = await _firestore.collection(FirestorePaths.stampLandmarks).get();
    if (snap.docs.isEmpty) return const [];
    return snap.docs
        .map((doc) {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = (data['id'] as String?)?.trim().isNotEmpty == true
              ? data['id']
              : doc.id;
          return StampLandmark.fromJson(data);
        })
        .where(StampLandmark.isUsable)
        .toList(growable: false);
  }

  static List<StampLandmark> _parseList(
    List<dynamic> raw,
    StampLandmarkOrigin fallback,
  ) {
    final out = <StampLandmark>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final landmark = StampLandmark.fromJson(
        Map<String, dynamic>.from(item),
        fallbackOrigin: fallback,
      );
      if (StampLandmark.isUsable(landmark)) out.add(landmark);
    }
    return List<StampLandmark>.unmodifiable(out);
  }
}
