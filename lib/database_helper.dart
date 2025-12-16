import 'package:mood_tracker/habit_model.dart';
import 'package:mood_tracker/main.dart';
import 'package:mood_tracker/mood_check.dart';
import 'package:mood_tracker/phq9_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mood_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // Incremented version
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE moods(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        emoji TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE habits(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        isCompleted INTEGER NOT NULL,
        streak INTEGER NOT NULL,
        lastCompleted TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        stressLevel REAL NOT NULL,
        sleepQuality INTEGER NOT NULL,
        energyLevel INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE happy_moments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        path TEXT NOT NULL
      )
    ''');
    
    await db.execute('''
      CREATE TABLE phq9_results(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        score INTEGER NOT NULL
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE phq9_results(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL UNIQUE,
          score INTEGER NOT NULL
        )
      ''');
    }
  }

  // ================= MOODS =================
  Future<void> insertMood(Mood mood) async {
    final db = await instance.database;
    await db.insert('moods', {
      'name': mood.name,
      'emoji': mood.emoji,
      'timestamp': mood.timestamp.toIso8601String(),
    });
  }

  Future<List<Mood>> getMoods() async {
    final db = await instance.database;
    final maps = await db.query('moods');

    return maps.map((map) {
      return Mood(
        name: map['name'] as String,
        emoji: map['emoji'] as String,
        timestamp: DateTime.parse(map['timestamp'] as String),
      );
    }).toList();
  }

  // ================= HABITS =================
  Future<void> insertHabit(Habit habit) async {
    final db = await instance.database;
    await db.insert('habits', {
      'name': habit.name,
      'isCompleted': habit.isCompleted ? 1 : 0,
      'streak': habit.streak,
      'lastCompleted': habit.lastCompleted.toIso8601String(),
    });
  }

  Future<void> updateHabit(Habit habit) async {
    final db = await instance.database;
    await db.update(
      'habits',
      {
        'isCompleted': habit.isCompleted ? 1 : 0,
        'streak': habit.streak,
        'lastCompleted': habit.lastCompleted.toIso8601String(),
      },
      where: 'name = ?',
      whereArgs: [habit.name],
    );
  }

  Future<void> deleteHabit(String name) async {
    final db = await instance.database;
    await db.delete(
      'habits',
      where: 'name = ?',
      whereArgs: [name],
    );
  }

  Future<List<Habit>> getHabits() async {
    final db = await instance.database;
    final maps = await db.query('habits');

    return maps.map((map) {
      return Habit(
        name: map['name'] as String,
        isCompleted: (map['isCompleted'] as int) == 1,
        streak: map['streak'] as int,
        lastCompleted: DateTime.parse(map['lastCompleted'] as String),
      );
    }).toList();
  }

  // ================= DAILY RECORDS =================
  Future<void> upsertDailyRecord(DailyRecord record) async {
    final db = await instance.database;
    final dateKey = DateFormat('yyyy-MM-dd').format(record.date);

    await db.insert(
      'daily_records',
      {
        'date': dateKey,
        'stressLevel': record.stressLevel,
        'sleepQuality': record.sleepQuality,
        'energyLevel': record.energyLevel,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<DailyRecord>> getDailyRecords() async {
    final db = await instance.database;
    final maps = await db.query(
      'daily_records',
      orderBy: 'date ASC',
    );

    return maps.map((map) {
      return DailyRecord(
        date: DateTime.parse(map['date'] as String),
        stressLevel: (map['stressLevel'] as num).toDouble(),
        sleepQuality: map['sleepQuality'] as int,
        energyLevel: map['energyLevel'] as int,
      );
    }).toList();
  }

  // ================= HAPPY MOMENTS =================
  Future<void> insertHappyMoment(String path) async {
    final db = await instance.database;
    await db.insert('happy_moments', {'path': path});
  }

  Future<List<String>> getHappyMoments() async {
    final db = await instance.database;
    final maps = await db.query('happy_moments');

    return maps.map((map) => map['path'] as String).toList();
  }
  
  // ================= PHQ-9 RESULTS =================
  Future<void> insertPHQ9Result(PHQ9Result result) async {
    final db = await instance.database;
    final dateKey = DateFormat('yyyy-MM-dd').format(result.date);
    await db.insert(
      'phq9_results',
      {
        'date': dateKey,
        'score': result.score,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<PHQ9Result>> getPHQ9Results() async {
    final db = await instance.database;
    final maps = await db.query(
      'phq9_results',
      orderBy: 'date ASC',
    );

    return maps.map((map) {
      return PHQ9Result(
        date: DateTime.parse(map['date'] as String),
        score: map['score'] as int,
      );
    }).toList();
  }
}
