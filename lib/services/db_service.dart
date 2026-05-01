import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/gift_entry.dart';

class DbService {
  static Database? _db;

  static Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'gift_book.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE gifts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            giverName TEXT NOT NULL,
            amount REAL NOT NULL,
            paymentMethod TEXT NOT NULL DEFAULT '现金',
            note TEXT,
            createdAt INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute("ALTER TABLE gifts ADD COLUMN paymentMethod TEXT NOT NULL DEFAULT '现金'");
          await db.execute("ALTER TABLE gifts ADD COLUMN note TEXT");
        }
      },
    );
  }

  static Future<int> insertGift(GiftEntry gift) async {
    final dbb = await db;
    return await dbb.insert('gifts', gift.toMap());
  }

  static Future<List<GiftEntry>> getAllGifts() async {
    final dbb = await db;
    final maps = await dbb.query('gifts', orderBy: 'createdAt DESC');
    return maps.map((m) => GiftEntry.fromMap(m)).toList();
  }

  static Future<double> getTotalAmount() async {
    final dbb = await db;
    final result = await dbb.rawQuery('SELECT SUM(amount) as total FROM gifts');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  static Future<int> deleteGift(int id) async {
    final dbb = await db;
    return await dbb.delete('gifts', where: 'id = ?', whereArgs: [id]);
  }
}