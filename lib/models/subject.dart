import 'package:cloud_firestore/cloud_firestore.dart';

class Subject {
  final String id;
  final String name;
  final int difficulty;
  final int importance;

  Subject({
    required this.id,
    required this.name,
    required this.difficulty,
    required this.importance,
  });

  // Write to Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'difficulty': difficulty,
      'importance': importance,
    };
  }

  // Read from Firestore
  factory Subject.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    
    return Subject(
      id: doc.id,
      name: data?['name'] ?? 'Unknown Subject',
      difficulty: data?['difficulty'] ?? 1,
      importance: data?['importance'] ?? 1,
    );
  }

  // Useful for updating specific fields later
  Subject copyWith({String? name, int? difficulty, int? importance}) {
    return Subject(
      id: id,
      name: name ?? this.name,
      difficulty: difficulty ?? this.difficulty,
      importance: importance ?? this.importance,
    );
  }
}