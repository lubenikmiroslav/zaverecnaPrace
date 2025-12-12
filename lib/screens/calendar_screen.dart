import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  int userId = 0;
  DateTime selectedDate = DateTime.now();
  DateTime currentMonth = DateTime.now();
  List<Map<String, dynamic>> habits = [];
  Map<int, bool> completionStatus = {};
  Set<String> datesWithCompletions = {};
  String? currentNote;

  final List<String> weekDays = ['Po', 'Út', 'St', 'Čt', 'Pá', 'So', 'Ne'];
  final List<String> monthNames = [
    'Leden', 'Únor', 'Březen', 'Duben', 'Květen', 'Červen',
    'Červenec', 'Srpen', 'Září', 'Říjen', 'Listopad', 'Prosinec'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    if (email != null) {
      final user = await DatabaseHelper.instance.getUserByEmail(email);
      if (user != null) {
        userId = user['id'];
        await _loadHabits();
        await _loadMonthCompletions();
        await _loadDayCompletions();
      }
    }
    setState(() {});
  }

  Future<void> _loadHabits() async {
    habits = await DatabaseHelper.instance.getHabits(userId);
  }

  Future<void> _loadMonthCompletions() async {
    datesWithCompletions.clear();
    for (var habit in habits) {
      final dates = await DatabaseHelper.instance.getCompletedDatesForHabit(habit['id']);
      datesWithCompletions.addAll(dates);
    }
  }

  Future<void> _loadDayCompletions() async {
    final dateStr = selectedDate.toIso8601String().split('T').first;
    completionStatus.clear();
    for (var habit in habits) {
      final isCompleted = await DatabaseHelper.instance.isHabitCompletedForDate(
        habit['id'],
        dateStr,
      );
      completionStatus[habit['id']] = isCompleted;
    }
    // Načíst poznámku pro vybraný den
    currentNote = await DatabaseHelper.instance.getCalendarNote(userId, dateStr);
    setState(() {});
  }

  Future<void> _toggleHabitCompletion(int habitId) async {
    final dateStr = selectedDate.toIso8601String().split('T').first;
    final isCompleted = completionStatus[habitId] ?? false;

    if (isCompleted) {
      await DatabaseHelper.instance.removeHabitCompletion(habitId, dateStr);
    } else {
      await DatabaseHelper.instance.logHabitCompletion(habitId, selectedDate);
    }

    await _loadMonthCompletions();
    await _loadDayCompletions();
  }

  void _previousMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month - 1);
    });
    _loadMonthCompletions();
  }

  void _nextMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
    });
    _loadMonthCompletions();
  }

  void _selectDate(DateTime date) {
    setState(() {
      selectedDate = date;
    });
    _loadDayCompletions();
  }

  Future<void> _editNote() async {
    final dateStr = selectedDate.toIso8601String().split('T').first;
    final controller = TextEditingController(text: currentNote ?? '');
    
    final newNote = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Poznámka - ${selectedDate.day}. ${monthNames[selectedDate.month - 1]}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Napiš poznámku k tomuto dni...',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
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

    if (newNote != null) {
      if (newNote.isEmpty) {
        await DatabaseHelper.instance.deleteCalendarNote(userId, dateStr);
        currentNote = null;
      } else {
        await DatabaseHelper.instance.saveCalendarNote(userId, dateStr, newNote);
        currentNote = newNote;
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    const Text(
                      'Kalendář',
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
              // Calendar Section
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
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
                    _buildMonthSelector(),
                    const SizedBox(height: 16),
                    _buildWeekDaysHeader(),
                    const SizedBox(height: 8),
                    _buildCalendarGrid(),
                  ],
                ),
              ),
              // Selected Date & Habits
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildSelectedDateHeader(),
                      _buildNoteSection(),
                      Expanded(child: _buildHabitsList()),
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

  Widget _buildMonthSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left, color: Colors.grey[700]),
          onPressed: _previousMonth,
        ),
        Text(
          '${monthNames[currentMonth.month - 1]} ${currentMonth.year}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        IconButton(
          icon: Icon(Icons.chevron_right, color: Colors.grey[700]),
          onPressed: _nextMonth,
        ),
      ],
    );
  }

  Widget _buildWeekDaysHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekDays.map((day) => SizedBox(
        width: 40,
        child: Center(
          child: Text(
            day,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDayOfMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0);
    
    // Pondělí = 1, Neděle = 7 -> posun pro grid
    int startingWeekday = firstDayOfMonth.weekday - 1; // 0 = pondělí
    
    final daysInMonth = lastDayOfMonth.day;
    final totalCells = ((startingWeekday + daysInMonth) / 7).ceil() * 7;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1,
        ),
        itemCount: totalCells,
        itemBuilder: (context, index) {
          final dayOffset = index - startingWeekday;
          
          if (dayOffset < 0 || dayOffset >= daysInMonth) {
            return const SizedBox();
          }

          final day = dayOffset + 1;
          final date = DateTime(currentMonth.year, currentMonth.month, day);
          final dateStr = date.toIso8601String().split('T').first;
          final hasCompletions = datesWithCompletions.contains(dateStr);
          final isSelected = selectedDate.year == date.year &&
              selectedDate.month == date.month &&
              selectedDate.day == date.day;
          final isToday = DateTime.now().year == date.year &&
              DateTime.now().month == date.month &&
              DateTime.now().day == date.day;

          return GestureDetector(
            onTap: () => _selectDate(date),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.pink.shade400
                    : hasCompletions
                        ? Colors.pink.shade50
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isToday
                    ? Border.all(
                        color: Colors.pink.shade400,
                        width: 2,
                      )
                    : null,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : (isToday ? Colors.pink.shade400 : Colors.black87),
                        fontSize: 14,
                      ),
                    ),
                    if (hasCompletions && !isSelected)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.pink.shade400,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedDateHeader() {
    final dayNames = ['Pondělí', 'Úterý', 'Středa', 'Čtvrtek', 'Pátek', 'Sobota', 'Neděle'];
    final dayName = dayNames[selectedDate.weekday - 1];
    
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      width: double.infinity,
      child: Text(
        '$dayName, ${selectedDate.day}. ${monthNames[selectedDate.month - 1]} ${selectedDate.year}',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildNoteSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.note_outlined,
                    color: Colors.pink.shade400,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Poznámka',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  currentNote == null ? Icons.add_circle_outline : Icons.edit_outlined,
                  color: Colors.pink.shade400,
                ),
                onPressed: _editNote,
              ),
            ],
          ),
          if (currentNote != null && currentNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              currentNote!,
              style: const TextStyle(fontSize: 14),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'Klikni na + pro přidání poznámky',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHabitsList() {
    if (habits.isEmpty) {
      return const Center(
        child: Text('Zatím nemáš žádné návyky'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: habits.length,
      itemBuilder: (context, index) {
        final habit = habits[index];
        final habitId = habit['id'] as int;
        final isCompleted = completionStatus[habitId] ?? false;
        final iconCode = int.tryParse(habit['icon'] ?? '') ?? Icons.check.codePoint;
        final icon = IconData(iconCode, fontFamily: 'MaterialIcons');
        final color = Color(int.parse('0xFF${habit['color'].toString().replaceAll('#', '')}'));

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCompleted ? color : Colors.grey[200]!,
              width: isCompleted ? 2 : 1,
            ),
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
                padding: const EdgeInsets.all(10),
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
                      habit['name'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? color : Colors.black87,
                      ),
                    ),
                    if (habit['description']?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 4),
                      Text(
                        habit['description'],
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Checkbox(
                value: isCompleted,
                activeColor: color,
                onChanged: (val) => _toggleHabitCompletion(habitId),
              ),
            ],
          ),
        );
      },
    );
  }
}

