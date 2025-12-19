import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';
import '../styles/app_styles.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final user = await DatabaseHelper.instance.loginUser(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        
        if (user != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_email', user['email']);
          await prefs.setString('nickname', user['nickname'] ?? '');
          await prefs.setInt('user_id', user['id']);

          Navigator.pushReplacementNamed(context, '/home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Neplatné přihlašovací údaje'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.primaryGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo / Header
                    Text(
                      'HabitTrack',
                      style: AppTextStyles.logoText,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sleduj své návyky, zlepšuj svůj život',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 48),

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      style: AppTextStyles.inputText,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: AppTextStyles.inputHint,
                        prefixIcon: Icon(Icons.email_outlined, color: AppColors.textTertiary),
                        filled: true,
                        fillColor: AppColors.semiTransparentWhite,
                        border: OutlineInputBorder(
                          borderRadius: AppDecorations.inputRadius,
                          borderSide: AppDecorations.thinWhiteBorderSide,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppDecorations.inputRadius,
                          borderSide: AppDecorations.thinWhiteBorderSide,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppDecorations.inputRadius,
                          borderSide: AppDecorations.whiteBorderSide,
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Zadej email';
                        }
                        if (!value.contains('@')) {
                          return 'Zadej platný email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      style: AppTextStyles.inputText,
                      decoration: InputDecoration(
                        labelText: 'Heslo',
                        labelStyle: AppTextStyles.inputHint,
                        prefixIcon: Icon(Icons.lock_outlined, color: AppColors.textTertiary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: AppColors.textTertiary,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                        filled: true,
                        fillColor: AppColors.semiTransparentWhite,
                        border: OutlineInputBorder(
                          borderRadius: AppDecorations.inputRadius,
                          borderSide: AppDecorations.thinWhiteBorderSide,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppDecorations.inputRadius,
                          borderSide: AppDecorations.thinWhiteBorderSide,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppDecorations.inputRadius,
                          borderSide: AppDecorations.whiteBorderSide,
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (value) =>
                          value!.isEmpty ? 'Zadej heslo' : null,
                    ),
                    const SizedBox(height: 24),

                    // Login button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.white,
                          foregroundColor: AppColors.primaryPink,
                          elevation: 8,
                          shadowColor: AppColors.blackWithOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppDecorations.buttonRadius,
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryPink,
                                ),
                              )
                            : Text(
                                'Přihlásit se',
                                style: AppTextStyles.buttonText.copyWith(fontSize: 18),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Register link
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      child: Text(
                        'Nemáš účet? Registrovat se',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Password reset link (for development/testing)
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/password-reset');
                      },
                      child: Text(
                        'Zapomněl jsi heslo?',
                        style: AppTextStyles.bodySmall.copyWith(
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
