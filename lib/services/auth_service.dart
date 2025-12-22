import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      notifyListeners();
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      
      // Try to save extra details, but don't fail the whole sign up if this part errors (e.g. network flaky)
      try {
        if (credential.user != null) {
           await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
             'name': name,
             'email': email,
             'createdAt': FieldValue.serverTimestamp(),
           });
           await credential.user!.updateDisplayName(name);
        }
      } catch (e) {
        print("Warning: Failed to save user profile: $e");
      }
      
      notifyListeners();
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }
}
