import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../../core/constants/payment_constants.dart';
import '../firebase/firestore_service.dart';
import '../models/payment_intent_model.dart';
import '../models/payment_intent_status_model.dart';
import '../models/sponsor_model.dart';

class PaymentRepository {
  PaymentRepository(this._firestoreService);

  final FirestoreService _firestoreService;

  Future<PaymentIntentModel> createShareTopUpIntent({
    required String uid,
    required int amountKrw,
  }) async {
    if (amountKrw != PaymentConstants.shareTopUpAmountKrw) {
      throw StateError('Unsupported top-up amount.');
    }

    final intentRef = _firestoreService.collection(FirestorePaths.paymentIntents).doc();
    final pgUrl = Uri.parse(PaymentConstants.pgBaseUrl).replace(
      path: PaymentConstants.shareTopUpPath,
      queryParameters: {
        'intentId': intentRef.id,
        'uid': uid,
        'amount': amountKrw.toString(),
      },
    );

    await intentRef.set({
      'uid': uid,
      'type': 'share_top_up',
      'amountKrw': amountKrw,
      'status': 'created',
      'pgUrl': pgUrl.toString(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return PaymentIntentModel(
      id: intentRef.id,
      type: PaymentIntentType.shareTopUp,
      amountKrw: amountKrw,
      pgUrl: pgUrl,
    );
  }

  Future<PaymentIntentModel> createSponsorPaymentIntent({
    required SponsorPaymentIntent sponsorIntent,
  }) async {
    if (!PaymentConstants.sponsorAmountOptionsShare.contains(sponsorIntent.amountShare)) {
      throw StateError('Unsupported sponsor amount.');
    }

    final intentRef = _firestoreService.collection(FirestorePaths.paymentIntents).doc();
    final pgUrl = Uri.parse(PaymentConstants.pgBaseUrl).replace(
      path: PaymentConstants.sponsorPath,
      queryParameters: {
        'intentId': intentRef.id,
        'uid': sponsorIntent.uid,
        'sponsorId': sponsorIntent.sponsorId,
        'tournamentId': sponsorIntent.tournamentId,
        'amount': sponsorIntent.amountShare.toString(),
        'option': sponsorIntent.option.code,
      },
    );

    await intentRef.set({
      'uid': sponsorIntent.uid,
      'sponsorId': sponsorIntent.sponsorId,
      'tournamentId': sponsorIntent.tournamentId,
      'type': 'sponsor_payment',
      'amountShare': sponsorIntent.amountShare,
      'option': sponsorIntent.option.code,
      'status': 'created',
      'pgUrl': pgUrl.toString(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return PaymentIntentModel(
      id: intentRef.id,
      type: PaymentIntentType.sponsorSupport,
      amountKrw: sponsorIntent.amountShare,
      pgUrl: pgUrl,
    );
  }

  Stream<PaymentIntentStatusModel?> watchPaymentIntentStatus(String intentId) {
    return _firestoreService
        .collection(FirestorePaths.paymentIntents)
        .doc(intentId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      return PaymentIntentStatusModel.fromFirestore(
        id: snapshot.id,
        data: snapshot.data() ?? const {},
      );
    });
  }
}
