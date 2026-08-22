import 'dart:io';

import 'package:sqflite/sqflite.dart';

import '../models/doubt.dart';

/// SQLite persistence for solved doubts. Uses the global `databaseFactory`,
/// so tests can swap in `databaseFactoryFfi`.
class DbService {
  DbService({this.dbName = 'doubts.db'});

  final String dbName;
  Database? _cache;

  Future<Database> get database async {
    return _cache ??= await openDatabase(dbName, version: 1,
        onCreate: (db, _) => db.execute('''
          CREATE TABLE doubts(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            image_path TEXT NOT NULL,
            title TEXT NOT NULL,
            solution TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )'''));
  }

  Future<List<Doubt>> getAll() async {
    final rows = await (await database).query('doubts', orderBy: 'created_at DESC');
    return rows.map(Doubt.fromMap).toList();
  }

  Future<int> insert(Doubt d) async => (await database).insert('doubts', d.toMap());

  /// Row + associated image file dono delete karta hai (file missing ho to ignore).
  Future<void> delete(int id) async {
    final db = await database;
    final rows = await db.query('doubts', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isNotEmpty) {
      final f = File(rows.first['image_path'] as String);
      if (await f.exists()) await f.delete();
    }
    await db.delete('doubts', where: 'id = ?', whereArgs: [id]);
  }
}
