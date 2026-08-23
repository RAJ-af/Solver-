import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:provider/provider.dart';

import 'package:ai_doubt_solver/models/doubt.dart';
import 'package:ai_doubt_solver/screens/history_tab.dart';
import 'package:ai_doubt_solver/services/api_service.dart';
import 'package:ai_doubt_solver/services/db_service.dart';
import 'package:ai_doubt_solver/store/doubt_store.dart';
import 'package:ai_doubt_solver/utils/time_ago.dart';
import 'package:ai_doubt_solver/widgets/shimmer_box.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('timeAgo', () {
    test('boundaries', () {
      final now = DateTime.now();
      expect(timeAgo(now.subtract(const Duration(seconds: 30))), 'abhi');
      expect(timeAgo(now.subtract(const Duration(minutes: 5))), '5 min pehle');
      expect(timeAgo(now.subtract(const Duration(hours: 3))), '3 ghante pehle');
      expect(timeAgo(now.subtract(const Duration(days: 2))), '2 din pehle');
    });
  });

  testWidgets('khali history par empty state + CTA', (tester) async {
    final db = DbService(dbName: 't_e_${DateTime.now().microsecondsSinceEpoch}.db');
    final store = DoubtStore(db);
    var goToSolve = false;

    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider<DoubtStore>.value(value: store),
    ], child: MaterialApp(home: Scaffold(body: HistoryTab(onGoToSolve: () => goToSolve = true)))));
    await tester.pumpAndSettle();

    expect(find.textContaining('Abhi koi doubt'), findsOneWidget);
    await tester.tap(find.text('Solve karo'));
    expect(goToSolve, isTrue);
  });

  testWidgets('pehli load par shimmer dikhta hai, empty-state flash nahi hota',
      (tester) async {
    final db = DbService(dbName: 't_l_${DateTime.now().microsecondsSinceEpoch}.db');
    final store = DoubtStore(db);
    // Sync prefix loading=true set karta hai; DB I/O fake-async zone me
    // progress nahi karta jab tak runAsync na ho — perfect flash window.
    final pending = store.refresh();

    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider<DoubtStore>.value(value: store),
    ], child: MaterialApp(home: Scaffold(body: HistoryTab(onGoToSolve: () {})))));

    expect(store.loading, isTrue);
    expect(find.byType(ShimmerBox), findsWidgets);
    expect(find.textContaining('Abhi koi doubt'), findsNothing);

    // Real I/O ko complete hone do, phir khali history ka empty state aana chahiye.
    await tester.runAsync(() => pending);
    await tester.pumpAndSettle();
    expect(store.loading, isFalse);
    expect(find.textContaining('Abhi koi doubt'), findsOneWidget);
  });

  testWidgets('items hone par cards dikhte hain, tap par detail khulta hai', (tester) async {
    final db = DbService(dbName: 't_f_${DateTime.now().microsecondsSinceEpoch}.db');
    final store = DoubtStore(db);
    // Widget test fake-async zone me chalta hai — real DB I/O ke liye runAsync zaroori hai.
    await tester.runAsync(
        () => store.addSaved('/nonexistent.jpg', const SolvedAnswer(title: 'Pythagoras Q', solution: 'Sol')));
    // Purana doubt bhi seed karo taaki relative time ('pehle') render ho.
    await tester.runAsync(() => db.insert(Doubt(
        id: null,
        imagePath: '/nonexistent_old.jpg',
        title: 'Old Q',
        solution: 'Old sol',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)))));
    await tester.runAsync(store.refresh);

    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider<DoubtStore>.value(value: store),
    ], child: MaterialApp(home: Scaffold(body: HistoryTab(onGoToSolve: () {})))));
    await tester.pumpAndSettle();

    expect(find.text('Pythagoras Q'), findsOneWidget);
    expect(find.textContaining('pehle'), findsWidgets);
    await tester.tap(find.text('Pythagoras Q'));
    await tester.pumpAndSettle();
    expect(find.byType(GptMarkdown), findsOneWidget);
  });
}
