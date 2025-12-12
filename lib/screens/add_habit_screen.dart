import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';

class AddHabitScreen extends StatefulWidget {
  const AddHabitScreen({super.key});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _timerDurationController = TextEditingController();
  Color selectedColor = Colors.pink;
  IconData selectedIcon = Icons.check_circle;
  int? habitId;
  String? selectedReminderTime;
  bool hasTimer = false;

  final List<String> commonCategories = [
    'Zdraví',
    'Sport',
    'Vzdělávání',
    'Práce',
    'Osobní',
    'Společenské',
    'Kreativita',
  ];

  final List<Color> availableColors = [
    Colors.pink,
    Colors.red,
    Colors.orange,
    Colors.amber,
    Colors.green,
    Colors.teal,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
    Colors.deepPurple,
  ];

  final List<IconData> availableIcons = [
    Icons.local_drink,
    Icons.fitness_center,
    Icons.directions_walk,
    Icons.directions_run,
    Icons.pool,
    Icons.bedtime,
    Icons.book,
    Icons.menu_book,
    Icons.check_circle,
    Icons.favorite,
    Icons.restaurant,
    Icons.cleaning_services,
    Icons.self_improvement,
    Icons.water_drop,
    Icons.air,
    Icons.sunny,
    Icons.nightlight,
    Icons.sports_basketball,
    Icons.sports_soccer,
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final habit = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (habit != null) {
      habitId = habit['id'];
      _nameController.text = habit['name'] ?? '';
      _descriptionController.text = habit['description'] ?? '';
      _categoryController.text = habit['category'] ?? '';
      selectedReminderTime = habit['reminder_time'];
      hasTimer = (habit['has_timer'] ?? 0) == 1;
      _timerDurationController.text = habit['timer_duration']?.toString() ?? '';
      final colorStr = habit['color'].toString().replaceAll('#', '');
      selectedColor = Color(int.parse('0xFF$colorStr'));
      selectedIcon = IconData(int.parse(habit['icon']), fontFamily: 'MaterialIcons');
    }
  }

  Future<void> _saveHabit() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');
      final user = await DatabaseHelper.instance.getUserByEmail(email!);

      final habitData = {
        'user_id': user!['id'],
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'color': '#${selectedColor.value.toRadixString(16).substring(2)}',
        'icon': selectedIcon.codePoint.toString(),
        'category': _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
        'reminder_time': selectedReminderTime,
        'has_timer': hasTimer ? 1 : 0,
        'timer_duration': hasTimer ? (int.tryParse(_timerDurationController.text) ?? 0) : 0,
        if (habitId == null) 'created_at': DateTime.now().toIso8601String(),
      };

      int newHabitId;
      if (habitId != null) {
        await DatabaseHelper.instance.updateHabit(habitId!, habitData);
        newHabitId = habitId!;
      } else {
        newHabitId = await DatabaseHelper.instance.insertHabit(habitData);
      }

      // Nastavit notifikaci, pokud je nastaven reminder time
      if (selectedReminderTime != null && selectedReminderTime!.isNotEmpty) {
        await NotificationService.instance.scheduleHabitReminder(
          habitId: newHabitId,
          habitName: _nameController.text.trim(),
          time: selectedReminderTime!,
        );
      } else if (habitId != null) {
        // Zrušit notifikaci, pokud byla odstraněna
        await NotificationService.instance.cancelHabitReminder(habitId!);
      }

      if (mounted) {
        Navigator.pop(context, true); // Vrátit true jako indikátor úspěchu
      }
    }
  }

  Future<void> _selectReminderTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedReminderTime != null
          ? TimeOfDay(
              hour: int.parse(selectedReminderTime!.split(':')[0]),
              minute: int.parse(selectedReminderTime!.split(':')[1]),
            )
          : TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        selectedReminderTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = habitId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Upravit návyk' : 'Přidat návyk'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Možnost vyhledávání návyků v budoucnu
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey[900]!,
              Colors.grey[800]!,
            ],
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Náhled návyku
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: selectedColor.withOpacity(0.3),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selectedColor,
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        selectedIcon,
                        color: selectedColor,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _nameController.text.isEmpty ? 'Název návyku' : _nameController.text,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (_descriptionController.text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _descriptionController.text,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Název návyku
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Název návyku',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: selectedColor),
                  ),
                  fillColor: Colors.white.withOpacity(0.1),
                  filled: true,
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Zadej název návyku' : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),

              // Popis
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Popis (volitelné)',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: selectedColor),
                  ),
                  fillColor: Colors.white.withOpacity(0.1),
                  filled: true,
                ),
                maxLines: 2,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 32),

              // Barvy
              Text(
                'Vyber barvu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: availableColors.map((color) => _colorDot(color)).toList(),
              ),
              const SizedBox(height: 32),

              // Ikony
              Text(
                'Vyber ikonu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: availableIcons.map((icon) => _iconButton(icon)).toList(),
                ),
              ),
              const SizedBox(height: 32),

              // Kategorie
              Text(
                'Kategorie (volitelné)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...commonCategories.map((cat) => FilterChip(
                    label: Text(cat),
                    selected: _categoryController.text == cat,
                    onSelected: (selected) {
                      setState(() {
                        _categoryController.text = selected ? cat : '';
                      });
                    },
                    selectedColor: selectedColor.withOpacity(0.3),
                    checkmarkColor: selectedColor,
                  )),
                  ActionChip(
                    label: const Text('+ Vlastní'),
                    onPressed: () async {
                      final custom = await showDialog<String>(
                        context: context,
                        builder: (context) {
                          final controller = TextEditingController();
                          return AlertDialog(
                            title: const Text('Vlastní kategorie'),
                            content: TextField(
                              controller: controller,
                              decoration: const InputDecoration(
                                labelText: 'Název kategorie',
                                hintText: 'Např. Ranní rutina',
                              ),
                              autofocus: true,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Zrušit'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, controller.text.trim()),
                                child: const Text('Přidat'),
                              ),
                            ],
                          );
                        },
                      );
                      if (custom != null && custom.isNotEmpty) {
                        setState(() {
                          _categoryController.text = custom;
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Časovač
              SwitchListTile(
                title: const Text(
                  'Použít časovač',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Pro časové návyky (např. 30 min čtení)',
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
                value: hasTimer,
                activeColor: selectedColor,
                onChanged: (value) {
                  setState(() {
                    hasTimer = value;
                  });
                },
              ),
              if (hasTimer) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _timerDurationController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Délka v minutách',
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: selectedColor),
                    ),
                    fillColor: Colors.white.withOpacity(0.1),
                    filled: true,
                    suffixText: 'min',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
              const SizedBox(height: 32),

              // Připomínka
              ListTile(
                title: const Text(
                  'Připomínka',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  selectedReminderTime ?? 'Nastavit čas připomínky',
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selectedReminderTime != null)
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            selectedReminderTime = null;
                          });
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.access_time, color: Colors.white),
                      onPressed: _selectReminderTime,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Tlačítko uložit
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _saveHabit,
                  style: FilledButton.styleFrom(
                    backgroundColor: selectedColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isEditing ? 'Uložit změny' : 'Vytvořit návyk',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _colorDot(Color color) {
    final isSelected = selectedColor == color;
    return GestureDetector(
      onTap: () => setState(() => selectedColor = color),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 24)
            : null,
      ),
    );
  }

  Widget _iconButton(IconData icon) {
    final isSelected = selectedIcon == icon;
    return GestureDetector(
      onTap: () => setState(() => selectedIcon = icon),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? selectedColor : Colors.white.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Icon(
          icon,
          color: isSelected ? selectedColor : Colors.white.withOpacity(0.7),
          size: 24,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _timerDurationController.dispose();
    super.dispose();
  }
}
