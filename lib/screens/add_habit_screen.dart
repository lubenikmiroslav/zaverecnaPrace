import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';

class AddHabitScreen extends StatefulWidget {
  const AddHabitScreen({super.key});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  Color selectedColor = Colors.teal;
  IconData selectedIcon = Icons.check_circle;
  int? habitId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final habit = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (habit != null) {
      habitId = habit['id'];
      _nameController.text = habit['name'] ?? '';
      _descriptionController.text = habit['description'] ?? '';
      selectedColor = Color(int.parse('0xFF${habit['color'].toString().replaceAll('#', '')}'));
      selectedIcon = IconData(int.parse(habit['icon']), fontFamily: 'MaterialIcons');
    }
  }

  Future<void> _saveHabit() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');
      final user = await DatabaseHelper.instance.loginUser(email!, '');

      final habitData = {
        'user_id': user!['id'],
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'color': '#${selectedColor.value.toRadixString(16).substring(2)}',
        'icon': selectedIcon.codePoint.toString(),
        'created_at': DateTime.now().toIso8601String(),
      };

      if (habitId != null) {
        await DatabaseHelper.instance.updateHabit(habitId!, habitData);
      } else {
        await DatabaseHelper.instance.insertHabit(habitData);
      }

      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = habitId != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Upravit návyk' : 'Přidat návyk')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Název návyku'),
                validator: (value) =>
                    value!.isEmpty ? 'Zadej název návyku' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Popis'),
              ),
              const SizedBox(height: 20),
              Text('Vyber barvu:', style: Theme.of(context).textTheme.titleMedium),
              Row(
                children: [
                  _colorDot(Colors.teal),
                  _colorDot(Colors.blue),
                  _colorDot(Colors.green),
                  _colorDot(Colors.orange),
                  _colorDot(Colors.purple),
                ],
              ),
              const SizedBox(height: 20),
              Text('Vyber ikonu:', style: Theme.of(context).textTheme.titleMedium),
              Wrap(
                spacing: 10,
                children: [
                  _iconButton(Icons.local_drink),
                  _iconButton(Icons.fitness_center),
                  _iconButton(Icons.bedtime),
                  _iconButton(Icons.book),
                  _iconButton(Icons.check_circle),
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _saveHabit,
                icon: const Icon(Icons.save),
                label: Text(isEditing ? 'Uložit změny' : 'Uložit návyk'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _colorDot(Color color) {
    return GestureDetector(
      onTap: () => setState(() => selectedColor = color),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selectedColor == color ? Colors.black : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _iconButton(IconData icon) {
    return IconButton(
      icon: Icon(icon,
          color: selectedIcon == icon ? selectedColor : Colors.grey),
      onPressed: () => setState(() => selectedIcon = icon),
    );
  }
}
