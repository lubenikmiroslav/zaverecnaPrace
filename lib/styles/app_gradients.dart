import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centrální soubor pro všechny gradienty aplikace
class AppGradients {
  // Hlavní gradient (orange -> pink)
  static LinearGradient get primaryGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.primaryOrange,
      AppColors.primaryPink,
    ],
  );
  
  // Rozšířený gradient (orange -> pink -> purple)
  static LinearGradient get extendedGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.primaryOrange,
      AppColors.primaryPink,
      AppColors.primaryPurple,
    ],
  );
  
  // Gradient pro karty
  static LinearGradient get cardGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.whiteWithOpacity(0.95),
      AppColors.whiteWithOpacity(0.9),
    ],
  );
  
  // Gradient pro progress bar
  static LinearGradient get progressGradient => LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      AppColors.whiteWithOpacity(0.6),
      AppColors.whiteWithOpacity(0.8),
    ],
  );
  
  // Gradient pro návykové karty
  static LinearGradient habitCardGradient(Color color) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      color.withOpacity(0.3),
      color.withOpacity(0.2),
    ],
  );
  
  // Gradient pro ikony návyků
  static LinearGradient habitIconGradient(Color color) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      color,
      color.withOpacity(0.8),
    ],
  );
  
  // Gradient pro tlačítka
  static LinearGradient get buttonGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.white,
      AppColors.whiteWithOpacity(0.95),
    ],
  );
}

