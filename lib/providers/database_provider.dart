import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../models/study_session.dart';
import '../models/user.dart';

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
  /// 2. Called when the session ends and the user submits their rating
  /// Notice we added 'duration' so we can add it to the user's total!
  Future<void> finishAndRateSession({
    required String uid,
    required String sessionId,
    required int productivityRating,
    required int duration, // NEW PARAMETER
  }) async {
    try {
      // 1. Update the specific session document
      await _db
          .collection('users')
          .doc(uid)
          .collection('sessions')
          .doc(sessionId)
          .update({
        'productivity': productivityRating,
        'endTime': FieldValue.serverTimestamp(), 
        'isCompleted': true,
      });

      // 2. Mathematically update the User's Dashboard Stats
      DocumentReference userRef = _db.collection('users').doc(uid);
      
      // We use a Transaction to safely read the old stats, calculate the new ones, and save them.
      await _db.runTransaction((transaction) async {
        DocumentSnapshot userDoc = await transaction.get(userRef);
        
        if (!userDoc.exists) return;

        // Use our new model to easily read the current data
        UserModel user = UserModel.fromFirestore(userDoc);

        // Calculate new values
        int newTotalSessions = user.totalSessions + 1;
        int newTotalTime = user.totalStudyTime + duration;
        
        // Calculate new rolling average for productivity
        double newAvgProductivity = ((user.avgProductivity * user.totalSessions) + productivityRating) / newTotalSessions;

        // Update the user document
        transaction.update(userRef, {
          'totalSessions': newTotalSessions,
          'totalStudyTime': newTotalTime,
          'avgProductivity': double.parse(newAvgProductivity.toStringAsFixed(1)), // Keep it to 1 decimal place
          // We can also flip today's weekActivity boolean here in the future!
        });
      });

    } catch (e) {
      debugPrint("Error completing session: $e");
      rethrow;
    }
  }

  // --- NEW METHOD ---
  // Create a stream for the UserModel so the Dashboard updates instantly!
  Stream<UserModel> getUserStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => UserModel.fromFirestore(doc));
  }

  // ... (Keep the getSessionsStream method from before here) ...
}