import 'dart:async';
import 'package:dietbuddy/constants/colors.dart';
import 'package:flutter/material.dart';
import '../helperScreens/welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: screenWidth,
            height: screenHeight,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.chartColor,
                  AppColors.vibrantBlue,
                  AppColors.vibrantPurple,
                  AppColors.vibrantPink,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned.fill(
            child: Image.asset(
              'assets/images/splash_screen.png',
              fit: BoxFit.cover,
              color: Colors.white10,
              colorBlendMode: BlendMode.lighten,
            ),
          ),
          Center(
            child: SizedBox(
              height: screenHeight * 0.6,
              width: screenWidth * 0.9,
              child: Image.asset('assets/images/db_logo.png'),
            ),
          ),
        ],
      ),
    );
  }
}
