import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:ai_doubt_solver/screens/solution_screen.dart';
import 'package:ai_doubt_solver/services/api_service.dart';
import 'package:ai_doubt_solver/services/db_service.dart';
import 'package:ai_doubt_solver/models/doubt.dart';
import 'package:ai_doubt_solver/store/doubt_store.dart';

class FakeApi implements AnswerProvider {
  FakeApi(this.delayMs, this.result);
  final int delayMs;
  Object result; // SolvedAnswer ya ApiError
  int calls = 0;

  @override
  Future<SolvedAnswer> solveQuestion(String imagePath) async {
    calls++;
    await Future.delayed(Duration(milliseconds: delayMs));
    final r = result;
    if (r is ApiError) throw r;
    return r as SolvedAnswer;
  }
}

/// In-memory DbService: sqflite ffi ka isolate/real-IO fake-async widget
/// tests ke saath starve hota hai, isliye auto-save verify karne ke liye
/// in-memory subclass use ki hai (behavior same: insert + getAll).
class MemDb extends DbService {
  MemDb() : super(dbName: 'mem.db');
  final rows = <Map<String, dynamic>>[];
  @override
  Future<int> insert(Doubt d) async {
    rows.add(d.toMap());
    return rows.length;
  }

  @override
  Future<List<Doubt>> getAll() async => rows.map(Doubt.fromMap).toList();
}

void main() {
  late Directory tmp;
  setUp(() async => tmp = await Directory.systemTemp.createTemp('solscr_test'));
  tearDown(() async => tmp.delete(recursive: true));

  Widget wrap(Widget child, DbService db) => MultiProvider(
        providers: [
          Provider<DbService>.value(value: db),
          ChangeNotifierProvider<DoubtStore>(create: (_) => DoubtStore(db)),
        ],
        child: MaterialApp(home: child),
      );

  testWidgets('analyzing state me skeleton dikhta hai, phir solution', (tester) async {
    final db = MemDb();
    final api = FakeApi(500, const SolvedAnswer(title: 'Pythagoras', solution: '## Step 1\n\$a^2+b^2=c^2\$'));
    File('${tmp.path}/img.jpg').writeAsBytesSync([1]);

    await tester.pumpWidget(wrap(SolutionScreen(imagePath: '${tmp.path}/img.jpg', api: api), db));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Ox Alpha soch raha hai…'), findsNothing); // pehla message alag hai
    expect(find.textContaining('padh rahe hain'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Pythagoras'), findsOneWidget);
    expect(find.byType(GptMarkdown), findsOneWidget);
    expect((await db.getAll()).length, 1); // auto-save

    await tester.pumpWidget(const SizedBox()); // dispose, pending timer avoid
  });

  testWidgets('error par friendly message + Retry', (tester) async {
    final db = MemDb();
    final api = FakeApi(10, const NetworkError('Internet nahi mil raha.'));
    File('${tmp.path}/img.jpg').writeAsBytesSync([1]);

    await tester.pumpWidget(wrap(SolutionScreen(imagePath: '${tmp.path}/img.jpg', api: api), db));
    await tester.pumpAndSettle();

    expect(find.text('Internet nahi mil raha.'), findsOneWidget);
    expect(api.calls, 1);

    // Ab fake ko success me badlo aur Retry dabao
    api.result = const SolvedAnswer(title: 'T', solution: 'S');

    // NOTE: FakeApi field final nahi hona chahiye — isliye class me `result` non-final rakho.
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.byType(GptMarkdown), findsOneWidget);
    expect(api.calls, 2);

    await tester.pumpWidget(const SizedBox()); // dispose trigger, pending timer avoid
  });

  testWidgets('result content par fade+slide-in entrance', (tester) async {
    final db = MemDb();
    final api = FakeApi(10, const SolvedAnswer(title: 'T', solution: 'S'));
    File('${tmp.path}/img.jpg').writeAsBytesSync([1]);

    await tester.pumpWidget(wrap(SolutionScreen(imagePath: '${tmp.path}/img.jpg', api: api), db));
    await tester.pump(const Duration(milliseconds: 40)); // API resolve, entrance mid-flight

    final inFlight = find.byWidgetPredicate((w) => w is Opacity && w.opacity < 1);
    expect(inFlight, findsWidgets);
    final midDy = tester.getCenter(find.byType(GptMarkdown)).dy; // slide-up se neeche

    await tester.pumpAndSettle();
    expect(find.byWidgetPredicate((w) => w is Opacity && w.opacity < 1), findsNothing);
    expect(tester.getCenter(find.byType(GptMarkdown)).dy, lessThan(midDy)); // upar slide ho gaya

    await tester.pumpWidget(const SizedBox()); // dispose trigger, pending timer avoid
  });
}
