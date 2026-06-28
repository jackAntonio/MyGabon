import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/verification_provider.dart';
import '../config/theme.dart';

/// Phone verification screen
class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  late TextEditingController _phoneController;
  late TextEditingController _otpController;
  bool _showOtpInput = false;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _otpController = TextEditingController();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vérifier votre numéro'),
        elevation: 0,
      ),
      body: Consumer<VerificationProvider>(
        builder: (context, verifyProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status card
                if (verifyProvider.isPhoneVerified)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified,
                            color: Colors.green, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Numéro vérifié ✓',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (verifyProvider
                                      .currentUserVerification?.phoneNumber !=
                                  null)
                                Text(
                                  verifyProvider
                                      .currentUserVerification!.phoneNumber!,
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontSize: 14,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Étape 1: Entrez votre numéro',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nous enverrons un code de vérification à votre numéro',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),

                      // Phone input
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Numéro de téléphone',
                          prefixText: '+241 ',
                          hintText: '6 XX XX XX XX',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabled: !verifyProvider.isVerifying,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Send OTP button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: verifyProvider.isVerifying
                              ? null
                              : () => _sendOtp(context, verifyProvider),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: verifyProvider.isVerifying
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Envoyer le code',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                    ],
                  ),

                if (_showOtpInput && !verifyProvider.isPhoneVerified) ...[
                  const SizedBox(height: 32),
                  const Text(
                    'Étape 2: Entrez le code',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Entrez le code OTP à 6 chiffres envoyé à votre numéro',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),

                  // OTP input
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      letterSpacing: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: '000000',
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabled: !verifyProvider.isVerifying,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Countdown
                  Center(
                    child: Column(
                      children: [
                        if (verifyProvider.otpResendCountdown > 0)
                          Text(
                            'Renvoyer le code dans ${verifyProvider.otpResendCountdown}s',
                            style: TextStyle(color: Colors.grey[600]),
                          )
                        else
                          TextButton(
                            onPressed: () => _sendOtp(context, verifyProvider),
                            child: const Text('Renvoyer le code'),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Verify button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: verifyProvider.isVerifying
                          ? null
                          : () => _verifyOtp(context, verifyProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: verifyProvider.isVerifying
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text(
                              'Vérifier le code',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],

                // Error message
                if (verifyProvider.verificationError != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            verifyProvider.verificationError!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _sendOtp(
    BuildContext context,
    VerificationProvider provider,
  ) async {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un numéro')),
      );
      return;
    }

    final success = await provider.sendPhoneOTP(_phoneController.text);
    if (success) {
      setState(() => _showOtpInput = true);
      _startCountdown(provider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code OTP envoyé')),
      );
    }
  }

  Future<void> _verifyOtp(
    BuildContext context,
    VerificationProvider provider,
  ) async {
    if (_otpController.text.length != 6) {
      provider.clearError();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrez un code à 6 chiffres')),
      );
      return;
    }

    final success = await provider.verifyPhoneOTP(
      _phoneController.text,
      _otpController.text,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Numéro vérifié avec succès!')),
      );
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pop(context);
      });
    }
  }

  void _startCountdown(VerificationProvider provider) {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      provider.decrementResendCountdown();
      if (provider.otpResendCountdown <= 0) {
        timer.cancel();
      }
    });
  }
}
