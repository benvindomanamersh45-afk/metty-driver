import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppGradients {
  static const LinearGradient mety = LinearGradient(
    colors: [AppColors.metyBlue, AppColors.metyBlueLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient driver = LinearGradient(
    colors: [AppColors.metyPurple, AppColors.metyBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient premium = LinearGradient(
    colors: [AppColors.metyOrange, AppColors.metyPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient online = LinearGradient(
    colors: [AppColors.metyGreen, AppColors.metyBlue],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  
  static const LinearGradient offline = LinearGradient(
    colors: [AppColors.error, AppColors.metyRed],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
