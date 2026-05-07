import 'package:cloud_firestore/cloud_firestore.dart';

class StudySession {
  final String id;
  final String subject;
  final int duration;
  final int productivity;
  final Timestamp createdAt;

  StudySession({
    required this.id,
    required this.subject,
    required this.duration,
    required this.productivity,
    required this.createdAt,
  });

  factory StudySession.fromFirestore(
      DocumentSnapshot doc) {

    final data =
    doc.data() as Map<String, dynamic>;

    return StudySession(
      id: doc.id,
      subject: data['subject'] ?? '',
      duration: data['duration'] ?? 0,
      productivity: data['productivity'] ?? 0,
      createdAt: data['createdAt'],
    );
  }
}