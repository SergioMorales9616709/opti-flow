import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static Database? _db;

  static Future<void> initialize() async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    _db = await openDatabase('optiflow.db', version: 1, onCreate: _onCreate);
  }

  /// Opens an in-memory database for widget/unit tests.
  static Future<void> initializeForTesting() async {
    _db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: _onCreate,
    );
  }

  static Database get db {
    assert(_db != null, 'DatabaseHelper.initialize() must be called first.');
    return _db!;
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE user_progress (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        date          TEXT    NOT NULL,
        exercise_type TEXT    NOT NULL,
        max_speed_ms  INTEGER NOT NULL
      )
    ''');
  }
}
