import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../auth/services/auth_service.dart';
import '../../sadhana/services/sadhana_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final sadhanaService = context.watch<SadhanaService>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.accent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.accent, Color(0xFF4338CA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      CircleAvatar(
                        radius: 42,
                        backgroundColor: Colors.white24,
                        backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                        child: user?.photoURL == null
                            ? const Icon(Icons.person, size: 40, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        user?.displayName ?? 'Devotee',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
                      ),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Poppins'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _StatsRow(streakCount: sadhanaService.streakCount, historyCount: sadhanaService.history.length),
                const SizedBox(height: 20),
                const _SectionTitle('Account'),
                _SettingsTile(icon: Icons.person_outline_rounded, title: 'Edit Profile', onTap: () {}),
                _SettingsTile(icon: Icons.notifications_outlined, title: 'Notifications', onTap: () {}),
                _SettingsTile(icon: Icons.language_rounded, title: 'Language', onTap: () {}),
                const SizedBox(height: 16),
                const _SectionTitle('About'),
                _SettingsTile(icon: Icons.info_outline_rounded, title: 'About IYF', onTap: () {}),
                _SettingsTile(icon: Icons.privacy_tip_outlined, title: 'Privacy Policy', onTap: () {}),
                _SettingsTile(icon: Icons.description_outlined, title: 'Terms of Service', onTap: () {}),
                _SettingsTile(icon: Icons.star_outline_rounded, title: 'Rate the App', onTap: () {}),
                const SizedBox(height: 16),
                _LogoutButton(),
                const SizedBox(height: 32),
                const Center(
                  child: Text(
                    'Hare Krishna! 🙏',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontStyle: FontStyle.italic, fontFamily: 'Poppins'),
                  ),
                ),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int streakCount;
  final int historyCount;

  const _StatsRow({required this.streakCount, required this.historyCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(value: '$streakCount', label: 'Day Streak', icon: '🔥'),
        const SizedBox(width: 12),
        _StatCard(value: '$historyCount', label: 'Total Logs', icon: '📿'),
        const SizedBox(width: 12),
        _StatCard(value: '0', label: 'Donations', icon: '🙏'),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final String icon;

  const _StatCard({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontFamily: 'Poppins'), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.2, fontFamily: 'Poppins'),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.textPrimary, size: 22),
        title: Text(title, style: const TextStyle(fontSize: 14, fontFamily: 'Poppins')),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: AppColors.error.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
        title: const Text(AppStrings.logout, style: TextStyle(fontSize: 14, fontFamily: 'Poppins', color: AppColors.error, fontWeight: FontWeight.w600)),
        onTap: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Logout', style: TextStyle(fontFamily: 'Poppins')),
              content: const Text('Are you sure you want to logout?', style: TextStyle(fontFamily: 'Poppins')),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Logout', style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
          );
          if (confirm == true && context.mounted) {
            await context.read<AuthService>().signOut();
            context.go('/login');
          }
        },
      ),
    );
  }
}
