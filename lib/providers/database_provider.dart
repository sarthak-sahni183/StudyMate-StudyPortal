import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../models/study_session.dart';
import '../models/user.dart';
import '../models/goal.dart';

class DatabaseProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }


  // ==========================================
  // GOAL METHODS
  // ==========================================

  /// Add a new goal to the user's subcollection
  Future<void> addGoal({
    required String uid,
    required String title,
    required String description,
    required DateTime deadline,
  }) async {
    _setLoading(true);
    try {
      final newGoal = GoalModel(
        id: '', 
        title: title,
        description: description,
        deadline: deadline,
      );

      await _db
          .collection('users')
          .doc(uid)
          .collection('goals')
          .add(newGoal.toMap());

    } catch (e) {
      debugPrint("Error adding goal: $e");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }


  Future<void> completeGoal({
    required String uid,
    required String goalId,
  }) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('goals')
          .doc(goalId)
          .update({'isCompleted': true});
    } catch (e) {
      debugPrint("Error completing goal: $e");
      rethrow;
    }
  }


  /// Get a real-time stream of incomplete goals, automatically sorted by nearest deadline
  Stream<List<GoalModel>> getGoalsStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('goals')
        // We removed the .where() query here to bypass the Firebase Index requirement!
        .orderBy('deadline') 
        .snapshots()
        .map((snapshot) {
          // Convert the Firebase documents to GoalModel objects
          final allGoals = snapshot.docs
              .map((doc) => GoalModel.fromFirestore(doc))
              .toList();
              
          // Filter out the completed goals locally in Dart instead!
          return allGoals.where((goal) => goal.isCompleted == false).toList();
        });
  }

  // ==========================================
  // SUBJECT METHOD
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
      // 2. Mathematically update the User's Dashboard Stats
      DocumentReference userRef = _db.collection('users').doc(uid);
      
      await _db.runTransaction((transaction) async {
        DocumentSnapshot userDoc = await transaction.get(userRef);
        if (!userDoc.exists) return;

        UserModel user = UserModel.fromFirestore(userDoc);

        // --- 1. Basic Stats Math ---
        int newTotalSessions = user.totalSessions + 1;
        int newTotalTime = user.totalStudyTime + duration;
        double newAvgProductivity = ((user.avgProductivity * user.totalSessions) + productivityRating) / newTotalSessions;

        // --- 2. THE STREAK & WEEK BUBBLE MATH ---
        DateTime now = DateTime.now();
        DateTime today = DateTime(now.year, now.month, now.day); // Strip the time out
        
        int newStreak = user.streak;
        List<bool> newWeekActivity = List.from(user.weekActivity);
        
        // Dart weekdays: 1 = Monday, 7 = Sunday. We subtract 1 to get array index (0-6)
        int todayIndex = now.weekday - 1; 

        if (user.lastSessionDate == null) {
          // First session ever!
          newStreak = 1;
          newWeekActivity[todayIndex] = true;
        } else {
          DateTime lastSession = DateTime(
            user.lastSessionDate!.year, 
            user.lastSessionDate!.month, 
            user.lastSessionDate!.day
          );
          
          int daysDifference = today.difference(lastSession).inDays;

          // Handle Week Activity Reset (If a new week started, wipe the bubbles clean)
          if (daysDifference >= 7 || now.weekday < user.lastSessionDate!.weekday) {
             newWeekActivity = [false, false, false, false, false, false, false];
          }
          // Light up today's bubble!
          newWeekActivity[todayIndex] = true;

          // Handle Streak
          if (daysDifference == 1) {
            // Studied yesterday! Streak goes up!
            newStreak += 1;
          } else if (daysDifference > 1) {
            // Missed a day. Streak resets to 1.
            newStreak = 1;
          }
          // If daysDifference == 0, they already studied today, so streak stays exactly the same!
        }

        // --- 3. Push everything to Firebase ---
        transaction.update(userRef, {
          'totalSessions': newTotalSessions,
          'totalStudyTime': newTotalTime,
          'avgProductivity': double.parse(newAvgProductivity.toStringAsFixed(1)),
          'streak': newStreak,
          'weekActivity': newWeekActivity,
          'lastSessionDate': FieldValue.serverTimestamp(), // Update the date for next time!
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

  /// Create a stream of completed study sessions for analytics.
  Stream<List<StudySession>> getSessionsStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .where('isCompleted', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StudySession.fromFirestore(doc))
            .toList());
  }
}
