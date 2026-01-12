import 'package:dietbuddy/helperScreens/change_password.dart';
import 'package:flutter/material.dart';
import 'package:dietbuddy/constants/colors.dart';
import 'package:dietbuddy/constants/styles.dart';
import 'package:dietbuddy/helperScreens/welcome_screen.dart';
import 'package:flutter/services.dart';
import 'package:dietbuddy/services/firebase/user_service.dart'; // Service import'u

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _userName = 'Loading...';
  String _userEmail = 'Loading...';
  String _userHeight = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      Map<String, dynamic> userData = await UserService.loadUserData();

      setState(() {
        _userName = userData['name'];
        _userEmail = userData['email'];
        _userHeight = userData['height'];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog(e.toString());
    }
  }

  Future<void> _updateUserName(String newName) async {
    try {
      await UserService.updateUserName(newName);

      setState(() {
        _userName = newName;
      });

      _showSuccessDialog('Name updated successfully!');
    } catch (e) {
      debugPrint('Error updating name: $e');
      _showErrorDialog(e.toString());
    }
  }

  Future<void> _updateUserHeight(String newHeight) async {
    try {
      await UserService.updateUserHeight(newHeight);

      setState(() {
        _userHeight = newHeight;
      });

      _showSuccessDialog('Height updated successfully!');
    } catch (e) {
      debugPrint('Error updating height: $e');
      _showErrorDialog(e.toString());
    }
  }

  Future<void> _deleteAccount() async {
    try {
      await UserService.deleteAccount();

      if (!mounted) return;
      // Welcome screen'e yönlendir
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      debugPrint('Error deleting account: $e');
      _showErrorDialog(e.toString());
    }
  }

  Future<void> _logout() async {
    try {
      await UserService.logout();

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      debugPrint('Error logging out: $e');
      _showErrorDialog(e.toString());
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.primaryColor.withValues(alpha: 0.75),
            title: Text(
              'Success',
              style: AppStyles.titleStyle.copyWith(
                color: AppColors.lineerStart,
                fontSize: 25,
              ),
            ),
            content: Text(message, style: AppStyles.textStyle),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.button,
                  foregroundColor: AppColors.lineerStart,
                ),
                child: Text(
                  'OK',
                  style: AppStyles.text.copyWith(color: AppColors.lineerStart),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.primaryColor.withValues(alpha: 0.75),
            title: Text(
              'Error',
              style: AppStyles.titleStyle.copyWith(
                color: AppColors.errorColor,
                fontSize: 25,
              ),
            ),
            content: Text(error, style: AppStyles.textStyle),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.button,
                  foregroundColor: AppColors.lineerStart,
                ),
                child: Text(
                  'OK',
                  style: AppStyles.text.copyWith(color: AppColors.lineerStart),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.vibrantBlue.withValues(alpha: 0.3),
              AppColors.vibrantPurple.withValues(alpha: 0.3),
              AppColors.vibrantPink.withValues(alpha: 0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.05,
            vertical: height * 0.02,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                children: [
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      SizedBox(width: 50),
                      const Spacer(),
                      Text(
                        'My Profile',
                        style: AppStyles.pageTitle.copyWith(
                          color: AppColors.vibrantPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(flex: 2),
                    ],
                  ),
                  SizedBox(height: height * 0.02),
                  Container(
                    height: 200,
                    width: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.transparent, width: 4),
                    ),
                    child: Image.asset('assets/images/db_logo.png'),
                  ),
                  SizedBox(height: height * 0.02),
                  // Bilgi Kartı
                  _buildInfoCard(context, width, height),
                  SizedBox(height: height * 0.05),
                  // Diğer kartlar
                  CustomProfileCard(
                    title:
                        "Update Height ${_userHeight.isNotEmpty ? '($_userHeight cm)' : ''}",
                    onTap: () => _showEditHeightDialog(context),
                    icon: Icons.height_outlined,
                    iconColor: AppColors.primaryColor,
                    textColor: AppColors.primaryColor,
                    arrowColor: AppColors.primaryColor,
                  ),
                  SizedBox(height: height * 0.015),
                  CustomProfileCard(
                    title: "Update Password",
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ChangePassword(),
                        ),
                      );
                    },
                    icon: Icons.password,
                    iconColor: AppColors.primaryColor,
                    textColor: AppColors.primaryColor,
                    arrowColor: AppColors.primaryColor,
                  ),
                  SizedBox(height: height * 0.015),
                  CustomProfileCard(
                    title: "Delete Account",
                    onTap: () => _showDeleteAccountDialog(context),
                    icon: Icons.delete,
                    gradientColors: [
                      AppColors.errorColor,
                      AppColors.vibrantPink,
                    ],
                    iconColor: AppColors.primaryColor,
                    textColor: AppColors.primaryColor,
                    arrowColor: AppColors.primaryColor,
                  ),

                  SizedBox(height: height * 0.015),
                  CustomProfileCard(
                    title: "Log Out",
                    onTap: () => _showLogoutDialog(context),
                    icon: Icons.logout,
                    iconColor: AppColors.primaryColor,
                    textColor: AppColors.primaryColor,
                    arrowColor: AppColors.primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, double width, double height) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            AppColors.vibrantBlue.withValues(alpha: 0.3),
            AppColors.vibrantPurple.withValues(alpha: 0.3),
            AppColors.vibrantPink.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Colors.white70),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _isLoading ? 'Loading...' : _userName,
                    style: AppStyles.subtitleButtonStyle.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.email, color: Colors.white70),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _isLoading ? 'Loading...' : _userEmail,
                    style: AppStyles.subtitleButtonStyle.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _showEditNameDialog(context),
              icon: Icon(Icons.edit, color: AppColors.primaryColor),
              label: const Text("Change Name"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.vibrantBlue,
                foregroundColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditHeightDialog(BuildContext context) {
    final heightController = TextEditingController(text: _userHeight);

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: AppColors.primaryColor.withValues(alpha: 0.75),
            title: Text(
              "Update Height",
              style: AppStyles.titleStyle.copyWith(
                color: AppColors.lineerStart,
                fontSize: 25,
              ),
            ),
            content: TextField(
              controller: heightController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: "Enter your height in cm",
                filled: true,
                fillColor: AppColors.textfield.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            actions: [
              TextButton(
                child: Text(
                  "Cancel",
                  style: AppStyles.text.copyWith(color: AppColors.lineerStart),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.button,
                  foregroundColor: AppColors.primaryColor,
                ),
                child: Text(
                  "Save",
                  style: AppStyles.text.copyWith(color: AppColors.lineerStart),
                ),
                onPressed: () {
                  if (heightController.text.isNotEmpty) {
                    _updateUserHeight(heightController.text);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
    );
  }

  void _showEditNameDialog(BuildContext context) {
    final nameController = TextEditingController(text: _userName);

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: AppColors.primaryColor.withValues(alpha: 0.75),
            title: Text(
              "Update Name",
              style: AppStyles.titleStyle.copyWith(
                color: AppColors.lineerStart,
                fontSize: 25,
              ),
            ),
            content: TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: "Enter your new name",
                filled: true,
                fillColor: AppColors.textfield.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            actions: [
              TextButton(
                child: Text(
                  "Cancel",
                  style: AppStyles.text.copyWith(color: AppColors.lineerStart),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.button,
                  foregroundColor: AppColors.primaryColor,
                ),
                child: Text(
                  "Save",
                  style: AppStyles.text.copyWith(color: AppColors.lineerStart),
                ),
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    _updateUserName(nameController.text);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: AppColors.primaryColor.withValues(alpha: 0.75),
            title: Text(
              "Log Out",
              style: AppStyles.titleStyle.copyWith(
                color: AppColors.lineerStart,
                fontSize: 25,
              ),
            ),
            content: Text(
              "Are you sure you want to log out of your account?",
              style: AppStyles.textStyle,
            ),
            actions: [
              TextButton(
                child: Text(
                  "Cancel",
                  style: AppStyles.text.copyWith(color: AppColors.lineerStart),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.button,
                  foregroundColor: AppColors.lineerStart,
                ),
                child: Text(
                  "Yes",
                  style: AppStyles.text.copyWith(color: AppColors.lineerStart),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _logout();
                },
              ),
            ],
          ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: AppColors.primaryColor.withValues(alpha: 0.75),
            title: Text(
              "Delete Account",
              style: AppStyles.titleStyle.copyWith(
                color: AppColors.errorColor,
                fontSize: 25,
              ),
            ),
            content: Text(
              "Are you sure you want to delete your account? This action cannot be undone.",
              style: AppStyles.textStyle,
            ),
            actions: [
              TextButton(
                child: Text(
                  "Cancel",
                  style: AppStyles.text.copyWith(color: AppColors.lineerStart),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.errorColor,
                  foregroundColor: AppColors.primaryColor,
                ),
                child: Text(
                  "Delete",
                  style: AppStyles.text.copyWith(color: AppColors.primaryColor),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _deleteAccount();
                },
              ),
            ],
          ),
    );
  }
}

//Card yapısını fonksiyonlaştırarak fonksiyoundan üretiyoruz.
class CustomProfileCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final List<Color>? gradientColors;
  final Color? iconColor;
  final Color? textColor;
  final Color? arrowColor;

  const CustomProfileCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.gradientColors,
    this.iconColor,
    this.textColor,
    this.arrowColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                gradientColors ??
                [AppColors.vibrantBlue, AppColors.vibrantPurple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            children: [
              Icon(icon, color: iconColor ?? AppColors.primaryColor),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: AppStyles.primaryStyle.copyWith(
                    fontWeight: FontWeight.w700,
                    color: textColor ?? AppColors.primaryColor,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: arrowColor ?? AppColors.primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
