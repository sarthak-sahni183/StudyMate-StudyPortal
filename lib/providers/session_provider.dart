import 'package:flutter/material.dart';
import '../models/study_session.dart';
import '../services/firestore_service.dart';

class SessionProvider extends ChangeNotifier {

  final FirestoreService _firestoreService =
      FirestoreService();

  List<StudySession> sessions = [];

  bool isLoading = false;

  Future<void> fetchSessions(String uid) async {

    isLoading = true;
    notifyListeners();

    sessions =
    await _firestoreService.getSessions(uid);

    isLoading = false;
    notifyListeners();
  }

  Future<void> addSession({
    required String uid,
    required String subject,
    required int duration,
    required int productivity,
  }) async {

    await _firestoreService.addStudySession(
      uid: uid,
      subject: subject,
      duration: duration,
      productivity: productivity,
    );

    await fetchSessions(uid);
  }
}