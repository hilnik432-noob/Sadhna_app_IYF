import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/access_level.dart';
import '../../../core/constants/facilitators.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // GoogleSignIn is only initialized on mobile — web uses signInWithPopup instead
  late final GoogleSignIn? _googleSignIn = kIsWeb ? null : GoogleSignIn();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        // Web: use Firebase popup — no separate client ID needed
        final provider = GoogleAuthProvider();
        provider.addScope('email');
        provider.addScope('profile');
        userCredential = await _auth.signInWithPopup(provider);
      } else {
        // Mobile: use google_sign_in package
        final GoogleSignInAccount? googleUser = await _googleSignIn?.signIn();
        if (googleUser == null) return null;
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await _auth.signInWithCredential(credential);
      }

      await _saveUserToFirestore(userCredential.user!);
      notifyListeners();
      return userCredential;
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      rethrow;
    }
  }

  Future<void> _saveUserToFirestore(User user) async {
    final userRef = _db.collection('users').doc(user.uid);
    final docSnap = await userRef.get();

    if (!docSnap.exists) {
      // First time login — create full profile
      await userRef.set({
        'uid': user.uid,
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'phone': '',
        'photoUrl': user.photoURL ?? '',
        'city': '',
        'temple': '',
        'batch': '',
        'mentor': '',
        'sadhanaCategory': 'student', // student's sadhna-card category (UserRole) — NOT a permission
        'accessLevel': AccessLevel.student.value, // permission level — see access_level.dart
        'joinedDate': FieldValue.serverTimestamp(),
        'streakCount': 0,
        'totalSadhanaLogs': 0,
        'lastSadhanaDate': null,
        'fcmToken': '',
        'isActive': true,
      });
    } else {
      // Returning user — update live fields only
      await userRef.update({
        'name': user.displayName ?? docSnap['name'],
        'photoUrl': user.photoURL ?? docSnap['photoUrl'],
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    // set(merge:true) instead of update(): update() throws if the doc
    // doesn't exist yet, which happens for any account whose initial
    // _saveUserToFirestore write never completed (e.g. closed the app
    // mid-sign-in) — merge self-heals that instead of erroring out.
    await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
    notifyListeners();
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection('users').doc(user.uid).get();
    return doc.data();
  }

  /// Reads the current account's permission level. Defaults to `student`
  /// if unset (covers every pre-existing account created before this field
  /// existed) — see access_level.dart for what each level can see.
  Future<AccessLevel> getAccessLevel() async {
    final profile = await getUserProfile();
    return AccessLevel.fromString(profile?['accessLevel'] as String?);
  }

  /// Facilitator/admin sign-in: the login screen shows a dropdown of
  /// [Facilitator] names (not emails — most facilitators have no account-
  /// linked inbox on file), which resolves to [Facilitator.loginEmail], a
  /// hidden Firebase Auth identifier. The password is whatever was set for
  /// that account (see scripts/seed_facilitator_accounts.py for how these
  /// accounts get created) — never stored anywhere outside Firebase Auth's
  /// own secure store.
  Future<UserCredential> signInFacilitator(Facilitator facilitator, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: facilitator.loginEmail,
      password: password,
    );
    notifyListeners();
    return credential;
  }

  /// Lets a signed-in facilitator set their own new password — the only
  /// self-service recovery path available to synthetic-login accounts,
  /// since they have no real inbox for Firebase's password-reset email.
  Future<void> changePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No signed-in user to change password for.');
    await user.updatePassword(newPassword);
  }

  Future<void> signOut() async {
    if (!kIsWeb) await _googleSignIn?.signOut();
    await _auth.signOut();
    notifyListeners();
  }
}
