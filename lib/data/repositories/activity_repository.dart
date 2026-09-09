import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../firebase/firestore_service.dart';
import '../models/activity_model.dart';
import '../models/user_model.dart';

class ActivityRepository {
  ActivityRepository(this._firestoreService);

  final FirestoreService _firestoreService;

  Stream<List<ActivityModel>> watchRecentActivities(String uid) {
    return _firestoreService
        .collection(FirestorePaths.activities)
        .where('userId', isEqualTo: uid)
        .orderBy('updatedAt', descending: true)
        .limit(30)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromSnapshot).toList());
  }

  /// Activities.watch_api_token 매핑 — Users 컬렉션과 동일 토큰을 연결.
  Future<void> mapWatchApiToken({
    required String userId,
    required String watchApiToken,
    required WatchType watchType,
  }) {
    return _firestoreService.doc(FirestorePaths.userWatchLink(userId)).set(
      {
        'userId': userId,
        'watch_api_token': watchApiToken,
        'watchApiToken': watchApiToken,
        'watchType': watchType.code,
        'jenaPipelineReady': true,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Client activity writes cannot mark a run passed. Use
  /// `POST /actions/runs/validate` via [ActivityValidationService].
  Future<void> persistMinimizedJenaResult({
    required String activityId,
    required String userId,
    required double distanceKm,
    required bool jenaVerified,
    ActivityStatus activityStatus = ActivityStatus.passed,
    String? jenaDecision,
    String? jenaReason,
    bool locked = false,
  }) {
    throw UnsupportedError(
      'Activity $activityId for $userId must be persisted by '
      'POST /actions/runs/validate (distanceKm=$distanceKm, '
      'verified=$jenaVerified, status=${activityStatus.code}, '
      'decision=$jenaDecision, locked=$locked, reason=$jenaReason).',
    );
  }

  ActivityModel _fromSnapshot(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final statusCode = data['activityStatus'] as String?;
    final appealStatus = data['appealStatus'] as String?;
    final verified = data['jenaVerified'] as bool? ??
        data['Jena_Verified'] as bool? ??
        false;
    final decision = data['jenaDecision'] as String?;

    final ActivityValidationStatus validationStatus;
    if (appealStatus == 'under_review') {
      validationStatus = ActivityValidationStatus.underReview;
    } else if (statusCode != null) {
      validationStatus =
          ActivityStatusCode.fromCode(statusCode).asValidationStatus;
    } else if (verified) {
      validationStatus = ActivityValidationStatus.verified;
    } else if (decision == null) {
      validationStatus = ActivityValidationStatus.pending;
    } else {
      validationStatus = ActivityValidationStatus.rejected;
    }

    final completedAt = data['completedAt'];
    DateTime? completedDate;
    if (completedAt is Timestamp) {
      completedDate = completedAt.toDate();
    }

    return ActivityModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      distanceKm: (data['distanceKm'] as num?)?.toDouble() ?? 0,
      durationSeconds: (data['durationSeconds'] as num?)?.toInt(),
      averagePaceSecondsPerKm:
          (data['averagePaceSecondsPerKm'] as num?)?.toDouble(),
      completedAt: completedDate,
      validationStatus: validationStatus,
      jenaReason: data['jenaReason'] as String?,
    );
  }
}
