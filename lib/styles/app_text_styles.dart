import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centrální soubor pro všechny textové styly aplikace
class AppTextStyles {
  // Logo / Brand text
  static TextStyle get logoText => TextStyle(
    fontFamily: 'Howdybun',
    fontSize: 48,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    shadows: [
      Shadow(
        color: AppColors.blackWithOpacity(0.2),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );
  
  // Nadpisy
  static TextStyle get heading1 => TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static TextStyle get heading2 => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static TextStyle get heading3 => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  // Tělo textu
  static TextStyle get bodyLarge => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );
  
  static TextStyle get bodyMedium => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );
  
  static TextStyle get bodySmall => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
  
  // Sekundární text
  static TextStyle get subtitle => TextStyle(
    fontSize: 16,
    color: AppColors.textSecondary,
    fontWeight: FontWeight.w500,
  );
  
  static TextStyle get caption => TextStyle(
    fontSize: 12,
    color: AppColors.textTertiary,
    fontWeight: FontWeight.normal,
  );
  
  // Tlačítka
  static TextStyle get buttonText => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryPink,
  );
  
  static TextStyle get buttonTextWhite => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );
  
  // Input fields
  static TextStyle get inputText => TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );
  
  static TextStyle get inputHint => TextStyle(
    fontSize: 16,
    color: AppColors.textTertiary,
  );
  
  // Návyky
  static TextStyle get habitName => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static TextStyle get habitDescription => TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );
  
  static TextStyle get habitProgress => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static TextStyle get habitAffirmation => TextStyle(
    fontSize: 12,
    fontStyle: FontStyle.italic,
    color: AppColors.textTertiary,
  );
  
  // Statistiky
  static TextStyle get statValue => TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryPink,
  );
  
  static TextStyle get statLabel => TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
    fontWeight: FontWeight.w500,
  );
  
  // Streak badge
  static TextStyle get streakBadge => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );
}

