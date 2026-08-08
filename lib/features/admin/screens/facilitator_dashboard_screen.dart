import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_colors.dart';
import 'student_list_screen.dart';

/// Thin wrapper that looks up the SIGNED-IN facilitator's own dikshitName
/// (stored as `facilitatorDikshitName` on their own user doc — see
/// scripts/seed_facilitator_accounts.py) before handing off to the shared
/// StudentListScreen, scoped to just their students. Needed because
/// GoRoute builders are synchronous but this lookup isn't.
class FacilitatorDashboardScreen extends StatelessWidget {
  const FacilitatorDashboardScreen({super.key});

  Future<String?> _loadOwnDikshitName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data()?['facilitatorDikshitName'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _loadOwnDikshitName(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
        }
        if (snap.data == null) {
          return const Scaffold(
            body: Center(child: Text(
              'Your account is not linked to a facilitator name yet.\nContact the admin to fix this.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary),
            )),
          );
        }
        return StudentListScreen(title: 'My Students', facilitatorDikshitName: snap.data);
      },
    );
  }
}
