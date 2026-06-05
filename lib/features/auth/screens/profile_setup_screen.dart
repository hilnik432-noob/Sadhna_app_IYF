import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/facilitators.dart';
import '../../sadhana/models/sadhana_entry.dart';
import '../services/auth_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _nameCtrl      = TextEditingController();
  final _ageCtrl       = TextEditingController();
  final _groupCtrl     = TextEditingController();
  final _mobileCtrl    = TextEditingController();

  UserRole?   _category;
  Facilitator? _facilitator;
  bool        _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _ageCtrl.dispose();
    _groupCtrl.dispose(); _mobileCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) {
      _showError('Please select your category.');
      return;
    }
    if (_facilitator == null) {
      _showError('Please select your facilitator.');
      return;
    }

    setState(() => _saving = true);
    try {
      await context.read<AuthService>().updateProfile({
        'name':              _nameCtrl.text.trim(),
        'age':               int.tryParse(_ageCtrl.text.trim()) ?? 0,
        'groupName':         _groupCtrl.text.trim(),
        'phone':             _mobileCtrl.text.trim(),
        'role':              _category!.name,
        'facilitatorName':   _facilitator!.dikshitName,
        'facilitatorDisplay': _facilitator!.displayName,
        'profileComplete':   true,
      });
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) _showError('Failed to save: $e');
    }
    if (mounted) setState(() => _saving = false);
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: AppColors.error));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // Header
                Center(
                  child: Column(children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFF6B21A8)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 16),
                    const Text('Complete Your Profile',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins')),
                    const SizedBox(height: 6),
                    const Text('Fill in your details so your facilitator can\ntrack your spiritual progress.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary,
                            fontSize: 13, fontFamily: 'Poppins', height: 1.5)),
                  ]),
                ),
                const SizedBox(height: 32),

                // Name
                _Label('Full Name *'),
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Enter your full name',
                    prefixIcon: Icon(Icons.person_rounded, color: AppColors.textSecondary),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),

                // Age + Mobile in a row
                Row(children: [
                  Expanded(
                    flex: 2,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _Label('Age *'),
                      TextFormField(
                        controller: _ageCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          hintText: 'Age',
                          prefixIcon: Icon(Icons.cake_rounded, color: AppColors.textSecondary),
                        ),
                        validator: (v) {
                          final age = int.tryParse(v ?? '');
                          if (age == null || age < 10 || age > 80) return 'Valid age';
                          return null;
                        },
                      ),
                    ]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _Label('Mobile No. *'),
                      TextFormField(
                        controller: _mobileCtrl,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        maxLength: 10,
                        decoration: const InputDecoration(
                          hintText: '10 digit number',
                          prefixIcon: Icon(Icons.phone_rounded, color: AppColors.textSecondary),
                          counterText: '',
                        ),
                        validator: (v) => (v == null || v.length != 10) ? 'Enter 10 digits' : null,
                      ),
                    ]),
                  ),
                ]),
                const SizedBox(height: 16),

                // Category
                _Label('Category *'),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: UserRole.values.map((role) => RadioListTile<UserRole>(
                      value: role, groupValue: _category,
                      activeColor: AppColors.primary,
                      dense: true,
                      title: Text(role.label,
                          style: const TextStyle(fontSize: 14, fontFamily: 'Poppins')),
                      onChanged: (v) => setState(() => _category = v),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Group name
                _Label('Group Name *'),
                TextFormField(
                  controller: _groupCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Govardhan Group, Vrindavan Group',
                    prefixIcon: Icon(Icons.group_rounded, color: AppColors.textSecondary),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Group name is required' : null,
                ),
                const SizedBox(height: 16),

                // Facilitator dropdown
                _Label('Your Facilitator *'),
                DropdownButtonFormField<Facilitator>(
                  value: _facilitator,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.supervisor_account_rounded, color: AppColors.textSecondary),
                    hintText: 'Select your facilitator',
                  ),
                  items: kFacilitators.map((f) => DropdownMenuItem(
                    value: f,
                    child: Text(f.displayName,
                        style: const TextStyle(fontSize: 13, fontFamily: 'Poppins'),
                        overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (v) => setState(() => _facilitator = v),
                  validator: (v) => v == null ? 'Select your facilitator' : null,
                ),
                const SizedBox(height: 32),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.check_circle_rounded),
                    label: Text(_saving ? 'Saving...' : 'Save & Continue',
                        style: const TextStyle(fontSize: 16, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _Label(String text) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Text(text,
      style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600,
          fontSize: 13, color: AppColors.textPrimary)),
);
