import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  
  const SettingsScreen({super.key, required this.onThemeChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String nickname = '';
  String email = '';
  int userId = 0;
  bool isDarkMode = false;
  String selectedColor = '#009688'; // teal default

  final List<Map<String, dynamic>> themeColors = [
    {'name': 'Tyrkysová', 'color': '#009688'},
    {'name': 'Modrá', 'color': '#2196F3'},
    {'name': 'Zelená', 'color': '#4CAF50'},
    {'name': 'Oranžová', 'color': '#FF9800'},
    {'name': 'Fialová', 'color': '#9C27B0'},
    {'name': 'Růžová', 'color': '#E91E63'},
    {'name': 'Červená', 'color': '#F44336'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    email = prefs.getString('user_email') ?? '';
    nickname = prefs.getString('nickname') ?? '';
    isDarkMode = prefs.getBool('dark_mode') ?? false;
    selectedColor = prefs.getString('theme_color') ?? '#009688';

    if (email.isNotEmpty) {
      final user = await DatabaseHelper.instance.getUserByEmail(email);
      if (user != null) {
        userId = user['id'];
        selectedColor = user['theme_color'] ?? selectedColor;
      }
    }
    setState(() {});
  }

  Future<void> _toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
    setState(() {
      isDarkMode = value;
    });
    widget.onThemeChanged(value);
  }

  Future<void> _changeThemeColor(String color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_color', color);
    
    if (userId > 0) {
      await DatabaseHelper.instance.updateUserSettings(userId, {'theme_color': color});
    }
    
    setState(() {
      selectedColor = color;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Barva motivu změněna. Restartuj aplikaci pro plný efekt.')),
    );
  }

  Future<void> _changeNickname() async {
    final controller = TextEditingController(text: nickname);
    
    final newNickname = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Změnit přezdívku'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nová přezdívka',
            hintText: 'Zadej novou přezdívku',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zrušit'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Uložit'),
          ),
        ],
      ),
    );

    if (newNickname != null && newNickname.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nickname', newNickname);
      
      if (userId > 0) {
        await DatabaseHelper.instance.updateUserSettings(userId, {'nickname': newNickname});
      }
      
      setState(() {
        nickname = newNickname;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Přezdívka byla změněna')),
      );
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Odhlásit se'),
        content: const Text('Opravdu se chceš odhlásit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Zrušit'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Odhlásit'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_email');
      await prefs.remove('nickname');
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nastavení'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // Profil
          _buildSectionHeader('Profil'),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                nickname.isNotEmpty ? nickname[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(nickname.isNotEmpty ? nickname : 'Bez přezdívky'),
            subtitle: Text(email),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _changeNickname,
            ),
          ),
          const Divider(),

          // Vzhled
          _buildSectionHeader('Vzhled'),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text('Tmavý režim'),
            subtitle: const Text('Přepnout mezi světlým a tmavým motivem'),
            value: isDarkMode,
            onChanged: _toggleDarkMode,
          ),
          const Divider(),

          // Barva motivu
          _buildSectionHeader('Barva motivu'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: themeColors.map((colorData) {
                final color = Color(int.parse('0xFF${colorData['color'].toString().replaceAll('#', '')}'));
                final isSelected = selectedColor == colorData['color'];
                
                return GestureDetector(
                  onTap: () => _changeThemeColor(colorData['color']),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8, spreadRadius: 2)]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),

          // Účet
          _buildSectionHeader('Účet'),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Odhlásit se', style: TextStyle(color: Colors.red)),
            onTap: _logout,
          ),
          const SizedBox(height: 32),

          // Info
          Center(
            child: Column(
              children: [
                Text(
                  'HabitTrack',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Verze 1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

