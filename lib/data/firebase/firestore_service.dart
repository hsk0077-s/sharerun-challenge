import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore firestore;

  DocumentReference<Map<String, dynamic>> doc(String path) {
    return firestore.doc(path);
  }

  CollectionReference<Map<String, dynamic>> collection(String path) {
    return firestore.collection(path);
  }

  Query<Map<String, dynamic>> collectionGroup(String collectionId) {
    return firestore.collectionGroup(collectionId);
  }

  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) handler,
  ) {
    return firestore.runTransaction(handler);
  }
}
