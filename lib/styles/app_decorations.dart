import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centrální soubor pro všechny dekorace (shadows, borders, atd.)
class AppDecorations {
  // Box shadows
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: AppColors.blackWithOpacity(0.1),
      blurRadius: 10,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];
  
  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: AppColors.blackWithOpacity(0.15),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: 2,
    ),
  ];
  
  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: AppColors.blackWithOpacity(0.2),
      blurRadius: 8,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];
  
  static List<BoxShadow> get profilePictureShadow => [
    BoxShadow(
      color: AppColors.blackWithOpacity(0.3),
      blurRadius: 15,
      offset: const Offset(0, 5),
      spreadRadius: 2,
    ),
  ];
  
  static List<BoxShadow> get iconShadow => [
    BoxShadow(
      color: AppColors.blackWithOpacity(0.2),
      blurRadius: 8,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];
  
  // Text shadows
  static List<Shadow> get textShadow => [
    Shadow(
      color: AppColors.blackWithOpacity(0.2),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<Shadow> get textShadowSmall => [
    Shadow(
      color: AppColors.blackWithOpacity(0.15),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
  // Borders - BorderSide pro OutlineInputBorder
  static BorderSide get whiteBorderSide => BorderSide(
    color: AppColors.white,
    width: 2,
  );
  
  static BorderSide get thinWhiteBorderSide => BorderSide(
    color: AppColors.white,
    width: 1,
  );
  
  // Borders - BoxBorder pro BoxDecoration
  static BoxBorder get whiteBorder => Border.all(
    color: AppColors.white,
    width: 2,
  );
  
  static BoxBorder get thinWhiteBorder => Border.all(
    color: AppColors.white,
    width: 1,
  );
  
  static BoxBorder get profilePictureBorder => Border.all(
    color: AppColors.white,
    width: 4,
  );
  
  // Border radius
  static BorderRadius get cardRadius => BorderRadius.circular(16);
  static BorderRadius get smallRadius => BorderRadius.circular(8);
  static BorderRadius get mediumRadius => BorderRadius.circular(12);
  static BorderRadius get largeRadius => BorderRadius.circular(20);
  static BorderRadius get buttonRadius => BorderRadius.circular(12);
  static BorderRadius get inputRadius => BorderRadius.circular(12);
  static BorderRadius get habitCardRadius => BorderRadius.circular(16);
  
  // Box decoration pro karty
  static BoxDecoration cardDecoration(BuildContext context) => BoxDecoration(
    color: AppColors.cardBackground(context),
    borderRadius: cardRadius,
    boxShadow: cardShadow,
  );
  
  // Box decoration pro návykové karty
  static BoxDecoration habitCardDecoration(Color color) => BoxDecoration(
    color: AppColors.semiTransparentWhite,
    borderRadius: habitCardRadius,
    border: Border.all(
      color: color.withOpacity(0.3),
      width: 1,
    ),
  );
  
  // Box decoration pro input fields
  static BoxDecoration get inputDecoration => BoxDecoration(
    color: AppColors.semiTransparentWhite,
    borderRadius: inputRadius,
    border: thinWhiteBorder,
  );
  
  // Box decoration pro tlačítka
  static BoxDecoration get buttonDecoration => BoxDecoration(
    color: AppColors.white,
    borderRadius: buttonRadius,
    boxShadow: buttonShadow,
  );
  
  // Box decoration pro profile picture
  static BoxDecoration get profilePictureDecoration => BoxDecoration(
    shape: BoxShape.circle,
    border: profilePictureBorder,
    boxShadow: profilePictureShadow,
  );
}

