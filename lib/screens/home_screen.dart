import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';
import 'timer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String nickname = '';
  int userId = 0;
  List<Map<String, dynamic>> habits = [];
  Map<int, int> completedTodayCount = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    nickname = prefs.getString('nickname') ?? '';
    final email = prefs.getString('user_email');
    if (email != null) {
      final user = await DatabaseHelper.instance.getUserByEmail(email);
      if (user != null) {
        userId = user['id'];
        await _loadHabits();
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _loadHabits() async {
    final data = await DatabaseHelper.instance.getHabits(userId);
    final todayStr = DateTime.now().toIso8601String().split('T').first;
    
    Map<int, int> todayCount = {};
    for (var habit in data) {
      final count = await DatabaseHelper.instance.getDailyCompletionCount(
        habit['id'],
        todayStr,
      );
      todayCount[habit['id']] = count;
    }
    
    setState(() {
      habits = data;
      completedTodayCount = todayCount;
    });
  }

  Future<void> _toggleHabitCompletion(int habitId) async {
    final todayStr = DateTime.now().toIso8601String().split('T').first;
    final habit = habits.firstWhere((h) => h['id'] == habitId);
    final target = (habit['daily_target'] ?? 1) as int;
    final current = completedTodayCount[habitId] ?? 0;
    
    // Pokud uživatel klikne víckrát než cíl: reset na 0
    if (current + 1 > target) {
      await DatabaseHelper.instance.removeHabitCompletionsForDate(habitId, todayStr);
      setState(() {
        completedTodayCount[habitId] = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resetováno pro dnešek')),
      );
      return;
    }

    await DatabaseHelper.instance.logHabitCompletion(habitId, DateTime.now());
    
    // Zkontroluj a odemkni achievementy
    final unlocked = await DatabaseHelper.instance.checkAndUnlockAchievements(userId, habitId);
    if (unlocked.isNotEmpty) {
      _showAchievementNotification(unlocked, habit['name']);
    }
    
    setState(() {
      completedTodayCount[habitId] = current + 1;
    });
  }

  void _showAchievementNotification(List<String> unlocked, String habitName) {
    final messages = {
      '7_day_streak': '🎉 Úžasné! 7 dní v řadě s "$habitName"!',
      '30_day_streak': '🏆 Neuvěřitelné! 30 dní v řadě s "$habitName"!',
      '100_completions': '⭐ Fantastické! 100 splnění "$habitName"!',
    };

    for (var achievement in unlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(messages[achievement] ?? 'Ocenění odemčeno!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Zobrazit',
            textColor: Colors.white,
            onPressed: () {
              Navigator.pushNamed(context, '/achievements');
            },
          ),
        ),
      );
    }
  }

  int _getCompletedCount() {
    int done = 0;
    for (var habit in habits) {
      final id = habit['id'] as int;
      final target = (habit['daily_target'] ?? 1) as int;
      final current = completedTodayCount[id] ?? 0;
      if (current >= target) done++;
    }
    return done;
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _getCompletedCount();
    final totalCount = habits.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.shade300,
                    Colors.pink.shade300,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Text(
                      nickname.isNotEmpty ? nickname[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    nickname.isNotEmpty ? nickname : 'Uživatel',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Domů'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Můj účet'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Nastavení'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to settings
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange.shade300,
              Colors.pink.shade300,
              Colors.purple.shade300,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar s hamburger menu a profile ikonou
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                    Text(
                      'HabitTrack',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.person, color: Colors.white),
                      onPressed: () {
                        Navigator.pushNamed(context, '/profile');
                      },
                    ),
                  ],
                ),
              ),
              
              // Progress indicator
              if (totalCount > 0)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Dnešní pokrok',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$completedCount z $totalCount',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

                  // Habits List
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator(color: Colors.white))
                        : habits.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.emoji_nature,
                                      size: 64,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Zatím nemáš žádné návyky',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _loadHabits,
                                color: Colors.white,
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(20),
                                  itemCount: habits.length + 1,
                                  itemBuilder: (context, index) {
                                    if (index == habits.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: _buildAddHabitCard(),
                                      );
                                    }
                                    final habit = habits[index];
                                    final habitId = habit['id'] as int;
                                    final iconCode = int.tryParse(habit['icon'] ?? '') ?? Icons.check.codePoint;
                                    final icon = IconData(iconCode, fontFamily: 'MaterialIcons');
                                    final colorStr = habit['color'].toString().replaceAll('#', '');
                                    final color = Color(int.parse('0xFF$colorStr'));
                                    final hasTimer = (habit['has_timer'] ?? 0) == 1;
                                    final target = (habit['daily_target'] ?? 1) as int;
                                    final current = completedTodayCount[habitId] ?? 0;

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: _buildHabitCard(
                                        habit: habit,
                                        icon: icon,
                                        color: color,
                                        isCompleted: current >= target,
                                        currentCount: current,
                                        targetCount: target,
                                        hasTimer: hasTimer,
                                        onTap: () => _toggleHabitCompletion(habitId),
                                        onTimer: hasTimer
                                            ? () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => TimerScreen(habit: habit),
                                                  ),
                                                );
                                              }
                                            : null,
                                        onEdit: () async {
                                          await Navigator.pushNamed(
                                            context,
                                            '/add',
                                            arguments: habit,
                                          );
                                          await _loadHabits();
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                  ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/add');
          if (result == true) {
            await _loadHabits();
          }
        },
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, color: Colors.pink),
      ),
    );
  }

  Widget _buildHabitCard({
    required Map<String, dynamic> habit,
    required IconData icon,
    required Color color,
    required bool isCompleted,
    required int currentCount,
    required int targetCount,
    required VoidCallback onTap,
    required VoidCallback onEdit,
    bool hasTimer = false,
    VoidCallback? onTimer,
  }) {
    final progress = (currentCount / targetCount).clamp(0.0, 1.0).toDouble();
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // Full-width translucent bar as background
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: Stack(
              children: [
                // Filled progress overlay
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Texts
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              habit['name'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (habit['description']?.isNotEmpty ?? false)
                              Text(
                                habit['description'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            const SizedBox(height: 6),
                            Text(
                              '$currentCount / $targetCount',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Icon bubble on right
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: color.withOpacity(0.6), width: 2),
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Menu (3 dots) in top-right
          Positioned(
            top: 6,
            right: 8,
            child: PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.more_vert, color: Colors.grey[700], size: 18),
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'delete') {
                  _showDeleteDialog(habit['id'] as int);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Upravit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Smazat', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Timer icon bottom-left
          if (hasTimer && onTimer != null)
            Positioned(
              bottom: 8,
              left: 12,
              child: GestureDetector(
                onTap: onTimer,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.timer,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showDeleteDialog(int habitId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Smazat návyk'),
        content: const Text('Opravdu chceš tento návyk smazat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Zrušit'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Smazat', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteHabit(habitId);
      await _loadHabits();
    }
  }

  Widget _buildAddHabitCard() {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.pushNamed(context, '/add');
        if (result == true) {
          await _loadHabits();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.purple.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: Colors.purple,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Přidat návyk',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
