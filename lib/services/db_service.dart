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
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE gifts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            giverName TEXT NOT NULL,
            amount REAL NOT NULL,
            paymentMethod TEXT NOT NULL DEFAULT '现金',
            note TEXT,
            sortOrder INTEGER NOT NULL DEFAULT 0,
            createdAt INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute("ALTER TABLE gifts ADD COLUMN paymentMethod TEXT NOT NULL DEFAULT '现金'");
          await db.execute("ALTER TABLE gifts ADD COLUMN note TEXT");
        }
        if (oldVersion < 3) {
          await db.execute("ALTER TABLE gifts ADD COLUMN sortOrder INTEGER NOT NULL DEFAULT 0");
          // 初始化已有数据的sortOrder为createdAt倒序
          await db.execute('UPDATE gifts SET sortOrder = (SELECT MAX(createdAt) FROM gifts) - createdAt');
        }
      },
    );
  }

  static Future<int> insertGift(GiftEntry gift) async {
    final dbb = await db;
    // 新记录插入到最前面（sortOrder最小）
    final minOrder = await dbb.rawQuery('SELECT MIN(sortOrder) as m FROM gifts');
    final nextOrder = ((minOrder.first['m'] as int?) ?? 0) - 1;
    final map = gift.toMap();
    map['sortOrder'] = nextOrder;
    return await dbb.insert('gifts', map);
  }

  static Future<List<GiftEntry>> getAllGifts() async {
    final dbb = await db;
    final maps = await dbb.query('gifts', orderBy: 'sortOrder ASC');
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

  static Future<bool> updateGift(GiftEntry gift) async {
    final dbb = await db;
    final count = await dbb.update(
      'gifts',
      gift.toMap(),
      where: 'id = ?',
      whereArgs: [gift.id],
    );
    return count > 0;
  }

  /// 批量更新排序
  static Future<void> reorderGifts(List<GiftEntry> gifts) async {
    final dbb = await db;
    await dbb.transaction((txn) async {
      for (var i = 0; i < gifts.length; i++) {
        await txn.update(
          'gifts',
          {'sortOrder': i},
          where: 'id = ?',
          whereArgs: [gifts[i].id],
        );
      }
    });
  }
}