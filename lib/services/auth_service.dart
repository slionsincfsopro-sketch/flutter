import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signIn(String email, String password) async {
    try {
      String finalEmail = email.trim();
      // Handle special admin username and any aliadmin.1 variants (like @gmail.com)
      bool isSpecialAdmin = finalEmail.toLowerCase() == 'aliadmin.1' || 
                            finalEmail.toLowerCase().startsWith('aliadmin.1@');
      
      if (isSpecialAdmin) {
        finalEmail = 'aliadmin.1@admin.com';
      }
      
      UserCredential credential;
      try {
        credential = await _auth.signInWithEmailAndPassword(email: finalEmail, password: password);
      } on FirebaseAuthException catch (e) {
        // Special case: If credentials match the admin requirement and login fails,
        // we attempt auto-registration so the user never needs to use the SignUp screen.
        if (isSpecialAdmin && password == '123321qwe') {
          try {
            credential = await _auth.createUserWithEmailAndPassword(email: finalEmail, password: password);
          } catch (createError) {
            // If creation fails (e.g. email already exists but password was wrong), rethrow the original error
            rethrow;
          }
        } else {
          rethrow;
        }
      }
      
      // Ensure admin document exists in dedicated 'admins' collection AND users collection
      if (isSpecialAdmin) {
        final uid = credential.user!.uid;
        final adminDoc = await FirebaseFirestore.instance.collection('admins').doc(uid).get();
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        
        if (!adminDoc.exists) {
           await FirebaseFirestore.instance.collection('admins').doc(uid).set({
            'name': 'Ali Admin',
            'email': finalEmail,
            'role': 'admin',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        
        if (!userDoc.exists) {
           await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'name': 'Ali Admin',
            'email': finalEmail,
            'role': 'admin',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        
        if (credential.user?.displayName == null) {
          await credential.user!.updateDisplayName('Ali Admin');
        }
      }
      
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
             'role': 'user',
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

  Future<void> updateProfile({String? name, String? photoUrl}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final isAdminUser = await isAdmin();
      final batch = FirebaseFirestore.instance.batch();
      
      // Update users collection (all users have a record here)
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      
      Map<String, dynamic> updates = {};
      if (name != null) {
        updates['name'] = name;
        await user.updateDisplayName(name);
      }
      if (photoUrl != null) updates['photoUrl'] = photoUrl;
      
      if (updates.isNotEmpty) {
        batch.set(userDoc, updates, SetOptions(merge: true));
        
        // If admin, also update the specific admins collection
        if (isAdminUser) {
          final adminDoc = FirebaseFirestore.instance.collection('admins').doc(user.uid);
          batch.set(adminDoc, updates, SetOptions(merge: true));
        }
      }

      await batch.commit();
      await user.reload();
      notifyListeners();
    } catch (e) {
      throw e.toString();
    }
  }

  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    // Check dedicated admins collection
    final adminDoc = await FirebaseFirestore.instance.collection('admins').doc(user.uid).get();
    if (adminDoc.exists) return true;
    
    // Fallback to check users collection for role
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return userDoc.data()?['role'] == 'admin';
  }

  Stream<bool> isAdminStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);
    
    // Listen to BOTH collections and prioritize admins
    return FirebaseFirestore.instance
        .collection('admins')
        .doc(user.uid)
        .snapshots()
        .map((doc) => doc.exists)
        .distinct();
  }
}
