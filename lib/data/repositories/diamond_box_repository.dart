import '../../core/constants/firestore_paths.dart';
import '../api/secured_action_api_client.dart';
import '../firebase/firestore_service.dart';
import '../models/diamond_box_model.dart';

class DiamondBoxRepository {
  DiamondBoxRepository(
    this._firestoreService,
    this._securedActionApiClient,
  );

  final FirestoreService _firestoreService;
  final SecuredActionApiClient _securedActionApiClient;

  Stream<List<DiamondBoxModel>> watchActiveBoxes() {
    return _firestoreService
        .collection(FirestorePaths.diamondBoxes)
        .where('active', isEqualTo: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => DiamondBoxModel.fromJson(
                  id: doc.id,
                  json: doc.data(),
                ),
              )
              .toList(),
        );
  }

  Future<void> collectBox({
    required DiamondBoxModel box,
    required double latitude,
    required double longitude,
  }) {
    return _securedActionApiClient.collectDiamondBox(
      boxId: box.id,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
