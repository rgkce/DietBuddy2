import 'package:dietbuddy/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppStyles {
  static final TextStyle titleStyle = GoogleFonts.lora(
    color: AppColors.titleColor,
    fontSize: 20,
  );
  static final TextStyle pageTitle = GoogleFonts.lora(
    color: AppColors.titleColor,
    fontSize: 32,
  );
  static final TextStyle textStyle = GoogleFonts.lora(
    color: AppColors.textColor,
    fontSize: 15,
  );
  static final TextStyle text = GoogleFonts.lora(
    color: AppColors.textColor,
    fontSize: 18,
  );
  static final TextStyle subtitleStyle = GoogleFonts.lora(
    color: const Color.fromARGB(255, 44, 50, 70),
    fontSize: 15,
  );
  static final TextStyle subtitleButtonStyle = GoogleFonts.lora(
    color: const Color.fromARGB(255, 44, 50, 70),
    fontSize: 20,
  );
  static final TextStyle primaryStyle = GoogleFonts.lora(
    color: const Color(0xFFFFFEFE),
    fontSize: 20,
  );
}