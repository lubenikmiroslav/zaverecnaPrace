import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  int userId = 0;
  List<Map<String, dynamic>> achievements = [];
  List<Map<String, dynamic>> habits = [];
  bool isLoading = true;

  final Map<String, Map<String, dynamic>> achievementTypes = {
    '7_day_streak': {
      'title': '7 dní v řadě',
      'description': 'Splň návyk 7 dní po sobě',
      'icon': Icons.local_fire_department,
      'color': Colors.orange,
    },
    '30_day_streak': {
      'title': '30 dní v řadě',
      'description': 'Splň návyk 30 dní po sobě',
      'icon': Icons.emoji_events,
      'color': Colors.amber,
    },
    '100_completions': {
      'title': '100 splnění',
      'description': 'Splň návyk celkem 100×',
      'icon': Icons.star,
      'color': Colors.purple,
    },
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    if (email != null) {
      final user = await DatabaseHelper.instance.getUserByEmail(email);
      if (user != null) {
        userId = user['id'];
        achievements = await DatabaseHelper.instance.getUserAchievements(userId);
        habits = await DatabaseHelper.instance.getHabits(userId);
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  Map<String, bool> _getUnlockedAchievements() {
    final unlocked = <String, bool>{};
    for (var achievement in achievements) {
      final key = '${achievement['habit_id']}_${achievement['type']}';
      unlocked[key] = true;
    }
    return unlocked;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ocenění'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final unlocked = _getUnlockedAchievements();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ocenění'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: habits.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Zatím nemáš žádné návyky',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: habits.map((habit) {
                final habitId = habit['id'] as int;
                return _buildHabitAchievements(habit, habitId, unlocked);
              }).toList(),
            ),
    );
  }

  Widget _buildHabitAchievements(
    Map<String, dynamic> habit,
    int habitId,
    Map<String, bool> unlocked,
  ) {
    final iconCode = int.tryParse(habit['icon'] ?? '') ?? Icons.check.codePoint;
    final icon = IconData(iconCode, fontFamily: 'MaterialIcons');
    final colorStr = habit['color'].toString().replaceAll('#', '');
    final color = Color(int.parse('0xFF$colorStr'));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    habit['name'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...achievementTypes.entries.map((entry) {
              final key = '${habitId}_${entry.key}';
              final isUnlocked = unlocked[key] ?? false;
              final achievement = entry.value;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? achievement['color'].withOpacity(0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isUnlocked
                        ? achievement['color']
                        : Colors.grey[300]!,
                    width: isUnlocked ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isUnlocked
                            ? achievement['color']
                            : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        achievement['icon'],
                        color: isUnlocked ? Colors.white : Colors.grey[600],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            achievement['title'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isUnlocked ? Colors.black87 : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            achievement['description'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isUnlocked)
                      Icon(
                        Icons.check_circle,
                        color: achievement['color'],
                        size: 24,
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

