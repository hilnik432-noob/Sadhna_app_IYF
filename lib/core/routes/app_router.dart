import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/profile_setup_screen.dart';
import '../../features/home/screens/home_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) async {
      final user = FirebaseAuth.instance.currentUser;
      final loc  = state.matchedLocation;

      // Not logged in → force login
      if (user == null) {
        if (loc == '/login' || loc == '/splash') return null;
        return '/login';
      }

      // Logged in but on splash/login → check profile
      if (loc == '/splash' || loc == '/login') {
        final profileComplete = await _isProfileComplete(user.uid);
        return profileComplete ? '/home' : '/profile-setup';
      }

      // Already on profile-setup → allow
      if (loc == '/profile-setup') return null;

      // On home but profile not complete → redirect
      if (loc == '/home') {
        final profileComplete = await _isProfileComplete(user.uid);
        if (!profileComplete) return '/profile-setup';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash',        builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login',         builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/profile-setup', builder: (_, __) => const ProfileSetupScreen()),
      GoRoute(path: '/home',          builder: (_, __) => const HomeScreen()),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );

  static Future<bool> _isProfileComplete(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return doc.data()?['profileComplete'] == true;
    } catch (_) {
      return false;
    }
  }
}
