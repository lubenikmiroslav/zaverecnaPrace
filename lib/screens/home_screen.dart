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
  Map<int, bool> completedToday = {}; // stav splnění pro dnešní den

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
      final user = await DatabaseHelper.instance.loginUser(email, '');
      if (user != null) {
        userId = user['id'];
        await _loadHabits();
      }
    }
    setState(() {});
  }

  Future<void> _loadHabits() async {
    final data = await DatabaseHelper.instance.getHabits(userId);
    setState(() {
      habits = data;
      completedToday = {}; // reset stavu při načtení
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');
    await prefs.remove('nickname');
    Navigator.pushReplacementNamed(context, '/');
  }

  Future<void> _deleteHabit(int habitId) async {
    await DatabaseHelper.instance.deleteHabit(habitId);
    await _loadHabits();
  }

  Future<void> _markHabitCompleted(int habitId) async {
    await DatabaseHelper.instance.logHabitCompletion(habitId, DateTime.now());
    setState(() {
      completedToday[habitId] = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Návyk označen jako splněný')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Moje návyky – $nickname'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Odhlásit se',
            onPressed: _logout,
          ),
        ],
      ),
      body: habits.isEmpty
          ? const Center(child: Text('Zatím nemáš žádné návyky'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: habits.length,
              itemBuilder: (context, index) {
                final habit = habits[index];
                final habitId = habit['id'] as int;
                final iconCode = int.tryParse(habit['icon'] ?? '') ?? Icons.check.codePoint;
                final icon = IconData(iconCode, fontFamily: 'MaterialIcons');
                final color = Color(int.parse('0xFF${habit['color'].toString().replaceAll('#', '')}'));
                final isCompleted = completedToday[habitId] ?? false;

                return Card(
                  elevation: 2,
                  child: ListTile(
                    leading: Icon(icon, color: color),
                    title: Text(habit['name']),
                    subtitle: Text(habit['description'] ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: isCompleted,
                          onChanged: isCompleted
                              ? null
                              : (val) async {
                                  await _markHabitCompleted(habitId);
                                },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.grey),
                          tooltip: 'Upravit',
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/add',
                              arguments: habit,
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Smazat',
                          onPressed: () async {
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
                                    child: const Text('Smazat'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await _deleteHabit(habitId);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, '/add');
          await _loadHabits(); // obnovit seznam po návratu
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
