import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../styles/app_styles.dart';
import '../widgets/animated_gradient_background.dart';

/// Screen pro reset hesla (vývoj/testování)
class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;
  String? selectedEmail;
  final _newPasswordController = TextEditingController(text: '123456');

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final allUsers = await DatabaseHelper.instance.getAllUsers();
    setState(() {
      users = allUsers;
      isLoading = false;
    });
  }

  Future<void> _resetPassword() async {
    if (selectedEmail == null || selectedEmail!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vyber uživatele'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await DatabaseHelper.instance.resetUserPassword(
        selectedEmail!,
        _newPasswordController.text.trim(),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Heslo pro $selectedEmail bylo resetováno na: ${_newPasswordController.text}'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Navigate back to login
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chyba: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'Reset hesla',
                        style: AppTextStyles.heading2,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance back button
                  ],
                ),
                const SizedBox(height: 32),

                // Info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppDecorations.cardDecoration(context),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primaryPink,
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tento nástroj slouží k resetování hesla při vývoji/testování.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // User selection
                Text(
                  'Vyber uživatele:',
                  style: AppTextStyles.heading3,
                ),
                const SizedBox(height: 12),

                if (isLoading)
                  const Center(child: CircularProgressIndicator(color: AppColors.white))
                else if (users.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppDecorations.cardDecoration(context),
                    child: Text(
                      'V databázi nejsou žádní uživatelé',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  Container(
                    decoration: AppDecorations.cardDecoration(context),
                    child: Column(
                      children: users.map((user) {
                        final email = user['email'] as String;
                        final nickname = user['nickname'] as String? ?? '';
                        final isSelected = selectedEmail == email;
                        
                        return InkWell(
                          onTap: () {
                            setState(() {
                              selectedEmail = email;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryPink.withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? AppColors.primaryPink
                                        : Colors.grey[300],
                                  ),
                                  child: Icon(
                                    isSelected ? Icons.check : Icons.person,
                                    color: isSelected ? AppColors.white : Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        email,
                                        style: AppTextStyles.bodyLarge.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      if (nickname.isNotEmpty)
                                        Text(
                                          nickname,
                                          style: AppTextStyles.bodySmall.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                const SizedBox(height: 24),

                // New password input
                Text(
                  'Nové heslo:',
                  style: AppTextStyles.heading3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _newPasswordController,
                  style: AppTextStyles.inputText.copyWith(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Zadej nové heslo',
                    hintStyle: AppTextStyles.inputHint.copyWith(color: Colors.grey),
                    filled: true,
                    fillColor: AppColors.white,
                    border: OutlineInputBorder(
                      borderRadius: AppDecorations.inputRadius,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppDecorations.inputRadius,
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppDecorations.inputRadius,
                      borderSide: BorderSide(color: AppColors.primaryPink, width: 2),
                    ),
                  ),
                  obscureText: false,
                ),

                const Spacer(),

                // Reset button
                ElevatedButton(
                  onPressed: _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPink,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppDecorations.buttonRadius,
                    ),
                    elevation: 8,
                  ),
                  child: Text(
                    'Resetovat heslo',
                    style: AppTextStyles.buttonTextWhite.copyWith(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

