import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/gift_entry.dart';
import '../models/gift_book.dart';
import '../models/search_result.dart';

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
      version: 5,
      onCreate: (db, version) async {
        // 礼金本表
        await db.execute('''
          CREATE TABLE gift_books (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            type TEXT NOT NULL DEFAULT 'wedding',
            created_at INTEGER NOT NULL
          )
        ''');
        // 礼金记录表（关联到礼金本）
        await db.execute('''
          CREATE TABLE gifts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            event_id INTEGER NOT NULL,
            giverName TEXT NOT NULL,
            amount REAL NOT NULL,
            paymentMethod TEXT NOT NULL DEFAULT '现金',
            note TEXT,
            sortOrder INTEGER NOT NULL DEFAULT 0,
            createdAt INTEGER NOT NULL,
            FOREIGN KEY (event_id) REFERENCES gift_books(id) ON DELETE CASCADE
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 4) {
          // oldVersion 3 -> 4: 创建gift_books表，现有gifts数据迁移到默认礼金本
          await db.execute('''
            CREATE TABLE gift_books (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              type TEXT NOT NULL DEFAULT 'wedding',
              created_at INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE gifts_new (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              event_id INTEGER NOT NULL,
              giverName TEXT NOT NULL,
              amount REAL NOT NULL,
              paymentMethod TEXT NOT NULL DEFAULT '现金',
              note TEXT,
              sortOrder INTEGER NOT NULL DEFAULT 0,
              createdAt INTEGER NOT NULL,
              FOREIGN KEY (event_id) REFERENCES gift_books(id) ON DELETE CASCADE
            )
          ''');
          // 插入默认礼金本
          await db.insert('gift_books', {
            'name': '我的礼金本',
            'type': 'wedding',
            'created_at': DateTime.now().millisecondsSinceEpoch,
          });
          // 迁移旧gifts数据到新表
          await db.execute('''
            INSERT INTO gifts_new (id, event_id, giverName, amount, paymentMethod, note, sortOrder, createdAt)
            SELECT id, 1, giverName, amount, paymentMethod, note, sortOrder, createdAt FROM gifts
          ''');
          await db.execute('DROP TABLE gifts');
          await db.execute('ALTER TABLE gifts_new RENAME TO gifts');
        }
        if (oldVersion < 5) {
          // oldVersion 4 -> 5: 已有gift_books的gifts表event_id字段已存在，无需操作
        }
      },
    );
  }

  // ─── 礼金本 CRUD ────────────────────────────────────────────────────────────

  static Future<int> insertGiftBook(GiftBook book) async {
    final dbb = await db;
    return await dbb.insert('gift_books', book.toMap());
  }

  static Future<List<GiftBook>> getAllGiftBooks() async {
    final dbb = await db;
    final maps = await dbb.query('gift_books', orderBy: 'created_at DESC');
    return maps.map((m) => GiftBook.fromMap(m)).toList();
  }

  static Future<GiftBook?> getGiftBook(int id) async {
    final dbb = await db;
    final maps = await dbb.query('gift_books', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return GiftBook.fromMap(maps.first);
  }

  static Future<int> updateGiftBook(GiftBook book) async {
    final dbb = await db;
    return await dbb.update(
      'gift_books',
      book.toMap(),
      where: 'id = ?',
      whereArgs: [book.id],
    );
  }

  static Future<int> deleteGiftBook(int id) async {
    final dbb = await db;
    // 先删除该礼金本下的所有记录
    await dbb.delete('gifts', where: 'event_id = ?', whereArgs: [id]);
    return await dbb.delete('gift_books', where: 'id = ?', whereArgs: [id]);
  }

  // ─── 礼金记录 CRUD ─────────────────────────────────────────────────────────

  static Future<int> insertGift(GiftEntry gift) async {
    final dbb = await db;
    final maxOrder = await dbb.rawQuery(
      'SELECT MAX(sortOrder) as m FROM gifts WHERE event_id = ?',
      [gift.eventId],
    );
    final nextOrder = ((maxOrder.first['m'] as int?) ?? 0) + 1;
    final map = gift.toMap();
    map['event_id'] = gift.eventId;
    map['sortOrder'] = nextOrder;
    return await dbb.insert('gifts', map);
  }

  static Future<List<GiftEntry>> getGiftsForBook(int eventId) async {
    final dbb = await db;
    final maps = await dbb.query(
      'gifts',
      where: 'event_id = ?',
      whereArgs: [eventId],
      orderBy: 'sortOrder ASC',
    );
    return maps.map((m) => GiftEntry.fromMap(m)).toList();
  }

  static Future<double> getTotalAmountForBook(int eventId) async {
    final dbb = await db;
    final result = await dbb.rawQuery(
      'SELECT SUM(amount) as total FROM gifts WHERE event_id = ?',
      [eventId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  static Future<int> getGiftRecordCount(int eventId) async {
    final dbb = await db;
    final result = await dbb.rawQuery(
      'SELECT COUNT(*) as cnt FROM gifts WHERE event_id = ?',
      [eventId],
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  static Future<int> deleteGift(int id) async {
    final dbb = await db;
    return await dbb.delete('gifts', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> restoreGift(GiftEntry gift) async {
    final dbb = await db;
    final map = gift.toMap();
    map['event_id'] = gift.eventId;
    await dbb.insert('gifts', map);
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

  // ─── 兼容旧接口 ────────────────────────────────────────────────────────────

  /// 兼容旧数据：如果没有礼金本，则创建一个默认的
  static Future<void> ensureDefaultBook() async {
    final books = await getAllGiftBooks();
    if (books.isEmpty) {
      await insertGiftBook(GiftBook(
        name: '我的礼金本',
        type: GiftBookType.wedding,
        createdAt: DateTime.now(),
      ));
    }
  }

  /// 旧接口（单礼金本模式）
  static Future<List<GiftEntry>> getAllGifts() async {
    await ensureDefaultBook();
    final books = await getAllGiftBooks();
    return getGiftsForBook(books.first.id!);
  }

  static Future<double> getTotalAmount() async {
    await ensureDefaultBook();
    final books = await getAllGiftBooks();
    return getTotalAmountForBook(books.first.id!);
  }

  // ─── 全局搜索 ─────────────────────────────────────────────────────────────

  static Future<List<SearchResult>> searchGifts(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final dbb = await db;
      final pattern = '%${query.trim()}%';

      final maps = await dbb.rawQuery('''
        SELECT g.id, g.event_id, g.giverName, g.amount, g.paymentMethod,
               g.note, g.sortOrder, g.createdAt,
               gb.name as book_name, gb.type as book_type, gb.created_at as book_created_at
        FROM gifts g
        JOIN gift_books gb ON g.event_id = gb.id
        WHERE g.giverName LIKE ?
        ORDER BY gb.created_at DESC, g.createdAt DESC
      ''', [pattern]);

      return maps.map((m) {
        final gift = GiftEntry(
          id: m['id'] as int?,
          eventId: m['event_id'] as int,
          giverName: m['giverName'] as String,
          amount: (m['amount'] as num).toDouble(),
          paymentMethod: m['paymentMethod'] as String? ?? '现金',
          note: m['note'] as String?,
          sortOrder: m['sortOrder'] as int? ?? 0,
          createdAt: DateTime.fromMillisecondsSinceEpoch(m['createdAt'] as int),
        );
        final book = GiftBook(
          id: m['event_id'] as int,
          name: m['book_name'] as String,
          type: GiftBookType.fromString(m['book_type'] as String),
          createdAt: DateTime.fromMillisecondsSinceEpoch(m['book_created_at'] as int),
        );
        return SearchResult(gift: gift, book: book);
      }).toList();
    } catch (e) {
      debugPrint('searchGifts error: $e');
      return [];
    }
  }
}
