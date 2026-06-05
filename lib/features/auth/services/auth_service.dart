import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
        'role': 'student',
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
    await _db.collection('users').doc(uid).update(data);
    notifyListeners();
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection('users').doc(user.uid).get();
    return doc.data();
  }

  Future<void> signOut() async {
    if (!kIsWeb) await _googleSignIn?.signOut();
    await _auth.signOut();
    notifyListeners();
  }
}
