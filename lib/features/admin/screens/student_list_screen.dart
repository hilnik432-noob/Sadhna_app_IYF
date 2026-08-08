import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/services/auth_service.dart';
import '../services/admin_service.dart';

/// Shared list screen for BOTH dashboards:
///   - super_admin: StudentListScreen(title: 'All Students', facilitatorDikshitName: null)
///   - facilitator: StudentListScreen(title: 'My Students', facilitatorDikshitName: myOwnDikshitName)
/// One widget, parametrized — avoids maintaining two near-identical list UIs.
class StudentListScreen extends StatefulWidget {
  final String title;
  final String? facilitatorDikshitName;
  final bool showLeaderboardButton;

  const StudentListScreen({
    super.key,
    required this.title,
    this.facilitatorDikshitName,
    this.showLeaderboardButton = false,
  });

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final _adminService = AdminService();
  late Future<List<StudentSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = _adminService.fetchStudents(facilitatorDikshitName: widget.facilitatorDikshitName);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _adminService.fetchStudents(facilitatorDikshitName: widget.facilitatorDikshitName);
    });
    await _future;
  }

  bool get _isPasswordLogin =>
      FirebaseAuth.instance.currentUser?.providerData
          .any((p) => p.providerId == 'password') ?? false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.self_improvement_rounded),
            tooltip: 'My Own Sadhna Log',
            onPressed: () => context.push('/home'),
          ),
          if (widget.showLeaderboardButton)
            IconButton(
              icon: const Icon(Icons.leaderboard_rounded),
              tooltip: 'Reading & Hearing Report',
              onPressed: () => context.push('/admin-report',
                  extra: {'facilitatorDikshitName': widget.facilitatorDikshitName}),
            ),
          if (_isPasswordLogin)
            IconButton(
              icon: const Icon(Icons.password_rounded),
              tooltip: 'Change password',
              onPressed: () => context.push('/change-password'),
            ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () async {
              await context.read<AuthService>().signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<StudentSummary>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }
            if (snap.hasError) {
              return Center(child: Text('Failed to load students: ${snap.error}',
                  style: const TextStyle(fontFamily: 'Poppins')));
            }
            final students = snap.data ?? [];
            if (students.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 120),
                Icon(Icons.people_outline_rounded, size: 64, color: AppColors.textSecondary),
                SizedBox(height: 12),
                Center(child: Text('No students found', style: TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary))),
              ]);
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: students.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final s = students[i];
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(
                        s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                      ),
                    ),
                    title: Text(s.name.isNotEmpty ? s.name : s.email,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Poppins')),
                    subtitle: Text(
                      [s.groupName, s.facilitatorDisplay].where((v) => v.isNotEmpty).join(' • '),
                      style: const TextStyle(fontSize: 12, fontFamily: 'Poppins'),
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                    onTap: () => context.push('/student-detail', extra: {'uid': s.uid, 'name': s.name}),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
