import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/facilitator_login_screen.dart';
import '../../features/auth/screens/admin_login_screen.dart';
import '../../features/auth/screens/profile_setup_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/admin/screens/student_list_screen.dart';
import '../../features/admin/screens/facilitator_dashboard_screen.dart';
import '../../features/admin/screens/student_detail_screen.dart';
import '../../features/admin/screens/change_password_screen.dart';
import '../../features/admin/screens/reading_hearing_leaderboard_screen.dart';
import '../constants/access_level.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) async {
      final user = FirebaseAuth.instance.currentUser;
      final loc  = state.matchedLocation;

      const publicRoutes = {'/login', '/splash', '/facilitator-login', '/admin-login'};

      // Not logged in → force to student login (facilitator-login stays
      // reachable directly since it's its own entry point).
      if (user == null) {
        return publicRoutes.contains(loc) ? null : '/login';
      }

      final accessLevel = await _getAccessLevel(user.uid);

      // Facilitators/super_admins never go through student profile-setup —
      // land them straight on their own dashboard from the public routes.
      if (accessLevel != AccessLevel.student && publicRoutes.contains(loc)) {
        return accessLevel == AccessLevel.superAdmin ? '/admin' : '/facilitator';
      }

      // A student who lands on /splash, /login, or /facilitator-login
      // (e.g. already had a session) goes through the normal profile check.
      if (accessLevel == AccessLevel.student && publicRoutes.contains(loc)) {
        final profileComplete = await _isProfileComplete(user.uid);
        return profileComplete ? '/home' : '/profile-setup';
      }

      if (loc == '/profile-setup') return null; // always allowed once logged in

      if (loc == '/home' && accessLevel == AccessLevel.student) {
        final profileComplete = await _isProfileComplete(user.uid);
        if (!profileComplete) return '/profile-setup';
      }

      // Route-level access control: a plain student typing /admin or
      // /facilitator in the URL bar gets bounced back, not let through.
      if ((loc == '/admin' || loc == '/admin-report') && accessLevel != AccessLevel.superAdmin) return '/home';
      if (loc == '/facilitator' && accessLevel == AccessLevel.student) return '/home';

      return null;
    },
    routes: [
      GoRoute(path: '/splash',            builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login',             builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/facilitator-login', builder: (_, __) => const FacilitatorLoginScreen()),
      GoRoute(path: '/admin-login',       builder: (_, __) => const AdminLoginScreen()),
      GoRoute(path: '/profile-setup',     builder: (_, __) => const ProfileSetupScreen()),
      GoRoute(path: '/home',              builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: '/admin',
        builder: (_, __) => const StudentListScreen(title: 'All Students', showLeaderboardButton: true),
      ),
      GoRoute(path: '/admin-report', builder: (_, __) => const ReadingHearingLeaderboardScreen()),
      GoRoute(path: '/facilitator',       builder: (_, __) => const FacilitatorDashboardScreen()),
      GoRoute(
        path: '/student-detail',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return StudentDetailScreen(
            uid: extra['uid'] as String? ?? '',
            name: extra['name'] as String? ?? '',
          );
        },
      ),
      GoRoute(path: '/change-password', builder: (_, __) => const ChangePasswordScreen()),
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

  static Future<AccessLevel> _getAccessLevel(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return AccessLevel.fromString(doc.data()?['accessLevel'] as String?);
    } catch (_) {
      return AccessLevel.student;
    }
  }
}
