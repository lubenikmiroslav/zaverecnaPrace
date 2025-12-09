import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String nickname = '';
  int userId = 0;
  List<Map<String, dynamic>> habits = [];
  Map<int, bool> completedToday = {};
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
    
    Map<int, bool> todayStatus = {};
    for (var habit in data) {
      final isCompleted = await DatabaseHelper.instance.isHabitCompletedForDate(
        habit['id'],
        todayStr,
      );
      todayStatus[habit['id']] = isCompleted;
    }
    
    setState(() {
      habits = data;
      completedToday = todayStatus;
    });
  }

  Future<void> _toggleHabitCompletion(int habitId) async {
    final todayStr = DateTime.now().toIso8601String().split('T').first;
    final isCompleted = completedToday[habitId] ?? false;
    
    if (isCompleted) {
      await DatabaseHelper.instance.removeHabitCompletion(habitId, todayStr);
    } else {
      await DatabaseHelper.instance.logHabitCompletion(habitId, DateTime.now());
    }
    
    setState(() {
      completedToday[habitId] = !isCompleted;
    });
  }

  int _getCompletedCount() {
    return completedToday.values.where((v) => v).length;
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

              // Habits Grid
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
                            child: GridView.builder(
                              padding: const EdgeInsets.all(20),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.85,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: habits.length + 1, // +1 pro tlačítko "Přidat"
                              itemBuilder: (context, index) {
                                if (index == habits.length) {
                                  // Tlačítko pro přidání návyku
                                  return _buildAddHabitCard();
                                }
                                
                                final habit = habits[index];
                                final habitId = habit['id'] as int;
                                final isCompleted = completedToday[habitId] ?? false;
                                final iconCode = int.tryParse(habit['icon'] ?? '') ?? Icons.check.codePoint;
                                final icon = IconData(iconCode, fontFamily: 'MaterialIcons');
                                final colorStr = habit['color'].toString().replaceAll('#', '');
                                final color = Color(int.parse('0xFF$colorStr'));

                                return _buildHabitCard(
                                  habit: habit,
                                  icon: icon,
                                  color: color,
                                  isCompleted: isCompleted,
                                  onTap: () => _toggleHabitCompletion(habitId),
                                  onEdit: () async {
                                    await Navigator.pushNamed(
                                      context,
                                      '/add',
                                      arguments: habit,
                                    );
                                    await _loadHabits();
                                  },
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
          await Navigator.pushNamed(context, '/add');
          await _loadHabits();
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
    required VoidCallback onTap,
    required VoidCallback onEdit,
  }) {
    // Počet splnění (streak)
    final streak = 0; // TODO: vypočítat streak
    
    return GestureDetector(
      onTap: onTap,
      onLongPress: onEdit,
      child: Container(
        decoration: BoxDecoration(
          color: isCompleted ? color.withOpacity(0.3) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCompleted ? color : Colors.white,
            width: isCompleted ? 3 : 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ikona v kruhu
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: isCompleted ? color : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                color: isCompleted ? Colors.white : color,
                size: 35,
              ),
            ),
            const SizedBox(height: 12),
            // Název návyku
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                habit['name'],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isCompleted ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            // Popis nebo streak
            if (habit['description']?.isNotEmpty ?? false)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  habit['description'],
                  style: TextStyle(
                    fontSize: 11,
                    color: isCompleted 
                        ? Colors.white.withOpacity(0.8) 
                        : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            // Streak číslo dole
            if (streak > 0)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$streak',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddHabitCard() {
    return GestureDetector(
      onTap: () async {
        await Navigator.pushNamed(context, '/add');
        await _loadHabits();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 35,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Přidat návyk',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
