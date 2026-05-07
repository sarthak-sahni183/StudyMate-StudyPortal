import 'package:cloud_firestore/cloud_firestore.dart';

class GoalModel {
  final String id;
  final String title;
  final String description;
  final DateTime deadline;
  final bool isCompleted;

  GoalModel({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'deadline': Timestamp.fromDate(deadline),
      'isCompleted': isCompleted,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory GoalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    return GoalModel(
      id: doc.id,
      title: data?['title'] ?? 'Untitled Goal',
      description: data?['description'] ?? '',
      // Convert Firebase Timestamp back to Dart DateTime safely
      deadline: (data?['deadline'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isCompleted: data?['isCompleted'] ?? false,
    );
  }
}