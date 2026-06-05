import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class DonationsScreen extends StatefulWidget {
  const DonationsScreen({super.key});

  @override
  State<DonationsScreen> createState() => _DonationsScreenState();
}

class _DonationsScreenState extends State<DonationsScreen> {
  late Razorpay _razorpay;
  int? _selectedAmount;
  final _customController = TextEditingController();
  bool _processing = false;

  static const _presetAmounts = [108, 251, 501, 1001, 2501, 5001];

  static const _causes = [
    ('🍛', 'Feed a Devotee', 'Sponsor prasad for one devotee for a day'),
    ('📚', 'Gita Distribution', 'Donate a Bhagavad Gita to someone in need'),
    ('🕌', 'Temple Seva', 'Contribute to temple maintenance and festivals'),
    ('🎓', 'Education', 'Support devotional education programs'),
  ];

  int? _selectedCause = 0;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _customController.dispose();
    super.dispose();
  }

  int get _amountInPaise {
    if (_selectedAmount != null) return _selectedAmount! * 100;
    final custom = int.tryParse(_customController.text);
    return (custom ?? 0) * 100;
  }

  void _startPayment() {
    final amount = _amountInPaise;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or enter an amount'), backgroundColor: AppColors.error),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final options = {
      'key': 'YOUR_RAZORPAY_KEY_ID', // TODO: Replace with your Razorpay key
      'amount': amount,
      'currency': 'INR',
      'name': 'Sadhana App',
      'description': _causes[_selectedCause ?? 0].$2,
      'prefill': {
        'name': user?.displayName ?? '',
        'email': user?.email ?? '',
      },
      'theme': {'color': '#FF6B35'},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('donations').add({
        'userId': user.uid,
        'userName': user.displayName ?? '',
        'amount': _amountInPaise ~/ 100,
        'cause': _causes[_selectedCause ?? 0].$2,
        'paymentId': response.paymentId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🙏', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              const Text('Thank You!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
              const SizedBox(height: 8),
              Text(
                'Your donation of ₹${_amountInPaise ~/ 100} has been received.\nHare Krishna! 🌸',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontFamily: 'Poppins', height: 1.5),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
          ],
        ),
      );
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: ${response.message}'), backgroundColor: AppColors.error),
      );
    }
  }

  void _onExternalWallet(ExternalWalletResponse response) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donate')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DonationHeader(),
            const SizedBox(height: 24),

            const Text('Select a Cause', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
            const SizedBox(height: 12),
            ..._causes.asMap().entries.map((entry) {
              final i = entry.key;
              final cause = entry.value;
              return _CauseTile(
                emoji: cause.$1,
                title: cause.$2,
                subtitle: cause.$3,
                selected: _selectedCause == i,
                onTap: () => setState(() => _selectedCause = i),
              );
            }),

            const SizedBox(height: 24),
            const Text(AppStrings.selectAmount, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
            const SizedBox(height: 12),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _presetAmounts.map((amount) {
                final selected = _selectedAmount == amount;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAmount = amount;
                      _customController.clear();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selected ? AppColors.primary : AppColors.divider),
                    ),
                    child: Text(
                      '₹$amount',
                      style: TextStyle(
                        color: selected ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),
            TextField(
              controller: _customController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() => _selectedAmount = null),
              decoration: const InputDecoration(
                hintText: AppStrings.customAmount,
                prefixText: '₹ ',
                prefixStyle: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
              ),
            ),

            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _processing ? null : _startPayment,
              icon: _processing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.favorite_rounded),
              label: Text(_processing ? 'Processing...' : AppStrings.proceedToPay),
            ),

            const SizedBox(height: 16),
            const _SecurePaymentBadge(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _DonationHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B21A8), Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🙏', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 10),
          const Text(
            AppStrings.donateTitle,
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
          ),
          const SizedBox(height: 6),
          const Text(
            AppStrings.donateSubtitle,
            style: TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Poppins', height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _CauseTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _CauseTile({required this.emoji, required this.title, required this.subtitle, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.primary : AppColors.divider, width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Poppins')),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontFamily: 'Poppins')),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _SecurePaymentBadge extends StatelessWidget {
  const _SecurePaymentBadge();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_rounded, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        const Text('Secured by Razorpay', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontFamily: 'Poppins')),
      ],
    );
  }
}
