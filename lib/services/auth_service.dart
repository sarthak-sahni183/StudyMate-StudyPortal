import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // Return null on success
    } on FirebaseAuthException catch (e) {
      // Catch specific Firebase error codes
      if (e.code == 'user-not-found' || e.code == 'invalid-email' || e.code == 'invalid-credential') {
        return 'No user found for that email or invalid credentials.';
      } else if (e.code == 'wrong-password') {
        return 'Incorrect password. Please try again.';
      } else if (e.code == 'user-disabled') {
        return 'This account has been disabled.';
      } else {
        return e.message ?? 'An unknown authentication error occurred.';
      }
    } catch (e) {
      return 'An unexpected error occurred: $e';
    }
  }

  Future<String?> signUp(String name, String age, String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create the new User Model with starting stats
      UserModel newUser = UserModel(
        uid: userCredential.user!.uid,
        name: name,
        email: email,
        age: int.tryParse(age) ?? 0,
        streak: 0,
        totalStudyTime: 0,
        totalSessions: 0,
        avgProductivity: 0.0,
        weekActivity: [false, false, false, false, false, false, false],
        lastSessionDate: null,
      );

      // Push the model to Firestore using .toMap()
      await _db.collection('users').doc(newUser.uid).set(newUser.toMap());

      return null; 
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return 'The password provided is too weak (minimum 6 characters).';
      } else if (e.code == 'email-already-in-use') {
        return 'An account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        return 'The email address is badly formatted.';
      } else {
        return e.message ?? 'Registration failed.';
      }
    } catch (e) {
      return 'An unexpected error occurred: $e';
    }
  }
}