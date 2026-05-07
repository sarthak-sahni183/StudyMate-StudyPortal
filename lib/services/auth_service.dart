import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges =>
      _auth.authStateChanges();


Future<User?> signUp(
    String email,
    String password) async {

  try {

    UserCredential userCredential =
        await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // CREATE USER DATA
    await _firestoreService.createUserData(
      uid: userCredential.user!.uid,
      email: email,
    );

    // SUCCESS LOG
    await _firestoreService.addAuthLog(
      email: email,
      action: 'signup',
      status: 'success',
    );

    return userCredential.user;

  } catch (e) {

    // FAILURE LOG
    await _firestoreService.addAuthLog(
      email: email,
      action: 'signup',
      status: 'failed',
      error: e.toString(),
    );

    print(e);
    return null;
  }
}

Future<User?> login(
    String email,
    String password) async {

  try {

    UserCredential userCredential =
        await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // SUCCESS LOG
    await _firestoreService.addAuthLog(
      email: email,
      action: 'login',
      status: 'success',
    );

    return userCredential.user;

  } catch (e) {

    // FAILURE LOG
    await _firestoreService.addAuthLog(
      email: email,
      action: 'login',
      status: 'failed',
      error: e.toString(),
    );

    print(e);
    return null;
  }
}
  Future<void> logout() async {
    await _auth.signOut();
  }

  final FirestoreService _firestoreService =
    FirestoreService();

}