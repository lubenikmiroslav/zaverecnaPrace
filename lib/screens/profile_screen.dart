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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange.shade400,
              Colors.pink.shade400,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Modern App Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Text(
                      'Můj účet',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48), // Balance
                  ],
                ),
              ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            // Profile Header
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                    child: Column(
                      children: [
                            // Profilová fotka s možností změny
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                GestureDetector(
                                  onTap: _showImagePicker,
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 4),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 58,
                                      backgroundColor: Colors.white,
                                      backgroundImage: profilePhotoPath != null
                                          ? FileImage(File(profilePhotoPath!))
                                          : null,
                                      child: profilePhotoPath == null
                                          ? Text(
                                              nickname.isNotEmpty ? nickname[0].toUpperCase() : '?',
                                              style: TextStyle(
                                                fontSize: 56,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.pink.shade400,
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _showImagePicker,
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.camera_alt,
                                        size: 24,
                                        color: Colors.pink.shade400,
                                      ),
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

                            const SizedBox(height: 32),
                            
                            // Statistiky karty - moderní design
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildModernStatItem(
                                      'Návyky',
                                      '${stats['habitsCount'] ?? 0}',
                                      Icons.list_alt,
                                      Colors.blue,
                                    ),
                                    Container(width: 1, height: 40, color: Colors.grey[200]),
                                    _buildModernStatItem(
                                      'Splnění',
                                      '${stats['totalCompletions'] ?? 0}',
                                      Icons.check_circle,
                                      Colors.green,
                                    ),
                                    Container(width: 1, height: 40, color: Colors.grey[200]),
                                    _buildModernStatItem(
                                      'Tento měsíc',
                                      '${stats['monthCompletions'] ?? 0}',
                                      Icons.calendar_today,
                                      Colors.pink,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Menu options - moderní design
                            _buildModernMenuSection(),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 28, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildModernMenuSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildModernMenuItem(
            icon: Icons.bar_chart,
            title: 'Statistiky',
            subtitle: 'Podrobný přehled pokroku',
            color: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StatsScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildModernMenuItem(
            icon: Icons.emoji_events,
            title: 'Ocenění',
            subtitle: 'Zobrazit odemčená ocenění',
            color: Colors.amber,
            onTap: () {
              Navigator.pushNamed(context, '/achievements');
            },
          ),
          const SizedBox(height: 12),
          _buildModernMenuItem(
            icon: Icons.add_circle,
            title: 'Přidat návyk',
            subtitle: 'Vytvoř nový návyk',
            color: Colors.pink,
            onTap: () async {
              final result = await Navigator.pushNamed(context, '/add');
              if (result == true) {
                await _loadUserData();
              }
            },
          ),
          const SizedBox(height: 12),
          _buildModernMenuItem(
            icon: Icons.settings,
            title: 'Nastavení',
            subtitle: 'Upravit profil a nastavení',
            color: Colors.grey,
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildModernMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
