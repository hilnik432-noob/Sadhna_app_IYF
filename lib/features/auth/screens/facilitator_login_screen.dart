import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/facilitators.dart';
import '../services/auth_service.dart';

/// Login screen for facilitators and super_admins — separate from the
/// student's Google Sign-In flow. Shows a DROPDOWN of facilitator names
/// (never a dropdown of passwords — only the name picker is a dropdown,
/// the password field below is a normal obscured text field) and signs in
/// via AuthService.signInFacilitator, which maps the picked name to a
/// hidden Firebase Auth login email under the hood.
class FacilitatorLoginScreen extends StatefulWidget {
  const FacilitatorLoginScreen({super.key});

  @override
  State<FacilitatorLoginScreen> createState() => _FacilitatorLoginScreenState();
}

class _FacilitatorLoginScreenState extends State<FacilitatorLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  Facilitator? _selected;
  bool _obscure = true;
  bool _loading = false;

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
      if (mounted) context.go('/home'); // router redirect bounces to /admin or /facilitator
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
      return 'This facilitator account has not been set up yet.';
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
                  ClipOval(
                    child: Image.asset('assets/images/iyf_logo.jpg', width: 72, height: 72, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 20),
                  const Text('Facilitator / Admin Login',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
                  const SizedBox(height: 6),
                  const Text('Select your name and enter your password.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontFamily: 'Poppins')),
                  const SizedBox(height: 28),

                  DropdownButtonFormField<Facilitator>(
                    value: _selected,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Your Name',
                      prefixIcon: Icon(Icons.supervisor_account_rounded, color: AppColors.textSecondary),
                    ),
                    items: kFacilitators.map((f) => DropdownMenuItem(
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
