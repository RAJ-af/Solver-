import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_doubt_solver/screens/solve_tab.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Camera button image_picker channel invoke karta hai', (tester) async {
    var called = false;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/image_picker'), (call) async {
      called = true;
      return null; // cancel simulate — navigation nahi hoga, bas channel verify
    });

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SolveTab())));
    await tester.tap(find.text('Camera se poochho'));
    await tester.pump();

    expect(called, isTrue);
  });

  testWidgets('Dono action cards dikhte hain', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SolveTab())));
    expect(find.text('Camera se poochho'), findsOneWidget);
    expect(find.text('Gallery se choose karo'), findsOneWidget);
    expect(find.textContaining('Koi bhi doubt'), findsOneWidget);
  });
}
