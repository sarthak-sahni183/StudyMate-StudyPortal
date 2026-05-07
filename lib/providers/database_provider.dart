import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../models/study_session.dart';

class DatabaseProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // ==========================================
  // SUBJECT METHODS
  // ==========================================

  /// Adds a subject and RETURNS the generated ID so the UI dropdown can select it immediately
  Future<String> addSubject({
    required String uid,
    required String name,
    required int difficulty,
    required int importance,
  }) async {
    _setLoading(true);
    try {
      final newSubject = Subject(
        id: '', 
        name: name,
        difficulty: difficulty,
        importance: importance,
      );

      // We use .add() which returns a DocumentReference containing the new ID
      DocumentReference docRef = await _db
          .collection('users')
          .doc(uid)
          .collection('subjects')
          .add(newSubject.toMap());
          
      return docRef.id; // Return the ID for the UI
          
    } catch (e) {
      debugPrint("Error adding subject: $e");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ... (Keep the getSubjectsStream method from before here) ...
   Stream<List<Subject>> getSubjectsStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('subjects')
        .orderBy('name') // Alphabetical order
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Subject.fromFirestore(doc))
            .toList());
  }

  // ==========================================
  // SESSION METHODS (The New Lifecycle)
  // ==========================================

  /// 1. Called when the user hits "Start"
  /// Returns the sessionId so the UI can hold onto it while the timer runs
  Future<String> startSession({
    required String uid,
    required String subjectName,
    required int plannedDuration,
  }) async {
    try {
      final newSession = StudySession(
        id: '',
        subjectName: subjectName,
        plannedDuration: plannedDuration,
        startTime: Timestamp.now(), // Exact start time
        isCompleted: false, // Mark as currently running
        // productivity and endTime are intentionally left null
      );

      DocumentReference docRef = await _db
          .collection('users')
          .doc(uid)
          .collection('sessions')
          .add(newSession.toMap());

      return docRef.id; // Save this ID in your UI state!

    } catch (e) {
      debugPrint("Error starting session: $e");
      rethrow;
    }
  }

  /// 2. Called when the session ends and the user submits their rating
  Future<void> finishAndRateSession({
    required String uid,
    required String sessionId,
    required int productivityRating,
  }) async {
    try {
      // Instead of .add(), we use .update() to modify the existing document
      await _db
          .collection('users')
          .doc(uid)
          .collection('sessions')
          .doc(sessionId)
          .update({
        'productivity': productivityRating,
        'endTime': FieldValue.serverTimestamp(), // Exact end time
        'isCompleted': true,
      });

    } catch (e) {
      debugPrint("Error completing session: $e");
      rethrow;
    }
  }

  // ... (Keep the getSessionsStream method from before here) ...
}