import 'package:cloud_firestore/cloud_firestore.dart';

class StudySession {
  final String id;
  final String subjectName; 
  final int plannedDuration; 
  final int? actualDuration;// What they choose before starting
  final int? productivity;   // Rated at the end (nullable)
  final Timestamp startTime;
  final Timestamp? endTime;  // Set at the end (nullable)
  final bool isCompleted;    // To filter out active vs finished sessions

  StudySession({
    required this.id,
    required this.subjectName,
    required this.plannedDuration,
    this.actualDuration,
    this.productivity,
    required this.startTime,
    this.endTime,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'subjectName': subjectName,
      'plannedDuration': plannedDuration,
      'actualDuration': actualDuration,
      'productivity': productivity,
      'startTime': startTime, 
      'endTime': endTime,
      'isCompleted': isCompleted,
    };
  }

  factory StudySession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    return StudySession(
      id: doc.id,
      subjectName: data?['subjectName'] ?? 'Unknown',
      plannedDuration: data?['plannedDuration'] ?? 0,
      actualDuration: data?['actualDuration'],
      productivity: data?['productivity'], 
      startTime: data?['startTime'] as Timestamp? ?? Timestamp.now(),
      endTime: data?['endTime'] as Timestamp?,
      isCompleted: data?['isCompleted'] ?? false,
    );
  }
}