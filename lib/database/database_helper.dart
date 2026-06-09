import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/cat_record.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'cat_health.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            catName TEXT NOT NULL,
            weight REAL NOT NULL,
            temperature REAL NOT NULL,
            timestamp INTEGER NOT NULL
          )
        ''');
        await _insertSamples(db);
      },
    );
  }

  Future<void> _insertSamples(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final samples = [
      {'catName': '나비', 'weight': 4.62, 'temperature': 33.8, 'timestamp': now - 1800000},
      {'catName': '나비', 'weight': 4.58, 'temperature': 33.7, 'timestamp': now - 18000000},
      {'catName': '나비', 'weight': 4.55, 'temperature': 33.6, 'timestamp': now - 259200000},
      {'catName': '코코', 'weight': 5.12, 'temperature': 34.1, 'timestamp': now - 28800000},
      {'catName': '코코', 'weight': 5.08, 'temperature': 34.0, 'timestamp': now - 100800000},
      {'catName': '보리', 'weight': 3.94, 'temperature': 33.4, 'timestamp': now - 36000000},
      {'catName': '보리', 'weight': 3.90, 'temperature': 33.5, 'timestamp': now - 187200000},
    ];
    for (final s in samples) {
      await db.insert('records', s);
    }
  }

  Future<int> insertRecord(CatRecord record) async {
    final db = await database;
    return db.insert('records', record.toMap()..remove('id'));
  }

  Future<List<CatRecord>> getAllRecords() async {
    final db = await database;
    final maps = await db.query('records', orderBy: 'timestamp DESC');
    return maps.map(CatRecord.fromMap).toList();
  }

  Future<int> deleteRecord(int id) async {
    final db = await database;
    return db.delete('records', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllAndSeed() async {
    final db = await database;
    await db.delete('records');
    await _insertSamples(db);
  }
}
