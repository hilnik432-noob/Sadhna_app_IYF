import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      final authService = context.read<AuthService>();
      final result = await authService.signInWithGoogle();
      if (result != null && mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/welcome_poster.png', fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                stops: const [0.35, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // IYF Logo
                  ClipOval(
                    child: Image.asset(
                      'assets/images/iyf_logo.jpg',
                      width: 100, height: 100, fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    AppStrings.appName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    AppStrings.tagline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 48),
                  _GoogleSignInButton(loading: _loading, onTap: _signInWithGoogle),
                  const SizedBox(height: 24),
                  Text(
                    'By continuing, you agree to our Terms of Service\nand Privacy Policy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11, fontFamily: 'Poppins'),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _GoogleSignInButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.network(
                      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/480px-Google_%22G%22_logo.svg.png',
                      height: 22,
                      width: 22,
                      errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 24, color: Colors.red),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      AppStrings.signInWithGoogle,
                      style: TextStyle(
                        color: Color(0xFF1A1A2E),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
