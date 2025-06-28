import 'package:dietbuddy/constants/colors.dart';
import 'package:dietbuddy/constants/styles.dart';
import 'package:dietbuddy/helperScreens/confirmation_page.dart';
import 'package:dietbuddy/services/firebase/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  final FocusNode nameFocus = FocusNode();
  final FocusNode emailFocus = FocusNode();
  final FocusNode phoneFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();

  bool _isChecked = false;
  bool _isFormValid = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController.addListener(_validateForm);
    emailController.addListener(_validateForm);
    phoneController.addListener(_validateForm);
    passwordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    nameFocus.dispose();
    emailFocus.dispose();
    phoneFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _isFormValid =
          nameController.text.trim().isNotEmpty &&
          emailController.text.trim().isNotEmpty &&
          phoneController.text.trim().isNotEmpty &&
          passwordController.text.trim().isNotEmpty &&
          _isValidEmail(emailController.text.trim()) &&
          _isValidPassword(passwordController.text.trim()) &&
          _isChecked;
    });
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidPassword(String password) {
    return password.length >= 6;
  }

  void _saveCredentialsIfRemember() async {
    if (_rememberMe) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', true);
      await prefs.setString('saved_email', emailController.text.trim());
      // Note: Storing password in SharedPreferences is not secure
      // Consider using secure storage for production apps
      await prefs.setString('saved_password', passwordController.text.trim());
    }
  }

  Future<void> _createAccount() async {
    if (!_isFormValid) {
      _showSnackBar("Lütfen tüm alanları doğru şekilde doldurun.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (result.isSuccess) {
        _saveCredentialsIfRemember();

        if (mounted) {
          _showSnackBar(
            result.message ??
                "Hesap başarıyla oluşturuldu. Doğrulama e-postasını kontrol edin.",
            isSuccess: true,
          );

          // Navigate to confirmation page
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const ConfirmationPage()),
          );
        }
      } else {
        if (mounted) {
          _showSnackBar(result.message ?? "Hesap oluşturulamadı");
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("Beklenmeyen bir hata oluştu: ${e.toString()}");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildTextField({
    required String labelText,
    required String hintText,
    required IconData icon,
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    bool obscureText = false,
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        style: const TextStyle(color: AppColors.primaryColor),
        keyboardType:
            labelText == 'Email'
                ? TextInputType.emailAddress
                : labelText == 'Phone'
                ? TextInputType.phone
                : TextInputType.text,
        textInputAction:
            nextFocus != null ? TextInputAction.next : TextInputAction.done,
        onSubmitted: (_) {
          if (nextFocus != null) {
            FocusScope.of(context).requestFocus(nextFocus);
          } else {
            FocusScope.of(context).unfocus();
          }
        },
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: const TextStyle(color: AppColors.primaryColor),
          hintText: hintText,
          hintStyle: TextStyle(color: AppColors.primaryColor.withOpacity(0.5)),
          prefixIcon: Icon(icon, color: AppColors.primaryColor),
          suffixIcon:
              isPassword
                  ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.primaryColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  )
                  : null,
          filled: true,
          fillColor: AppColors.primaryColor.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: const BorderSide(color: AppColors.primaryColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: const BorderSide(color: AppColors.primaryColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: const BorderSide(color: AppColors.primaryColor),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
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
            top: true,
            bottom: false,
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: screenHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new),
                            color: AppColors.primaryColor,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const Spacer(),
                          Text(
                            "Sign up",
                            style: AppStyles.pageTitle.copyWith(
                              color: AppColors.primaryColor,
                            ),
                          ),
                          const Spacer(flex: 2),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: screenHeight * 0.2,
                        child: Image.asset("assets/images/db_logo.png"),
                      ),
                      const SizedBox(height: 30),
                      _buildTextField(
                        labelText: 'Fullname',
                        hintText: 'Your name here',
                        icon: Icons.person,
                        controller: nameController,
                        focusNode: nameFocus,
                        nextFocus: emailFocus,
                      ),
                      _buildTextField(
                        labelText: 'Email',
                        hintText: 'Your email@gmail.com',
                        icon: Icons.email_outlined,
                        controller: emailController,
                        focusNode: emailFocus,
                        nextFocus: phoneFocus,
                      ),
                      _buildTextField(
                        labelText: 'Phone',
                        hintText: 'Your phone number',
                        icon: Icons.phone,
                        controller: phoneController,
                        focusNode: phoneFocus,
                        nextFocus: passwordFocus,
                      ),
                      _buildTextField(
                        labelText: 'Password',
                        hintText: '********',
                        icon: Icons.lock_outline,
                        controller: passwordController,
                        focusNode: passwordFocus,
                        obscureText: _obscurePassword,
                        isPassword: true,
                      ),
                      const SizedBox(height: 10),
                      // Remember Me Checkbox
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (bool? value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                            checkColor: AppColors.vibrantBlue,
                            fillColor: WidgetStateProperty.all(Colors.white),
                          ),
                          Text(
                            "Remember Me",
                            style: AppStyles.subtitleStyle.copyWith(
                              color: AppColors.primaryColor,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Checkbox(
                            value: _isChecked,
                            onChanged: (bool? value) {
                              setState(() {
                                _isChecked = value ?? false;
                              });
                              _validateForm();
                            },
                            checkColor: AppColors.titleColor,
                            fillColor: WidgetStateProperty.all(Colors.white),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      title: const Text(
                                        'Terms & Conditions',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      content: const SingleChildScrollView(
                                        child: Text(
                                          '''
By signing up, you agree to our Terms & Conditions. 
This includes how we handle your personal data, app usage rules, 
and your responsibilities as a user.

Please review the full agreement before proceeding.
                                          ''',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            setState(() {
                                              _isChecked = false;
                                            });
                                            _validateForm();
                                          },
                                          child: Text(
                                            'Decline',
                                            style: AppStyles.textStyle.copyWith(
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppColors.vibrantBlue,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            setState(() {
                                              _isChecked = true;
                                            });
                                            _validateForm();
                                          },
                                          child: Text(
                                            'Accept',
                                            style: AppStyles.textStyle.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: Text(
                                "I agree to Terms & Conditions",
                                style: AppStyles.subtitleStyle.copyWith(
                                  color: AppColors.primaryColor,
                                  fontSize: 16,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      // Updated Sign Up Button with gradient design from second file
                      GestureDetector(
                        onTap:
                            _isFormValid && !_isLoading ? _createAccount : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 56,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient:
                                _isFormValid
                                    ? const LinearGradient(
                                      colors: [
                                        AppColors.chartColor,
                                        AppColors.vibrantBlue,
                                      ],
                                    )
                                    : null,
                            color: _isFormValid ? null : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow:
                                _isFormValid
                                    ? [
                                      const BoxShadow(
                                        color: AppColors.shadowColor,
                                        blurRadius: 6,
                                        offset: Offset(0, 4),
                                      ),
                                    ]
                                    : [],
                          ),
                          child: Center(
                            child:
                                _isLoading
                                    ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                    : Text(
                                      "Create Account",
                                      style: AppStyles.titleStyle.copyWith(
                                        fontSize: 18,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account? ",
                            style: AppStyles.subtitleStyle.copyWith(
                              color: AppColors.primaryColor,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Text(
                              "Sign In",
                              style: AppStyles.subtitleStyle.copyWith(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
