import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final int age;
  
  // Dashboard Stats
  final int streak;
  final int totalStudyTime; // in minutes
  final int totalSessions;
  final double avgProductivity;
  final List<bool> weekActivity;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.age,
    required this.streak,
    required this.totalStudyTime,
    required this.totalSessions,
    required this.avgProductivity,
    required this.weekActivity,
  });

  // Convert to Firebase Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'age': age,
      'streak': streak,
      'totalStudyTime': totalStudyTime,
      'totalSessions': totalSessions,
      'avgProductivity': avgProductivity,
      'weekActivity': weekActivity,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Convert from Firebase Document
  // Convert from Firebase Document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    return UserModel(
      uid: doc.id,
      name: data?['name'] ?? 'Student',
      email: data?['email'] ?? '',
      age: data?['age'] ?? 0,
      streak: data?['streak'] ?? 0,
      totalStudyTime: data?['totalStudyTime'] ?? 0,
      totalSessions: data?['totalSessions'] ?? 0,
      
      // FIX IS HERE: Converts it to a string first, then safely parses it to a double.
      // This works perfectly whether Firebase stored it as "0", 0, or 4.5!
      avgProductivity: double.tryParse(data?['avgProductivity']?.toString() ?? '0') ?? 0.0,
      
      weekActivity: List<bool>.from(
        data?['weekActivity'] ?? [false, false, false, false, false, false, false]
      ),
    );
  }}