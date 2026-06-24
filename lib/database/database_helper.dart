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
    final now = DateTime.now();

    // 나비 1달치 데이터 (30일, 자연스러운 체중 증가)
    final nabiRecords = [
      {'days': 30, 'weight': 4.21},
      {'days': 29, 'weight': 4.23},
      {'days': 28, 'weight': 4.20},
      {'days': 27, 'weight': 4.25},
      {'days': 26, 'weight': 4.22},
      {'days': 25, 'weight': 4.28},
      {'days': 24, 'weight': 4.30},
      {'days': 23, 'weight': 4.27},
      {'days': 22, 'weight': 4.32},
      {'days': 21, 'weight': 4.35},
      {'days': 20, 'weight': 4.33},
      {'days': 19, 'weight': 4.38},
      {'days': 18, 'weight': 4.36},
      {'days': 17, 'weight': 4.40},
      {'days': 16, 'weight': 4.42},
      {'days': 15, 'weight': 4.39},
      {'days': 14, 'weight': 4.44},
      {'days': 13, 'weight': 4.41},
      {'days': 12, 'weight': 4.46},
      {'days': 11, 'weight': 4.48},
      {'days': 10, 'weight': 4.45},
      {'days': 9, 'weight': 4.50},
      {'days': 8, 'weight': 4.52},
      {'days': 7, 'weight': 4.49},
      {'days': 6, 'weight': 4.54},
      {'days': 5, 'weight': 4.56},
      {'days': 4, 'weight': 4.53},
      {'days': 3, 'weight': 4.58},
      {'days': 2, 'weight': 4.60},
      {'days': 1, 'weight': 4.58},
      {'days': 0, 'weight': 4.62},
    ];

    for (final r in nabiRecords) {
      final ts = now.subtract(Duration(days: r['days'] as int, hours: 8));
      await db.insert('records', {
        'catName': '나비',
        'weight': r['weight'],
        'temperature': 33.5,
        'timestamp': ts.millisecondsSinceEpoch,
      });
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

  Future<int> updateRecord(CatRecord record) async {
    final db = await database;
    return db.update(
      'records',
      record.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<void> deleteAllAndSeed() async {
    final db = await database;
    await db.delete('records');
    await _insertSamples(db);
  }
}
