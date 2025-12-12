import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';

class HabitDetailScreen extends StatefulWidget {
  final Map<String, dynamic> habit;

  const HabitDetailScreen({super.key, required this.habit});

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  int userId = 0;
  bool isCompleted = false;
  int streak = 0;
  int totalCompletions = 0;
  Timer? _timer;
  int _timerSeconds = 0;
  bool _isTimerRunning = false;
  int? _habitTimerDuration;

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
        final todayStr = DateTime.now().toIso8601String().split('T').first;
        isCompleted = await DatabaseHelper.instance.isHabitCompletedForDate(
          widget.habit['id'],
          todayStr,
        );
        streak = await DatabaseHelper.instance.getHabitStreak(widget.habit['id']);
        final logs = await DatabaseHelper.instance.getHabitLogs(widget.habit['id']);
        totalCompletions = logs.length;
        _habitTimerDuration = widget.habit['timer_duration'] as int? ?? 0;
        setState(() {});
      }
    }
  }

  Future<void> _toggleCompletion() async {
    final todayStr = DateTime.now().toIso8601String().split('T').first;
    
    if (isCompleted) {
      await DatabaseHelper.instance.removeHabitCompletion(widget.habit['id'], todayStr);
    } else {
      await DatabaseHelper.instance.logHabitCompletion(widget.habit['id'], DateTime.now());
      await DatabaseHelper.instance.checkAndUnlockAchievements(userId, widget.habit['id']);
    }
    
    await _loadData();
  }

  void _startTimer() {
    if (_habitTimerDuration == null || _habitTimerDuration == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tento návyk nemá nastavený časovač')),
      );
      return;
    }

    setState(() {
      _timerSeconds = _habitTimerDuration! * 60; // převod na sekundy
      _isTimerRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timerSeconds > 0) {
          _timerSeconds--;
        } else {
          _timer?.cancel();
          _isTimerRunning = false;
          _showTimerComplete();
        }
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _timerSeconds = 0;
    });
  }

  void _showTimerComplete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Časovač dokončen! 🎉'),
        content: const Text('Výborně! Dokončil jsi svůj návyk.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _toggleCompletion();
            },
            child: const Text('Označit jako splněno'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconCode = int.tryParse(widget.habit['icon'] ?? '') ?? Icons.check.codePoint;
    final icon = IconData(iconCode, fontFamily: 'MaterialIcons');
    final colorStr = widget.habit['color'].toString().replaceAll('#', '');
    final color = Color(int.parse('0xFF$colorStr'));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.habit['name']),
        backgroundColor: color,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.pushNamed(
                context,
                '/add',
                arguments: widget.habit,
              );
              await _loadData();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header s ikonou
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 50, color: color),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.habit['name'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (widget.habit['description']?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.habit['description'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Statistiky
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard('Série', '$streak dní', Icons.local_fire_department, Colors.orange),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard('Celkem', '$totalCompletions×', Icons.done_all, Colors.green),
                  ),
                ],
              ),
            ),

            // Časovač (pokud je nastaven)
            if (_habitTimerDuration != null && _habitTimerDuration! > 0) ...[
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color),
                ),
                child: Column(
                  children: [
                    Text(
                      _isTimerRunning ? _formatTime(_timerSeconds) : '${_habitTimerDuration} min',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!_isTimerRunning)
                          ElevatedButton.icon(
                            onPressed: _startTimer,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Spustit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color,
                              foregroundColor: Colors.white,
                            ),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: _stopTimer,
                            icon: const Icon(Icons.stop),
                            label: const Text('Zastavit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // Tlačítko splnění
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _toggleCompletion,
                  style: FilledButton.styleFrom(
                    backgroundColor: isCompleted ? Colors.grey : color,
                  ),
                  child: Text(
                    isCompleted ? 'Označit jako nesplněno' : 'Označit jako splněno',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

