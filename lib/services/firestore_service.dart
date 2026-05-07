import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/study_session.dart';


class FirestoreService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;





Future<Map<String, dynamic>>
    getDashboardData(String uid) async {

  final userDoc = await _firestore
      .collection('users')
      .doc(uid)
      .get();

  final userData = userDoc.data();

  final sessionSnapshot = await _firestore
      .collection('users')
      .doc(uid)
      .collection('sessions')
      .get();

  int totalStudyTime = 0;

  int totalSessions =
      sessionSnapshot.docs.length;

  double avgProductivity = 0;

  if (sessionSnapshot.docs.isNotEmpty) {

    int productivitySum = 0;

    for (var doc in sessionSnapshot.docs) {

      totalStudyTime +=
          (doc['duration'] as int);

      productivitySum +=
          (doc['productivity'] as int);
    }

    avgProductivity =
        productivitySum /
        sessionSnapshot.docs.length;
  }

  return {

    'name': userData?['name'] ?? 'User',

    'streak': userData?['streak'] ?? 0,

    'totalStudyTime': totalStudyTime,

    'totalSessions': totalSessions,

    'avgProductivity':
        avgProductivity.toStringAsFixed(1),
  };
}
  

Future<void> createUserData({
  required String uid,
  required String email,
}) async {

  await _firestore
      .collection('users')
      .doc(uid)
      .set({

    'email': email,
    'name': email.split('@')[0],
    'streak': 0,
    'createdAt': Timestamp.now(),
  });
}


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


  Future<List<StudySession>> getSessions(
    String uid) async {

  final snapshot = await _firestore
      .collection('users')
      .doc(uid)
      .collection('sessions')
      .orderBy('createdAt', descending: true)
      .get();

  return snapshot.docs
      .map((doc) =>
      StudySession.fromFirestore(doc))
      .toList();
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