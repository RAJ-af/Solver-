import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ai_doubt_solver/screens/root_shell.dart';
import 'package:ai_doubt_solver/store/doubt_store.dart';
import 'package:ai_doubt_solver/services/db_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('app shell render hota hai, tabs switch hote hain', (tester) async {
    final db = DbService(dbName: 't_smoke_${DateTime.now().microsecondsSinceEpoch}.db');
    final store = DoubtStore(db);
    await tester.runAsync(() => store.refresh());

    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider<DoubtStore>.value(value: store),
    ], child: const MaterialApp(home: RootShell(skipInitialRefresh: true))));
    await tester.pumpAndSettle();

    expect(find.text('Koi bhi doubt?\nPhoto kheencho!', findRichText: true), findsOneWidget);
    expect(find.text('History'), findsOneWidget);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Abhi koi doubt'), findsOneWidget);
  });
}
