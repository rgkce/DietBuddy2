import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dietbuddy/constants/colors.dart';
import 'package:dietbuddy/constants/styles.dart';
import 'package:dietbuddy/introScreen/vkiwizard.dart';

class ConfirmationPage extends StatefulWidget {
  const ConfirmationPage({super.key});

  @override
  State<ConfirmationPage> createState() => _ConfirmationPageState();
}

class _ConfirmationPageState extends State<ConfirmationPage> {
  bool _isVerified = false;
  bool _isLoading = true;
  Timer? _timer;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;

    // Eğer kullanıcı zaten doğrulanmışsa direkt yönlendir
    if (_user?.emailVerified == true) {
      _navigateToNextPage();
      return;
    }

    // Periyodik olarak e-posta doğrulamasını kontrol et
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkEmailVerified();
    });

    // İlk kontrolü hemen yap
    _checkEmailVerified();
  }

  void _checkEmailVerified() async {
    try {
      // Kullanıcı bilgilerini yenile
      await _user?.reload();
      _user = _auth.currentUser;

      if (_user?.emailVerified == true) {
        setState(() {
          _isVerified = true;
          _isLoading = false;
        });

        // Başarı mesajını gösterdikten sonra yönlendir
        await Future.delayed(const Duration(seconds: 2));
        _navigateToNextPage();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Email verification check error: $e');
    }
  }

  void _navigateToNextPage() {
    _timer?.cancel();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const VKIWizard()),
      );
    }
  }

  // E-posta doğrulama linkini yeniden gönder
  void _resendVerificationEmail() async {
    try {
      await _user?.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent! Please check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending email: ${e.toString()}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  // Geri dön butonu - çıkış yap ve login sayfasına dön
  void _goBack() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.vibrantBlue,
              AppColors.vibrantPurple,
              AppColors.vibrantPink,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Geri dön butonu
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    onPressed: _goBack,
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: AppColors.primaryColor,
                      size: 28,
                    ),
                  ),
                ),

                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // İkon
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.1,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child:
                              _isVerified
                                  ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.greenAccent,
                                    size: 80,
                                  )
                                  : _isLoading
                                  ? const SizedBox(
                                    width: 80,
                                    height: 80,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                  : const Icon(
                                    Icons.email_outlined,
                                    color: Colors.white,
                                    size: 80,
                                  ),
                        ),

                        const SizedBox(height: 30),

                        // Başlık
                        Text(
                          _isVerified ? "Email Verified!" : "Verify Your Email",
                          style: AppStyles.titleStyle.copyWith(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 20),

                        // Açıklama metni
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            _isVerified
                                ? "Your email has been successfully verified! Redirecting to the next step..."
                                : "We've sent a verification link to:\n${_user?.email ?? ''}\n\nPlease click the link in your email to continue.",
                            style: AppStyles.text.copyWith(
                              fontSize: 16,
                              color: Colors.white,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Butonlar
                        if (!_isVerified) ...[
                          // E-postayı yeniden gönder butonu
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _resendVerificationEmail,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.vibrantPurple,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Resend Verification Email',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Manuel kontrol butonu
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _checkEmailVerified,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: const Text(
                                'I\'ve Verified My Email',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Alt bilgi
                if (!_isVerified)
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.white70,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Didn't receive the email? Check your spam folder or try resending.",
                            style: AppStyles.text.copyWith(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
