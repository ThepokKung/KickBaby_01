import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'kick_data.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE kicks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertKick(String data, String timestamp) async {
    Database db = await database;
    return await db.insert('kicks', {
      'data': data,
      'timestamp': timestamp,
    });
  }

  Future<List<Map<String, dynamic>>> getKicks() async {
    Database db = await database;
    return await db.query('kicks', orderBy: 'id DESC');
  }

  Future<int> deleteAllKicks() async {
    Database db = await database;
    return await db.delete('kicks');
  }
}
