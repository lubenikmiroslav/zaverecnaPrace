import 'package:flutter/material.dart';

/// Centrální soubor pro všechny barvy aplikace
class AppColors {
  // Primární barvy
  static const Color primaryOrange = Color(0xFFFF9800);
  static const Color primaryPink = Color(0xFFE91E63);
  static const Color primaryPurple = Color(0xFF9C27B0);
  
  // Barvy pro návyky
  static const Color habitPink = Color(0xFFE91E63);
  static const Color habitRed = Color(0xFFF44336);
  static const Color habitOrange = Color(0xFFFF9800);
  static const Color habitAmber = Color(0xFFFFC107);
  static const Color habitGreen = Color(0xFF4CAF50);
  static const Color habitTeal = Color(0xFF009688);
  static const Color habitBlue = Color(0xFF2196F3);
  static const Color habitIndigo = Color(0xFF3F51B5);
  static const Color habitPurple = Color(0xFF9C27B0);
  static const Color habitDeepPurple = Color(0xFF673AB7);
  
  // Neutrální barvy
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;
  
  // Barvy s opacity
  static Color whiteWithOpacity(double opacity) => Colors.white.withOpacity(opacity);
  static Color blackWithOpacity(double opacity) => Colors.black.withOpacity(opacity);
  
  // Barvy pro karty a pozadí (reagují na dark mode)
  static Color cardBackground(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.grey[900]!.withOpacity(0.95)
        : Colors.white.withOpacity(0.95);
  }
  
  // Semi-transparentní barvy (pro gradient pozadí - vždy bílé)
  static Color semiTransparentWhite = Colors.white.withOpacity(0.3);
  
  static Color semiTransparentBlack(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.black.withOpacity(0.3)
        : Colors.black.withOpacity(0.1);
  }
  
  // Barvy pro text (na gradient pozadí - vždy bílé)
  static const Color textPrimary = Colors.white;
  static Color textSecondary = Colors.white.withOpacity(0.9);
  static Color textTertiary = Colors.white.withOpacity(0.7);
  
  // Barvy pro text na kartách (reagují na dark mode)
  static Color cardTextPrimary(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;
  }
  
  static Color cardTextSecondary(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.white.withOpacity(0.7)
        : Colors.black54;
  }
  
  // Barvy pro chyby a úspěch
  static const Color error = Color(0xFFF44336);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  
  // Barvy pro progress a indikátory
  static Color progressBackground(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.white.withOpacity(0.2)
        : Colors.white.withOpacity(0.3);
  }
  
  static Color progressFill(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.white.withOpacity(0.5)
        : Colors.white.withOpacity(0.6);
  }
  
  // Seznam dostupných barev pro návyky
  static List<Color> get availableHabitColors => [
    habitPink,
    habitRed,
    habitOrange,
    habitAmber,
    habitGreen,
    habitTeal,
    habitBlue,
    habitIndigo,
    habitPurple,
    habitDeepPurple,
  ];
  
  // Barvy pro theme (z settings)
  static const List<Map<String, dynamic>> themeColors = [
    {'name': 'Tyrkysová', 'color': '#009688'},
    {'name': 'Modrá', 'color': '#2196F3'},
    {'name': 'Zelená', 'color': '#4CAF50'},
    {'name': 'Oranžová', 'color': '#FF9800'},
    {'name': 'Fialová', 'color': '#9C27B0'},
    {'name': 'Růžová', 'color': '#E91E63'},
    {'name': 'Červená', 'color': '#F44336'},
  ];
}

