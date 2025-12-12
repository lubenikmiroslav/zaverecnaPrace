import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../services/database_helper.dart';
import 'stats_screen.dart';
import 'add_habit_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String nickname = '';
  String email = '';
  int userId = 0;
  Map<String, dynamic> stats = {};
  String? profilePhotoPath;
  bool isLoading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    nickname = prefs.getString('nickname') ?? '';
    email = prefs.getString('user_email') ?? '';
    
    if (email.isNotEmpty) {
      final user = await DatabaseHelper.instance.getUserByEmail(email);
      if (user != null) {
        userId = user['id'];
        profilePhotoPath = user['profile_photo_path'];
        stats = await DatabaseHelper.instance.getUserStats(userId);
      }
    }
    
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 85,
      );

      if (image != null) {
        // Uložit obrázek do aplikace
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'profile_$userId${path.extension(image.path)}';
        final savedImage = await File(image.path).copy('${appDir.path}/$fileName');
        
        // Uložit cestu do databáze
        await DatabaseHelper.instance.updateUserSettings(
          userId,
          {'profile_photo_path': savedImage.path},
        );
        
        setState(() {
          profilePhotoPath = savedImage.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chyba při načítání obrázku: $e')),
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 85,
      );

      if (image != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'profile_$userId${path.extension(image.path)}';
        final savedImage = await File(image.path).copy('${appDir.path}/$fileName');
        
        await DatabaseHelper.instance.updateUserSettings(
          userId,
          {'profile_photo_path': savedImage.path},
        );
        
        setState(() {
          profilePhotoPath = savedImage.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chyba při pořizování fotky: $e')),
      );
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Vybrat z galerie'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Pořídit fotku'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            if (profilePhotoPath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Smazat fotku', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deletePhoto();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePhoto() async {
    if (profilePhotoPath != null) {
      try {
        final file = File(profilePhotoPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // Ignorovat chyby při mazání
      }
    }
    
    await DatabaseHelper.instance.updateUserSettings(
      userId,
      {'profile_photo_path': null},
    );
    
    setState(() {
      profilePhotoPath = null;
    });
  }

  double _calculateProgress() {
    final total = stats['habitsCount'] ?? 0;
    final completed = stats['totalCompletions'] ?? 0;
    if (total == 0) return 0.0;
    // Zjednodušený výpočet - můžeš upravit podle potřeby
    return (completed / (total * 30)).clamp(0.0, 1.0) * 100; // 30 dní jako cíl
  }

  @override
  Widget build(BuildContext context) {
    final progress = _calculateProgress();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Můj účet'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Notifikace
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header s gradientem (jako stickK)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.orange.shade400,
                          Colors.red.shade400,
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        // Profilová fotka s možností změny
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: _showImagePicker,
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.white,
                                backgroundImage: profilePhotoPath != null
                                    ? FileImage(File(profilePhotoPath!))
                                    : null,
                                child: profilePhotoPath == null
                                    ? Text(
                                        nickname.isNotEmpty ? nickname[0].toUpperCase() : '?',
                                        style: TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange.shade400,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 20,
                                  color: Colors.orange.shade400,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Jméno
                        Text(
                          nickname.isNotEmpty ? nickname : 'Uživatel',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Progress indikátory (jako stickK)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildProgressCircle(
                          'Progress',
                          progress,
                          Colors.teal,
                        ),
                        _buildProgressCircle(
                          'Success',
                          (stats['monthCompletions'] ?? 0) / ((stats['habitsCount'] ?? 1) * 30) * 100,
                          Colors.grey,
                        ),
                      ],
                    ),
                  ),

                  // Statistiky karty
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Návyky',
                            '${stats['habitsCount'] ?? 0}',
                            Icons.list_alt,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Splnění',
                            '${stats['totalCompletions'] ?? 0}',
                            Icons.check_circle,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Menu options
                  _buildMenuSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildProgressCircle(String label, double percentage, Color color) {
    return Column(
      children: [
        SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Text(
                '${percentage.toInt()}%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.bar_chart),
          title: const Text('Statistiky'),
          subtitle: const Text('Podrobný přehled pokroku'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const StatsScreen()),
            );
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.emoji_events),
          title: const Text('Ocenění'),
          subtitle: const Text('Zobrazit odemčená ocenění'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.pushNamed(context, '/achievements');
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.add_circle),
          title: const Text('Přidat návyk'),
          subtitle: const Text('Vytvoř nový návyk'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final result = await Navigator.pushNamed(context, '/add');
            if (result == true) {
              await _loadUserData();
            }
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.settings),
          title: const Text('Nastavení'),
          subtitle: const Text('Upravit profil a nastavení'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SettingsScreen(
                  onThemeChanged: (bool isDark) {},
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
