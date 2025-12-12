import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';
import '../services/health_service.dart';
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
  Map<int, int> habitStreaks = {};
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
    Map<int, int> streaks = {};
    
    for (var habit in data) {
      final habitId = habit['id'] as int;
      final count = await DatabaseHelper.instance.getDailyCompletionCount(
        habitId,
        todayStr,
      );
      todayCount[habitId] = count;
      
      // Načíst streak
      final streak = await DatabaseHelper.instance.getHabitStreak(habitId);
      streaks[habitId] = streak;
      
      // Pokud je návyk synchronizován se zdravím, načíst data
      if ((habit['sync_with_health'] ?? 0) == 1) {
        await _syncHealthData(habit);
      }
    }
    
    setState(() {
      habits = data;
      completedTodayCount = todayCount;
      habitStreaks = streaks;
    });
  }
  
  Future<void> _syncHealthData(Map<String, dynamic> habit) async {
    try {
      final healthService = HealthService.instance;
      await healthService.initialize();
      
      if (!await healthService.isAvailable()) {
        final granted = await healthService.requestPermissions();
        if (!granted) return; // Uživatel nepovolil oprávnění
      }
      
      final metricType = habit['health_metric_type'] as String?;
      if (metricType == null) return;
      
      final habitId = habit['id'] as int;
      final todayStr = DateTime.now().toIso8601String().split('T').first;
      
      int? healthValue;
      int target = (habit['daily_target'] ?? 1) as int;
      
      switch (metricType) {
        case 'steps':
          healthValue = await healthService.getStepsToday();
          // Pro kroky: pokud máš 10000 kroků jako cíl, pak 10000 kroků = 1 splnění
          if (healthValue != null && target > 0) {
            final completionCount = (healthValue >= (target * 1000)) ? 1 : 0; // 10k kroků = 1 splnění
            final existingCount = await DatabaseHelper.instance.getDailyCompletionCount(habitId, todayStr);
            
            if (completionCount != existingCount) {
              await DatabaseHelper.instance.removeHabitCompletionsForDate(habitId, todayStr);
              if (completionCount > 0) {
                await DatabaseHelper.instance.logHabitCompletion(habitId, DateTime.now());
              }
              setState(() {
                completedTodayCount[habitId] = completionCount;
              });
            }
          }
          break;
        case 'water':
          final waterLiters = await healthService.getWaterToday();
          if (waterLiters != null && target > 0) {
            // Pro vodu: pokud máš 2 litry jako cíl, pak 2 litry = 1 splnění
            final completionCount = (waterLiters >= target) ? 1 : 0;
            final existingCount = await DatabaseHelper.instance.getDailyCompletionCount(habitId, todayStr);
            
            if (completionCount != existingCount) {
              await DatabaseHelper.instance.removeHabitCompletionsForDate(habitId, todayStr);
              if (completionCount > 0) {
                await DatabaseHelper.instance.logHabitCompletion(habitId, DateTime.now());
              }
              setState(() {
                completedTodayCount[habitId] = completionCount;
              });
            }
          }
          break;
        case 'calories':
          // TODO: implementovat kalorie
          break;
      }
    } catch (e) {
      print('Error syncing health data: $e');
      // Tichá chyba - nechceme rušit uživatele
    }
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
    
    // Aktualizovat streak
    final newStreak = await DatabaseHelper.instance.getHabitStreak(habitId);
    setState(() {
      habitStreaks[habitId] = newStreak;
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'HabitTrack',
                      style: TextStyle(
                        fontFamily: 'Howdybun',
                        fontSize: 32,
                        fontWeight: FontWeight.normal,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/profile'),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                        ),
                        child: Icon(Icons.person, color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Modern Progress Card
              if (totalCount > 0)
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 8, 20, 20),
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
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Dnešní pokrok',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.pink.shade400,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$completedCount',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Colors.pink.shade400,
                              height: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8, left: 4),
                            child: Text(
                              '/ $totalCount',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.grey[400],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.pink.shade400),
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
                                        streak: habitStreaks[habitId] ?? 0,
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
    int streak = 0,
  }) {
    final progress = (currentCount / targetCount).clamp(0.0, 1.0).toDouble();
    final affirmation = habit['affirmation'] as String?;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // Modern card design
          Container(
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Filled progress overlay
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
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
                            if (affirmation != null && affirmation.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  affirmation,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: color.withOpacity(0.8),
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            if (habit['description']?.isNotEmpty ?? false)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  habit['description'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  '$currentCount / $targetCount',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                if (streak > 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.local_fire_department, size: 12, color: Colors.orange),
                                        const SizedBox(width: 2),
                                        Text(
                                          '$streak',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Modern icon on right
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, color.withOpacity(0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(icon, color: Colors.white, size: 26),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Menu (3 dots) in top-right
          Positioned(
            top: 8,
            right: 8,
            child: PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.more_vert, color: Colors.grey[600], size: 18),
              ),
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
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 2,
            style: BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.pink.shade400, Colors.pink.shade300],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Přidat návyk',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Začni nový návyk',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
