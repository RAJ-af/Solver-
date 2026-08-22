import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ai_doubt_solver/models/doubt.dart';
import 'package:ai_doubt_solver/services/db_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('insert -> getAll returns newest first', () async {
    final db = DbService(dbName: 't_order_${DateTime.now().microsecondsSinceEpoch}.db');
    await db.insert(Doubt(id: null, imagePath: '/tmp/a.jpg', title: 'Q1', solution: 'S1',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1000)));
    await db.insert(Doubt(id: null, imagePath: '/tmp/b.jpg', title: 'Q2', solution: 'S2',
        createdAt: DateTime.fromMillisecondsSinceEpoch(2000)));

    final all = await db.getAll();
    expect(all.length, 2);
    expect(all.first.title, 'Q2'); // newest first
    expect(all.first.id, isNotNull);
  });

  test('roundtrip preserves fields', () async {
    final db = DbService(dbName: 't_rt_${DateTime.now().microsecondsSinceEpoch}.db');
    final t = DateTime.fromMillisecondsSinceEpoch(123456);
    await db.insert(Doubt(id: null, imagePath: '/x/y.jpg', title: 'T', solution: 'S', createdAt: t));
    final got = (await db.getAll()).single;
    expect(got.imagePath, '/x/y.jpg');
    expect(got.title, 'T');
    expect(got.solution, 'S');
    expect(got.createdAt, t);
  });

  test('delete removes row', () async {
    final db = DbService(dbName: 't_del_${DateTime.now().microsecondsSinceEpoch}.db');
    final id = await db.insert(Doubt(id: null, imagePath: '/nonexistent.jpg', title: 'T',
        solution: 'S', createdAt: DateTime.now()));
    expect((await db.getAll()).length, 1);
    await db.delete(id);
    expect(await db.getAll(), isEmpty);
  });
}
