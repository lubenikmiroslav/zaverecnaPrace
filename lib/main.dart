import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/database_helper.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/add_habit_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/achievements_screen.dart';
import 'screens/timer_screen.dart';
import 'screens/password_reset_screen.dart';
import 'widgets/splash_wrapper.dart';
import 'styles/app_styles.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  await NotificationService.instance.initialize();

  final prefs = await SharedPreferences.getInstance();
  final savedEmail = prefs.getString('user_email');
  final isDarkMode = prefs.getBool('dark_mode') ?? false;
  final themeColor = prefs.getString('theme_color') ?? '#009688';

  runApp(HabitTrackApp(
    isLoggedIn: savedEmail != null,
    isDarkMode: isDarkMode,
    themeColor: themeColor,
  ));
}

class HabitTrackApp extends StatefulWidget {
  final bool isLoggedIn;
  final bool isDarkMode;
  final String themeColor;

  const HabitTrackApp({
    super.key,
    required this.isLoggedIn,
    required this.isDarkMode,
    required this.themeColor,
  });

  @override
  State<HabitTrackApp> createState() => HabitTrackAppState();

  static HabitTrackAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<HabitTrackAppState>();
  }
}

class HabitTrackAppState extends State<HabitTrackApp> {
  late bool _isDarkMode;
  late Color _seedColor;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _seedColor = _parseColor(widget.themeColor);
  }

  Color _parseColor(String hexColor) {
    return Color(int.parse('0xFF${hexColor.replaceAll('#', '')}'));
  }

  void toggleTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', isDark);
    setState(() {
      _isDarkMode = isDark;
    });
  }

  void changeThemeColor(String hexColor) {
    setState(() {
      _seedColor = _parseColor(hexColor);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HabitTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: SplashWrapper(
        isLoggedIn: widget.isLoggedIn,
      ),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return AppAnimations.fadeRoute(const LoginScreen());
          case '/register':
            return AppAnimations.slideRoute(const RegisterScreen());
          case '/home':
            return AppAnimations.fadeRoute(const MainNavigation());
          case '/add':
            return AppAnimations.scaleRoute(const AddHabitScreen());
          case '/profile':
            return AppAnimations.slideRoute(const ProfileScreen(), fromRight: false);
          case '/achievements':
            return AppAnimations.scaleRoute(const AchievementsScreen());
          case '/password-reset':
            return AppAnimations.fadeRoute(const PasswordResetScreen());
          default:
            return AppAnimations.fadeRoute(const LoginScreen());
        }
      },
    );
  }
}
