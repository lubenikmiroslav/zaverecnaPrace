import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';
import '../styles/app_styles.dart';

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
  final _targetController = TextEditingController(text: '1');
  final _affirmationController = TextEditingController();
  Color selectedColor = Colors.pink;
  IconData selectedIcon = Icons.check_circle;
  int? habitId;
  String? selectedReminderTime;
  bool hasTimer = false;
  bool syncWithHealth = false;
  String? selectedHealthMetric;

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

  // Presety oblíbených návyků
  late final List<Map<String, dynamic>> popularPresets = [
    {
      'name': 'Vyčistit zuby',
      'description': 'Ráno a večer',
      'color': Colors.orange,
      'icon': Icons.brush,
      'daily_target': 2,
      'reminder_time': null,
      'has_timer': false,
      'timer_duration': 0,
      'category': 'Zdraví',
      'affirmation': 'I AM HEALTHY + CLEAN',
    },
    {
      'name': 'Žádný telefon po 21:00',
      'description': 'Odlož mobil, připomínka v 20:30',
      'color': Colors.redAccent,
      'icon': Icons.nights_stay,
      'daily_target': 1,
      'reminder_time': '20:30',
      'has_timer': false,
      'timer_duration': 0,
      'category': 'Wellbeing',
      'affirmation': 'I AM PRESENT + FOCUSED',
    },
    {
      'name': 'Vypít 2 litry vody',
      'description': 'Sleduj pitný režim (8× sklenice)',
      'color': Colors.lightBlue,
      'icon': Icons.water_drop,
      'daily_target': 8,
      'reminder_time': null,
      'has_timer': false,
      'timer_duration': 0,
      'category': 'Zdraví',
      'affirmation': 'I AM HYDRATED + ENERGETIC',
      'sync_with_health': true,
      'health_metric_type': 'water',
    },
    {
      'name': 'Ujít 10 000 kroků',
      'description': 'Cíl 10k kroků',
      'color': Colors.green,
      'icon': Icons.directions_walk,
      'daily_target': 1,
      'reminder_time': null,
      'has_timer': false,
      'timer_duration': 0,
      'category': 'Sport',
      'affirmation': 'I AM STRONG + ATHLETIC',
      'sync_with_health': true,
      'health_metric_type': 'steps',
    },
    {
      'name': 'Meditace 30 minut',
      'description': 'Vědomý klid, nastav časovač',
      'color': Colors.teal,
      'icon': Icons.self_improvement,
      'daily_target': 1,
      'reminder_time': null,
      'has_timer': true,
      'timer_duration': 30,
      'category': 'Mindfulness',
      'affirmation': 'I AM CALM + CENTERED',
    },
    {
      'name': 'Ráno ustlat postel',
      'description': 'Začni den pořádkem',
      'color': Colors.purpleAccent,
      'icon': Icons.bed,
      'daily_target': 1,
      'reminder_time': '07:30',
      'has_timer': false,
      'timer_duration': 0,
      'category': 'Ranní rutina',
      'affirmation': 'I AM ORGANIZED + PRODUCTIVE',
    },
    {
      'name': 'Dny bez nikotinu',
      'description': 'Držím se bez nikotinu',
      'color': Colors.indigo,
      'icon': Icons.smoke_free,
      'daily_target': 1,
      'reminder_time': null,
      'has_timer': false,
      'timer_duration': 0,
      'category': 'Zdraví',
      'affirmation': 'I AM FREE + HEALTHY',
    },
    {
      'name': 'Dny bez alkoholu',
      'description': 'Žádný alkohol dnes',
      'color': Colors.deepOrange,
      'icon': Icons.wine_bar,
      'daily_target': 1,
      'reminder_time': null,
      'has_timer': false,
      'timer_duration': 0,
      'category': 'Zdraví',
      'affirmation': 'I AM CLEAR + STRONG',
    },
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
      _targetController.text = (habit['daily_target'] ?? 1).toString();
      _affirmationController.text = habit['affirmation'] ?? '';
      syncWithHealth = (habit['sync_with_health'] ?? 0) == 1;
      selectedHealthMetric = habit['health_metric_type'];
      final colorStr = habit['color'].toString().replaceAll('#', '');
      selectedColor = Color(int.parse('0xFF$colorStr'));
      selectedIcon = IconData(int.parse(habit['icon']), fontFamily: 'MaterialIcons');
    }
  }

  void _applyPreset(Map<String, dynamic> preset) {
    setState(() {
      habitId = null;
      _nameController.text = preset['name'] ?? '';
      _descriptionController.text = preset['description'] ?? '';
      _categoryController.text = preset['category'] ?? '';
      selectedColor = preset['color'] as Color? ?? Colors.pink;
      selectedIcon = preset['icon'] as IconData? ?? Icons.check_circle;
      selectedReminderTime = preset['reminder_time'] as String?;
      hasTimer = preset['has_timer'] as bool? ?? false;
      _timerDurationController.text = (preset['timer_duration'] ?? 0).toString();
      _targetController.text = (preset['daily_target'] ?? 1).toString();
      _affirmationController.text = preset['affirmation'] ?? '';
      syncWithHealth = preset['sync_with_health'] as bool? ?? false;
      selectedHealthMetric = preset['health_metric_type'] as String?;
    });
  }

  Future<void> _saveHabit() async {
    // Validace - pokud je jméno prázdné, použij default
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Zadej název návyku'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');
      if (email == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chyba: Uživatel není přihlášen'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final user = await DatabaseHelper.instance.getUserByEmail(email);
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chyba: Uživatel nenalezen'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final habitData = {
        'user_id': user['id'],
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'color': '#${selectedColor.value.toRadixString(16).substring(2)}',
        'icon': selectedIcon.codePoint.toString(),
        'category': _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
        'reminder_time': selectedReminderTime,
        'has_timer': hasTimer ? 1 : 0,
        'timer_duration': hasTimer ? (int.tryParse(_timerDurationController.text) ?? 0) : 0,
        'daily_target': int.tryParse(_targetController.text) ?? 1,
        'affirmation': _affirmationController.text.trim().isEmpty ? null : _affirmationController.text.trim(),
        'sync_with_health': 0,  // Disabled
        'health_metric_type': null,  // Disabled
        if (habitId == null) 'created_at': DateTime.now().toIso8601String(),
      };

      int newHabitId;
      if (habitId != null) {
        await DatabaseHelper.instance.updateHabit(habitId!, habitData);
        newHabitId = habitId!;
      } else {
        newHabitId = await DatabaseHelper.instance.insertHabit(habitData);
      }

      // Nastavit notifikaci, pokud je nastaven reminder time (s error handling)
      if (selectedReminderTime != null && selectedReminderTime!.isNotEmpty) {
        try {
          await NotificationService.instance.scheduleHabitReminder(
            habitId: newHabitId,
            habitName: _nameController.text.trim(),
            time: selectedReminderTime!,
          );
        } catch (e) {
          // Notifikace selhala, ale návyk je uložen - jen logujeme chybu
          print('Chyba při nastavení notifikace: $e');
          // Návyk je stále úspěšně uložen, takže pokračujeme
        }
      } else if (habitId != null) {
        // Zrušit notifikaci, pokud byla odstraněna
        try {
          await NotificationService.instance.cancelHabitReminder(habitId!);
        } catch (e) {
          print('Chyba při zrušení notifikace: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(habitId != null ? 'Návyk upraven' : 'Návyk vytvořen! 🎉'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true); // Vrátit true jako indikátor úspěchu
      }
    } catch (e) {
      print('Chyba při ukládání návyku: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba při ukládání návyku: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
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
          gradient: Theme.of(context).brightness == Brightness.dark
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.grey[900]!,
                    Colors.grey[800]!,
                  ],
                )
              : AppGradients.primaryGradient,
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
                  color: Theme.of(context).cardColor.withOpacity(0.3),
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

              // Populární návyky
              Text(
                'Populární návyky',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: popularPresets.map((preset) {
                    final presetColor = preset['color'] as Color? ?? Colors.white;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ActionChip(
                        backgroundColor: Colors.white.withOpacity(0.9),
                        label: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              preset['name'] ?? '',
                              style: TextStyle(
                                color: presetColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if ((preset['description'] as String?)?.isNotEmpty ?? false)
                              Text(
                                preset['description'],
                                style: TextStyle(color: presetColor.withOpacity(0.7), fontSize: 11),
                              ),
                          ],
                        ),
                        onPressed: () => _applyPreset(preset),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 32),

              // Kolikrát denně
              Text(
                'Kolikrát denně',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      final current = int.tryParse(_targetController.text) ?? 1;
                      if (current > 1) {
                        setState(() {
                          _targetController.text = (current - 1).toString();
                        });
                      }
                    },
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.white),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _targetController,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: selectedColor),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final val = int.tryParse(v ?? '');
                        if (val == null || val < 1) return 'Zadej alespoň 1';
                        return null;
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      final current = int.tryParse(_targetController.text) ?? 1;
                      setState(() {
                        _targetController.text = (current + 1).toString();
                      });
                    },
                    icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Affirmation
              Text(
                'Motivační zpráva (volitelné)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _affirmationController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Např. "I AM STRONG + ATHLETIC"',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
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
