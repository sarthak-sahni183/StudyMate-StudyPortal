import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<void> addStudySession({
    required String uid,
    required String subject,
    required int duration,
    required int productivity,
  }) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .add({
      'subject': subject,
      'duration': duration,
      'productivity': productivity,
      'createdAt': Timestamp.now(),
    });
  }

Future<void> addAuthLog({
  required String email,
  required String action,
  required String status,
  String? error,
}) async {

  await _firestore
      .collection('auth_logs')
      .add({

    'email': email,
    'action': action,
    'status': status,
    'error': error ?? '',
    'timestamp': Timestamp.now(),
  });
}
}