import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/access_level.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/facilitators.dart';
import '../../../core/constants/groups.dart';
import '../../auth/screens/profile_setup_screen.dart';
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
                        backgroundImage: user?.photoURL != null
                            ? NetworkImage(user!.photoURL!) as ImageProvider
                            : const AssetImage('assets/images/iyf_logo.jpg'),
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
                const _BackToDashboardTile(),
                const _SectionTitle('Account'),
                _SettingsTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Edit Profile',
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _EditProfileSheet(
                      onSave: (data) => context.read<AuthService>().updateProfile(data),
                    ),
                  ),
                ),
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

/// Shown only to facilitator/super_admin accounts that are ALSO practicing
/// students (both real accounts in this app are dual-role) — a way back
/// to their dashboard from the normal student flow, mirroring the "My Own
/// Sadhna Log" button added on their dashboard's side. Renders nothing for
/// plain student accounts.
class _BackToDashboardTile extends StatelessWidget {
  const _BackToDashboardTile();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AccessLevel>(
      future: context.read<AuthService>().getAccessLevel(),
      builder: (context, snap) {
        final level = snap.data;
        if (level == null || level == AccessLevel.student) return const SizedBox.shrink();

        final isSuperAdmin = level == AccessLevel.superAdmin;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _SettingsTile(
            icon: Icons.admin_panel_settings_rounded,
            title: isSuperAdmin ? 'Go to Admin Dashboard' : 'Go to Facilitator Dashboard',
            onTap: () => context.push(isSuperAdmin ? '/admin' : '/facilitator'),
          ),
        );
      },
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

// ── Edit Profile bottom sheet ─────────────────────────────────────────────────
class _EditProfileSheet extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic>) onSave;
  const _EditProfileSheet({required this.onSave});
  @override State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _mobileCtrl = TextEditingController();
  Facilitator? _facilitator;
  IYFGroup?    _group;
  bool _saving = false;

  @override
  void dispose() { _mobileCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
          left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Edit Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
        const SizedBox(height: 4),
        const Text('Name and age can only be changed by contacting admin.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Poppins')),
        const SizedBox(height: 20),
        DropdownButtonFormField<IYFGroup>(
          value: _group,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Change Group',
            prefixIcon: Icon(Icons.group_rounded, color: AppColors.textSecondary),
          ),
          items: kGroups.map((g) => DropdownMenuItem(
            value: g,
            child: Text(g.displayName,
                style: const TextStyle(fontSize: 14, fontFamily: 'Poppins')),
          )).toList(),
          onChanged: (v) => setState(() => _group = v),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _mobileCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Mobile No.',
            prefixIcon: Icon(Icons.phone_rounded, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<Facilitator>(
          value: _facilitator,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Change Facilitator',
            prefixIcon: Icon(Icons.supervisor_account_rounded, color: AppColors.textSecondary),
          ),
          items: kFacilitators.map((f) => DropdownMenuItem(
            value: f,
            child: Text(f.displayName,
                style: const TextStyle(fontSize: 13, fontFamily: 'Poppins'),
                overflow: TextOverflow.ellipsis),
          )).toList(),
          onChanged: (v) => setState(() => _facilitator = v),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _saving ? null : () async {
              setState(() => _saving = true);
              final data = <String, dynamic>{};
              if (_group != null) { data['groupName'] = _group!.name; data['groupCode'] = _group!.code; }
              if (_mobileCtrl.text.trim().isNotEmpty) data['phone'] = _mobileCtrl.text.trim();
              if (_facilitator != null) {
                data['facilitatorName']    = _facilitator!.dikshitName;
                data['facilitatorDisplay'] = _facilitator!.displayName;
              }
              if (data.isNotEmpty) await widget.onSave(data);
              if (mounted) Navigator.pop(context);
            },
            child: Text(_saving ? 'Saving...' : 'Save Changes',
                style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
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
