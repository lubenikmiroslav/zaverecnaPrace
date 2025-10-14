import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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

    return await openDatabase(path, version: 1, onCreate: _createDB);
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

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
