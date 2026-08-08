import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/access_level.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/facilitators.dart';
import '../services/auth_service.dart';

/// Dedicated super_admin login — separate page from FacilitatorLoginScreen
/// per design request, even though the underlying mechanism is identical
/// (dropdown name picker + password, via AuthService.signInFacilitator).
/// The dropdown here is restricted to kSuperAdminDikshitNames only.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  Facilitator? _selected;
  bool _obscure = true;
  bool _loading = false;

  List<Facilitator> get _superAdmins =>
      kFacilitators.where((f) => kSuperAdminDikshitNames.contains(f.dikshitName)).toList();

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate() || _selected == null) return;
    setState(() => _loading = true);
    try {
      await context.read<AuthService>().signInFacilitator(_selected!, _passwordCtrl.text);
      if (mounted) context.go('/home'); // router redirect bounces to /admin
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${_friendlyError(e)}'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('wrong-password') || msg.contains('invalid-credential')) {
      return 'Incorrect password.';
    }
    if (msg.contains('user-not-found')) {
      return 'This admin account has not been set up yet.';
    }
    return 'Please check your password and try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.admin_panel_settings_rounded, size: 56, color: AppColors.primary),
                  const SizedBox(height: 20),
                  const Text('Admin Login',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
                  const SizedBox(height: 6),
                  const Text('Super admin access — select your name and enter your password.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontFamily: 'Poppins')),
                  const SizedBox(height: 28),

                  DropdownButtonFormField<Facilitator>(
                    value: _selected,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Your Name',
                      prefixIcon: Icon(Icons.admin_panel_settings_outlined, color: AppColors.textSecondary),
                    ),
                    items: _superAdmins.map((f) => DropdownMenuItem(
                      value: f,
                      child: Text(f.displayName,
                          style: const TextStyle(fontSize: 13, fontFamily: 'Poppins'),
                          overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (v) => setState(() => _selected = v),
                    validator: (v) => v == null ? 'Please select your name' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
                    onFieldSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _login,
                      icon: _loading
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.login_rounded),
                      label: Text(_loading ? 'Signing in...' : 'Login',
                          style: const TextStyle(fontSize: 15, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Back to student login',
                        style: TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary)),
                  ),
                  TextButton(
                    onPressed: () => context.pushReplacement('/facilitator-login'),
                    child: const Text('Facilitator Login instead',
                        style: TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
