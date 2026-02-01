import 'dart:ui';

import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract class AppTextStyle{

  static final Text30 = GoogleFonts.aboreto(
  color:  Color.fromARGB(255, 59, 90, 190),
  fontSize: 32,
  fontWeight: FontWeight.bold,
  letterSpacing: 1.5,
  );
  static final Text20 =  GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color:AppColors.buttonTitle,
  );
  static final Text18 = GoogleFonts.poppins(
    fontSize: 18,
    color:AppColors.bigTitle,
  );
  static final Texte18 = GoogleFonts.poppins(
    fontSize: 18,
    color:AppColors.title,
  );


}
