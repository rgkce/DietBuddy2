import 'package:dietbuddy/constants/colors.dart';
import 'package:dietbuddy/constants/styles.dart';
import 'package:dietbuddy/helperScreens/password_changed.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({super.key});

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final FocusNode _confirmPasswordFocus = FocusNode();

  String? _passwordError;
  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 15),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(Icons.arrow_back_ios_new, size: 30),
                            color: AppColors.primaryColor,
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              'Change Password',
                              style: AppStyles.pageTitle.copyWith(
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child: SizedBox(
                          height: screenWidth * 0.5,
                          width: screenWidth * 0.5,
                          child: Image.asset('assets/images/db_logo.png'),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child: Text(
                          'Create a new password and please never share it with anyone for safe use.',
                          style: AppStyles.text.copyWith(
                            color: AppColors.primaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 45),
                      _buildPasswordField(
                        controller: _currentPasswordController,
                        label: 'Current password',
                        hintText: '**********',
                        obscureText: _obscureCurrentPassword,
                        onToggleVisibility: () {
                          setState(() {
                            _obscureCurrentPassword = !_obscureCurrentPassword;
                          });
                        },
                        currentFocus: FocusNode(),
                      ),
                      const SizedBox(height: 25),
                      _buildPasswordField(
                        controller: _newPasswordController,
                        label: 'New password',
                        hintText: '**********',
                        obscureText: _obscureNewPassword,
                        onToggleVisibility: () {
                          setState(() {
                            _obscureNewPassword = !_obscureNewPassword;
                          });
                        },
                        currentFocus: FocusNode(),
                        nextFocus: _confirmPasswordFocus,
                      ),
                      const SizedBox(height: 25),
                      _buildPasswordField(
                        controller: _confirmPasswordController,
                        label: 'Confirm password',
                        hintText: '**********',
                        obscureText: _obscureConfirmPassword,
                        onToggleVisibility: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                        currentFocus: _confirmPasswordFocus,
                        isLastField: true,
                      ),
                      if (_passwordError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _passwordError!,
                            style: TextStyle(color: AppColors.errorColor),
                          ),
                        ),
                      const SizedBox(height: 40),
                      InkWell(
                        onTap: _isLoading ? null : _updatePassword,
                        borderRadius: BorderRadius.circular(25),
                        child: Container(
                          width: double.infinity,
                          height: 55,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.chartColor,
                                AppColors.vibrantBlue,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.shadowColor,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _isLoading ? 'Loading...' : 'Change Password',
                            style: AppStyles.titleStyle.copyWith(
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required FocusNode currentFocus,
    FocusNode? nextFocus,
    bool isLastField = false,
  }) {
    return TextField(
      controller: controller,
      focusNode: currentFocus,
      obscureText: obscureText,
      textInputAction:
          isLastField ? TextInputAction.done : TextInputAction.next,
      onSubmitted: (_) {
        if (!isLastField && nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
        } else {
          FocusScope.of(context).unfocus();
        }
      },
      cursorColor: AppColors.primaryColor,
      style: TextStyle(color: AppColors.primaryColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.primaryColor),
        prefixIcon: Icon(Icons.lock, color: AppColors.primaryColor),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: AppColors.primaryColor,
          ),
          onPressed: onToggleVisibility,
        ),
        hintText: hintText,
        hintStyle: TextStyle(color: AppColors.primaryColor.withOpacity(0.5)),
        filled: true,
        fillColor: Colors.transparent,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide(color: AppColors.primaryColor, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide(color: AppColors.primaryColor, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide(color: AppColors.primaryColor, width: 1.0),
        ),
      ),
    );
  }

  bool _isPasswordValid(String password) {
    if (password.length < 6) return false;
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    return hasUppercase && hasLowercase && hasDigits;
  }

  Future<bool> _verifyCurrentPassword(String currentPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return false;

      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _changePasswordInFirebase(String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return false;

      await user.updatePassword(newPassword);
      return true;
    } catch (e) {
      print('Şifre güncelleme hatası: $e');
      return false;
    }
  }

  void _showSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Your password has been successfully updated!',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _updatePassword() async {
    setState(() {
      _isLoading = true;
      _passwordError = null;
    });

    try {
      String currentPassword = _currentPasswordController.text.trim();
      String newPassword = _newPasswordController.text.trim();
      String confirmPassword = _confirmPasswordController.text.trim();

      if (currentPassword.isEmpty ||
          newPassword.isEmpty ||
          confirmPassword.isEmpty) {
        setState(() {
          _passwordError = "Please fill in all fields!";
          _isLoading = false;
        });
        return;
      }

      if (newPassword != confirmPassword) {
        setState(() {
          _passwordError = "The new passwords don't match!";
          _isLoading = false;
        });
        return;
      }

      if (!_isPasswordValid(newPassword)) {
        setState(() {
          _passwordError =
              "The password must be at least 6 characters and contain uppercase letters, lowercase letters and numbers!";
          _isLoading = false;
        });
        return;
      }

      if (currentPassword == newPassword) {
        setState(() {
          _passwordError =
              "The new password must be different from the existing password!";
          _isLoading = false;
        });
        return;
      }

      bool isCurrentPasswordValid = await _verifyCurrentPassword(
        currentPassword,
      );
      if (!isCurrentPasswordValid) {
        setState(() {
          _passwordError = "The current password is incorrect!";
          _isLoading = false;
        });
        return;
      }

      bool isPasswordChanged = await _changePasswordInFirebase(newPassword);
      if (!isPasswordChanged) {
        setState(() {
          _passwordError =
              "There was an error updating the password. Please try again.";
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _passwordError = null;
      });

      _showSuccessSnackBar();
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => PasswordChanged()),
        );
      }
    } catch (e) {
      setState(() {
        _passwordError = "An unexpected error occurred. Please try again.";
        _isLoading = false;
      });
      print('Hata: $e');
    }
  }
}
