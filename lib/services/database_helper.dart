import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('habittrack.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 2, onCreate: _createDB, onUpgrade: _onUpgrade);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS calendar_notes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER,
          date TEXT,
          note TEXT,
          FOREIGN KEY (user_id) REFERENCES users (id)
        );
      ''');
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nickname TEXT,
        theme_color TEXT,
        email TEXT UNIQUE,
        password_hash TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE habits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        name TEXT,
        description TEXT,
        color TEXT,
        icon TEXT,
        created_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id)
      );
    ''');

    await db.execute('''
      CREATE TABLE habit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habit_id INTEGER,
        date TEXT,
        completed INTEGER,
        FOREIGN KEY (habit_id) REFERENCES habits (id)
      );
    ''');

    await db.execute('''
      CREATE TABLE calendar_notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        date TEXT,
        note TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id)
      );
    ''');
  }

  // ✅ Registrace uživatele
  Future<int> registerUser(String email, String password, String nickname) async {
    final db = await database;
    final hashed = password.hashCode.toString(); // jednoduchý hash
    return await db.insert('users', {
      'email': email,
      'password_hash': hashed,
      'nickname': nickname,
      'theme_color': '#00BCD4',
    });
  }

  // ✅ Přihlášení uživatele
  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final db = await database;
    final hashed = password.hashCode.toString();
    final result = await db.query(
      'users',
      where: 'email = ? AND password_hash = ?',
      whereArgs: [email, hashed],
    );
    if (result.isNotEmpty) return result.first;
    return null;
  }

  // ✅ Přidání návyku
  Future<int> insertHabit(Map<String, dynamic> habit) async {
    final db = await database;
    return await db.insert('habits', habit);
  }

  // ✅ Získání návyků pro uživatele
  Future<List<Map<String, dynamic>>> getHabits(int userId) async {
    final db = await database;
    return await db.query(
      'habits',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }

  // ✅ Úprava návyku
  Future<int> updateHabit(int id, Map<String, dynamic> habit) async {
    final db = await database;
    return await db.update(
      'habits',
      habit,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ✅ Smazání návyku
  Future<int> deleteHabit(int id) async {
    final db = await database;
    return await db.delete(
      'habits',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ✅ Označení návyku jako splněný
  Future<int> logHabitCompletion(int habitId, DateTime date) async {
    final db = await database;
    final formattedDate = date.toIso8601String().split('T').first; // yyyy-MM-dd
    return await db.insert('habit_logs', {
      'habit_id': habitId,
      'date': formattedDate,
      'completed': 1,
    });
  }

  // ✅ Získání logů pro návyk (historie plnění)
  Future<List<Map<String, dynamic>>> getHabitLogs(int habitId) async {
    final db = await database;
    return await db.query(
      'habit_logs',
      where: 'habit_id = ?',
      whereArgs: [habitId],
      orderBy: 'date DESC', // seřazeno od nejnovějšího
    );
  }

  // ✅ Získání všech logů pro uživatele v daném dni
  Future<List<Map<String, dynamic>>> getLogsForDate(int userId, String date) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT hl.*, h.name, h.color, h.icon 
      FROM habit_logs hl
      JOIN habits h ON hl.habit_id = h.id
      WHERE h.user_id = ? AND hl.date = ?
    ''', [userId, date]);
  }

  // ✅ Kontrola, zda je návyk splněn pro daný den
  Future<bool> isHabitCompletedForDate(int habitId, String date) async {
    final db = await database;
    final result = await db.query(
      'habit_logs',
      where: 'habit_id = ? AND date = ?',
      whereArgs: [habitId, date],
    );
    return result.isNotEmpty;
  }

  // ✅ Získání všech dat, kdy byl návyk splněn
  Future<List<String>> getCompletedDatesForHabit(int habitId) async {
    final db = await database;
    final result = await db.query(
      'habit_logs',
      columns: ['date'],
      where: 'habit_id = ?',
      whereArgs: [habitId],
    );
    return result.map((row) => row['date'] as String).toList();
  }

  // ✅ Získání statistik pro uživatele
  Future<Map<String, dynamic>> getUserStats(int userId) async {
    final db = await database;
    
    // Celkový počet návyků
    final habitsCount = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM habits WHERE user_id = ?', [userId]
    )) ?? 0;

    // Celkový počet splnění
    final completionsCount = Sqflite.firstIntValue(await db.rawQuery('''
      SELECT COUNT(*) FROM habit_logs hl
      JOIN habits h ON hl.habit_id = h.id
      WHERE h.user_id = ?
    ''', [userId])) ?? 0;

    // Splnění za posledních 7 dní
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final weekAgoStr = weekAgo.toIso8601String().split('T').first;
    final weekCompletions = Sqflite.firstIntValue(await db.rawQuery('''
      SELECT COUNT(*) FROM habit_logs hl
      JOIN habits h ON hl.habit_id = h.id
      WHERE h.user_id = ? AND hl.date >= ?
    ''', [userId, weekAgoStr])) ?? 0;

    // Splnění za posledních 30 dní
    final monthAgo = DateTime.now().subtract(const Duration(days: 30));
    final monthAgoStr = monthAgo.toIso8601String().split('T').first;
    final monthCompletions = Sqflite.firstIntValue(await db.rawQuery('''
      SELECT COUNT(*) FROM habit_logs hl
      JOIN habits h ON hl.habit_id = h.id
      WHERE h.user_id = ? AND hl.date >= ?
    ''', [userId, monthAgoStr])) ?? 0;

    return {
      'habitsCount': habitsCount,
      'totalCompletions': completionsCount,
      'weekCompletions': weekCompletions,
      'monthCompletions': monthCompletions,
    };
  }

  // ✅ Získání uživatele podle emailu
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (result.isNotEmpty) return result.first;
    return null;
  }

  // ✅ Aktualizace uživatelského nastavení
  Future<int> updateUserSettings(int userId, Map<String, dynamic> settings) async {
    final db = await database;
    return await db.update(
      'users',
      settings,
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // ✅ Odstranění splnění návyku (pro toggle)
  Future<int> removeHabitCompletion(int habitId, String date) async {
    final db = await database;
    return await db.delete(
      'habit_logs',
      where: 'habit_id = ? AND date = ?',
      whereArgs: [habitId, date],
    );
  }

  // ✅ Vytvoření výchozích návyků pro nového uživatele
  Future<void> createDefaultHabits(int userId) async {
    final defaultHabits = [
      {
        'user_id': userId,
        'name': '30 minut čtení',
        'description': 'Přečti si knihu nebo článek',
        'color': '#FF6B6B',
        'icon': Icons.menu_book.codePoint.toString(),
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'user_id': userId,
        'name': 'Chůze 10 km',
        'description': 'Projdi se nebo zaběhej',
        'color': '#4ECDC4',
        'icon': Icons.directions_walk.codePoint.toString(),
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'user_id': userId,
        'name': 'Vyčištění zubů',
        'description': 'Ráno a večer',
        'color': '#95E1D3',
        'icon': Icons.brush.codePoint.toString(),
        'created_at': DateTime.now().toIso8601String(),
      },
    ];

    for (var habit in defaultHabits) {
      await insertHabit(habit);
    }
  }

  // ✅ Uložení poznámky do kalendáře
  Future<int> saveCalendarNote(int userId, String date, String note) async {
    final db = await database;
    // Zkontroluj, zda už existuje poznámka pro tento den
    final existing = await db.query(
      'calendar_notes',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, date],
    );
    
    if (existing.isNotEmpty) {
      // Aktualizuj existující poznámku
      return await db.update(
        'calendar_notes',
        {'note': note},
        where: 'user_id = ? AND date = ?',
        whereArgs: [userId, date],
      );
    } else {
      // Vytvoř novou poznámku
      return await db.insert('calendar_notes', {
        'user_id': userId,
        'date': date,
        'note': note,
      });
    }
  }

  // ✅ Získání poznámky pro daný den
  Future<String?> getCalendarNote(int userId, String date) async {
    final db = await database;
    final result = await db.query(
      'calendar_notes',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, date],
    );
    if (result.isNotEmpty) {
      return result.first['note'] as String?;
    }
    return null;
  }

  // ✅ Smazání poznámky
  Future<int> deleteCalendarNote(int userId, String date) async {
    final db = await database;
    return await db.delete(
      'calendar_notes',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, date],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}