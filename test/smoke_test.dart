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

  testWidgets('tab switch par subtle fade + tab state preserve', (tester) async {
    final db = DbService(dbName: 't_fade_${DateTime.now().microsecondsSinceEpoch}.db');
    final store = DoubtStore(db);
    await tester.runAsync(() => store.refresh());

    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider<DoubtStore>.value(value: store),
    ], child: const MaterialApp(home: RootShell(skipInitialRefresh: true))));
    await tester.pumpAndSettle();

    final fade = find.byWidgetPredicate(
        (w) => w is FadeTransition && w.child is IndexedStack);
    expect(fade, findsOneWidget);
    expect(tester.widget<FadeTransition>(fade).opacity.value, 1.0);

    await tester.tap(find.text('History'));
    await tester.pump(const Duration(milliseconds: 60)); // fade mid-flight
    expect(tester.widget<FadeTransition>(fade).opacity.value, lessThan(1.0));

    await tester.pumpAndSettle();
    expect(tester.widget<FadeTransition>(fade).opacity.value, closeTo(1.0, 0.001));
    // IndexedStack children unmount nahi hote — SolveTab hero ab bhi tree me
    // (hidden child 'offstage' count hota hai isliye skipOffstage: false).
    expect(find.text('Koi bhi doubt?\nPhoto kheencho!',
        findRichText: true, skipOffstage: false), findsOneWidget);
    expect(find.textContaining('Abhi koi doubt'), findsOneWidget);
  });
}
