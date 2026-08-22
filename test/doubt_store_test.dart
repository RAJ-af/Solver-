import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ai_doubt_solver/services/db_service.dart';
import 'package:ai_doubt_solver/services/api_service.dart';
import 'package:ai_doubt_solver/store/doubt_store.dart';

void main() {
  setUpAll(initFfi);

  test('addSaved list ke head me daalta hai aur notify karta hai', () async {
    final store = DoubtStore(DbService(
        dbName: 't_store_${DateTime.now().microsecondsSinceEpoch}.db'));
    var notifications = 0;
    store.addListener(() => notifications++);

    await store.addSaved('/tmp/a.jpg', const SolvedAnswer(title: 'Q1', solution: 'S1'));
    await store.addSaved('/tmp/b.jpg', const SolvedAnswer(title: 'Q2', solution: 'S2'));

    expect(store.doubts.first.title, 'Q2');
    expect(store.doubts.length, 2);
    expect(notifications, greaterThanOrEqualTo(2));
    expect(store.loading, isFalse);
  });

  test('remove list se aur db dono se hatata hai', () async {
    final db = DbService(dbName: 't_rm_${DateTime.now().microsecondsSinceEpoch}.db');
    final store = DoubtStore(db);
    await store.addSaved('/tmp/a.jpg', const SolvedAnswer(title: 'Q1', solution: 'S1'));
    final d = store.doubts.single;

    await store.remove(d);

    expect(store.doubts, isEmpty);
    expect(await db.getAll(), isEmpty);
  });
}

void initFfi() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
