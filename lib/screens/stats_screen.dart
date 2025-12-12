import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/database_helper.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int userId = 0;
  Map<String, dynamic> stats = {};
  List<Map<String, dynamic>> habits = [];
  Map<int, List<String>> habitCompletionDates = {};
  bool isLoading = true;

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
        stats = await DatabaseHelper.instance.getUserStats(userId);
        habits = await DatabaseHelper.instance.getHabits(userId);
        
        for (var habit in habits) {
          final dates = await DatabaseHelper.instance.getCompletedDatesForHabit(habit['id']);
          habitCompletionDates[habit['id']] = dates;
        }
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  int _calculateStreak(List<String> dates) {
    if (dates.isEmpty) return 0;
    
    final sortedDates = dates.map((d) => DateTime.parse(d)).toList()
      ..sort((a, b) => b.compareTo(a)); // seřazeno od nejnovějšího

    final today = DateTime.now();
    final todayStr = today.toIso8601String().split('T').first;
    final yesterdayStr = today.subtract(const Duration(days: 1)).toIso8601String().split('T').first;
    
    // Pokud dnes ani včera nebylo splněno, streak je 0
    if (!dates.contains(todayStr) && !dates.contains(yesterdayStr)) {
      return 0;
    }

    int streak = 0;
    DateTime checkDate = dates.contains(todayStr) ? today : today.subtract(const Duration(days: 1));
    
    for (int i = 0; i < 365; i++) {
      final checkStr = checkDate.toIso8601String().split('T').first;
      if (dates.contains(checkStr)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    
    return streak;
  }

  double _calculateCompletionRate(List<String> dates, DateTime createdAt) {
    if (dates.isEmpty) return 0;
    
    final today = DateTime.now();
    final daysSinceCreation = today.difference(createdAt).inDays + 1;
    final maxDays = daysSinceCreation > 30 ? 30 : daysSinceCreation;
    
    // Počet splnění za posledních maxDays dní
    int completions = 0;
    for (int i = 0; i < maxDays; i++) {
      final checkDate = today.subtract(Duration(days: i));
      final checkStr = checkDate.toIso8601String().split('T').first;
      if (dates.contains(checkStr)) {
        completions++;
      }
    }
    
    return (completions / maxDays) * 100;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Statistiky'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiky'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewCards(),
            const SizedBox(height: 24),
            _buildSectionTitle('Přehled návyků'),
            const SizedBox(height: 12),
            _buildHabitStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Celkem návyků',
                '${stats['habitsCount'] ?? 0}',
                Icons.list_alt,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Celkem splnění',
                '${stats['totalCompletions'] ?? 0}',
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Za 7 dní',
                '${stats['weekCompletions'] ?? 0}',
                Icons.date_range,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Za 30 dní',
                '${stats['monthCompletions'] ?? 0}',
                Icons.calendar_month,
                Colors.purple,
              ),
            ),
          ],
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
                fontSize: 28,
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
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildHabitStats() {
    if (habits.isEmpty) {
      return Card(
        child: Container(
          padding: const EdgeInsets.all(32),
          width: double.infinity,
          child: const Column(
            children: [
              Icon(Icons.info_outline, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Zatím nemáš žádné návyky',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: habits.map((habit) {
        final habitId = habit['id'] as int;
        final dates = habitCompletionDates[habitId] ?? [];
        final streak = _calculateStreak(dates);
        final createdAt = DateTime.tryParse(habit['created_at'] ?? '') ?? DateTime.now();
        final completionRate = _calculateCompletionRate(dates, createdAt);
        
        final iconCode = int.tryParse(habit['icon'] ?? '') ?? Icons.check.codePoint;
        final icon = IconData(iconCode, fontFamily: 'MaterialIcons');
        final color = Color(int.parse('0xFF${habit['color'].toString().replaceAll('#', '')}'));

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        habit['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniStat(
                        'Aktuální série',
                        '$streak dní',
                        Icons.local_fire_department,
                        Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _buildMiniStat(
                        'Celkem splnění',
                        '${dates.length}×',
                        Icons.done_all,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildProgressBar(completionRate, color),
                const SizedBox(height: 4),
                Text(
                  'Úspěšnost: ${completionRate.toStringAsFixed(0)}% (posledních 30 dní)',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                _buildWeeklyChart(dates, color),
                const SizedBox(height: 16),
                _buildMonthlyTrendChart(dates, color),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWeeklyChart(List<String> completedDates, Color color) {
    final today = DateTime.now();
    final days = ['Po', 'Út', 'St', 'Čt', 'Pá', 'So', 'Ne'];
    
    final spots = List.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      final dateStr = date.toIso8601String().split('T').first;
      final isCompleted = completedDates.contains(dateStr);
      return FlSpot(index.toDouble(), isCompleted ? 1.0 : 0.0);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Posledních 7 dní:',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 1,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < 7) {
                        final date = today.subtract(Duration(days: 6 - value.toInt()));
                        final dayIndex = (date.weekday - 1) % 7;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            days[dayIndex],
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: spots.asMap().entries.map((entry) {
                final index = entry.key;
                final spot = entry.value;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: spot.y,
                      color: spot.y > 0 ? color : Colors.grey[300],
                      width: 20,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyTrendChart(List<String> completedDates, Color color) {
    final today = DateTime.now();
    final last30Days = List.generate(30, (index) {
      final date = today.subtract(Duration(days: 29 - index));
      final dateStr = date.toIso8601String().split('T').first;
      return completedDates.contains(dateStr);
    });

    final spots = last30Days.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value ? 1.0 : 0.0);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trend za posledních 30 dní:',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey[200]!,
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() % 7 == 0 && value.toInt() < 30) {
                        final date = today.subtract(Duration(days: 29 - value.toInt()));
                        return Text(
                          DateFormat('d.M').format(date),
                          style: const TextStyle(fontSize: 10),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                  left: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: color,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: color.withOpacity(0.1),
                  ),
                ),
              ],
              minY: 0,
              maxY: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressBar(double percentage, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: percentage / 100,
        minHeight: 8,
        backgroundColor: Colors.grey[200],
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }

  Widget _buildWeeklyView(List<String> completedDates, Color color) {
    final today = DateTime.now();
    final days = ['Po', 'Út', 'St', 'Čt', 'Pá', 'So', 'Ne'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Posledních 7 dní:',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (index) {
            final date = today.subtract(Duration(days: 6 - index));
            final dateStr = date.toIso8601String().split('T').first;
            final isCompleted = completedDates.contains(dateStr);
            final dayIndex = (date.weekday - 1) % 7;
            
            return Column(
              children: [
                Text(
                  days[dayIndex],
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isCompleted ? color : Colors.grey[200],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

