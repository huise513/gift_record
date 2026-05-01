import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class DbService {
  static Database? _db;

  static Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'gift_record.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            occasion TEXT NOT NULL,
            eventDate INTEGER NOT NULL,
            note TEXT,
            createdAt INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE gifts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            eventId INTEGER NOT NULL,
            giverName TEXT NOT NULL,
            amount REAL NOT NULL,
            phone TEXT,
            note TEXT,
            createdAt INTEGER NOT NULL,
            FOREIGN KEY (eventId) REFERENCES events (id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  // 事件操作
  static Future<int> insertEvent(Event event) async {
    final dbb = await db;
    return await dbb.insert('events', event.toMap());
  }

  static Future<List<Event>> getEvents() async {
    final dbb = await db;
    final maps = await dbb.query('events', orderBy: 'eventDate DESC');
    return maps.map((m) => Event.fromMap(m)).toList();
  }

  static Future<Event?> getEvent(int id) async {
    final dbb = await db;
    final maps = await dbb.query('events', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Event.fromMap(maps.first);
  }

  static Future<int> updateEvent(Event event) async {
    final dbb = await db;
    return await dbb.update(
      'events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  static Future<int> deleteEvent(int id) async {
    final dbb = await db;
    await dbb.delete('gifts', where: 'eventId = ?', whereArgs: [id]);
    return await dbb.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  // 礼金操作
  static Future<int> insertGift(Gift gift) async {
    final dbb = await db;
    return await dbb.insert('gifts', gift.toMap());
  }

  static Future<List<Gift>> getGiftsByEvent(int eventId) async {
    final dbb = await db;
    final maps = await dbb.query(
      'gifts',
      where: 'eventId = ?',
      whereArgs: [eventId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) => Gift.fromMap(m)).toList();
  }

  static Future<double> getTotalAmount(int eventId) async {
    final dbb = await db;
    final result = await dbb.rawQuery(
      'SELECT SUM(amount) as total FROM gifts WHERE eventId = ?',
      [eventId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  static Future<int> updateGift(Gift gift) async {
    final dbb = await db;
    return await dbb.update(
      'gifts',
      gift.toMap(),
      where: 'id = ?',
      whereArgs: [gift.id],
    );
  }

  static Future<int> deleteGift(int id) async {
    final dbb = await db;
    return await dbb.delete('gifts', where: 'id = ?', whereArgs: [id]);
  }
}
