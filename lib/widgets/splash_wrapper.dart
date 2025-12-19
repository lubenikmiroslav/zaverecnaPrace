import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_navigation.dart';

/// Wrapper pro splash screen s navigací
class SplashWrapper extends StatefulWidget {
  final bool isLoggedIn;
  
  const SplashWrapper({super.key, required this.isLoggedIn});
  
  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  bool _isComplete = false;
  
  void _handleComplete() {
    if (!_isComplete && mounted) {
      setState(() {
        _isComplete = true;
      });
      
      // Use post frame callback to ensure context is valid
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => widget.isLoggedIn
                  ? const MainNavigation()
                  : const LoginScreen(),
            ),
          );
        }
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return SplashScreen(
      onComplete: _handleComplete,
    );
  }
}

