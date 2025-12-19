import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';
import '../styles/app_styles.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final userId = await DatabaseHelper.instance.registerUser(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _nicknameController.text.trim(),
        );
        
        // Vytvoř výchozí návyky
        await DatabaseHelper.instance.createDefaultHabits(userId);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', _emailController.text.trim());
        await prefs.setString('nickname', _nicknameController.text.trim());
        await prefs.setInt('user_id', userId);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Registrace úspěšná! 🎉'),
            backgroundColor: AppColors.success,
          ),
        );

        Navigator.pushReplacementNamed(context, '/home');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registrace selhala: ${e.toString().contains('UNIQUE') ? 'Email již existuje' : e}'),
            backgroundColor: AppColors.error,
          ),
        );
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
                    // Header
                    Text(
                      'HabitTrack',
                      style: AppTextStyles.logoText.copyWith(fontSize: 42),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vytvoř si účet a začni sledovat své návyky',
                      style: AppTextStyles.subtitle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Nickname field
                    TextFormField(
                      controller: _nicknameController,
                      style: AppTextStyles.inputText,
                      decoration: InputDecoration(
                        labelText: 'Přezdívka',
                        labelStyle: AppTextStyles.inputHint,
                        prefixIcon: Icon(Icons.person_outlined, color: AppColors.textTertiary),
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
                      textCapitalization: TextCapitalization.words,
                      validator: (value) =>
                          value!.isEmpty ? 'Zadej přezdívku' : null,
                    ),
                    const SizedBox(height: 16),

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
                          value!.length < 6 ? 'Heslo musí mít min. 6 znaků' : null,
                    ),
                    const SizedBox(height: 16),

                    // Confirm password field
                    TextFormField(
                      controller: _confirmPasswordController,
                      style: AppTextStyles.inputText,
                      decoration: InputDecoration(
                        labelText: 'Potvrdit heslo',
                        labelStyle: AppTextStyles.inputHint,
                        prefixIcon: Icon(Icons.lock_outlined, color: AppColors.textTertiary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            color: AppColors.textTertiary,
                          ),
                          onPressed: () {
                            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
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
                      obscureText: _obscureConfirmPassword,
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Hesla se neshodují';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Register button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.white,
                          foregroundColor: AppColors.primaryPink,
                          elevation: 8,
                          shadowColor: AppColors.blackWithOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppDecorations.buttonRadius,
                          ),
                        ),
                        onPressed: _isLoading ? null : _register,
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
                                'Registrovat se',
                                style: AppTextStyles.buttonText.copyWith(fontSize: 18),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Login link
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Už máš účet? Přihlásit se',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
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
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
