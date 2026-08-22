# AI Doubt Solver Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Flutter app jo question-photo ko OpenAI-compatible vision API (default: OpenRouter `stealth/ox-alpha`) se Hinglish step-by-step solution me convert karta hai, locally save karta hai, history me rakhta hai.

**Architecture:** Lightweight layered — services (`Api`, `Db`, `Image`) + ek `ChangeNotifier` store, 2-tab NavigationBar shell (Solve | History), custom slide-fade transitions. Sab API config `.env` se.

**Tech Stack:** Flutter 3.47 stable (Android), sqflite, image_picker, flutter_dotenv, google_fonts (Sora/Inter), gpt_markdown, http, image, provider, path_provider.

**Spec:** `docs/superpowers/specs/2026-08-22-ai-doubt-solver-design.md` (executors dono padhein)

## Global Constraints

- Working dir: `/root/ai_doubt_solver`. Flutter binary: `/opt/flutter/bin/flutter` (PATH me nahi hai).
- Colors (verbatim): primary/accent teal `#00BCC8`, highlight lime `#D0FF00`, dark bg `#0A0E13`, dark surface `#131920`, dark onSurface `#E8EFF0`, light bg `#F6FAFB`, light ink `#0E1A1C`, muted light `#5A6B6E`, muted dark `#8FA3A6`, error light `#E5484D`, error dark `#FF6369`.
- Typography: headings **Sora**, body **Inter** (google_fonts). Base body 15, headings 20–28.
- Env keys (sirf ye naam, kahin hardcode nahi): `API_BASE_URL`, `API_KEY`, `API_MODEL`. Default example values: `https://openrouter.ai/api/v1/chat/completions`, `stealth/ox-alpha`.
- Image pipeline: max width 1024px (upscale kabhi nahi), JPEG quality 80, single processed file = API payload + display + storage. Original copy nahi.
- Prompt pehli line `TITLE: <max 60 chars>` maangta hai; parser fallback: pehli non-empty line truncated 60.
- API timeout 90s. Wire format OpenAI-compatible chat completions; response parse `choices[0].message.content`.
- Android permission: sirf `CAMERA` (+ `<queries>` declarations). Storage permission nahi.
- App label "AI Doubt Solver", org `io.github.rajaf` → applicationId `io.github.rajaf.ai_doubt_solver`.
- UI copy Hinglish me (exact strings tasks me diye hain — wahi use karo).
- Commits: conventional commits (feat/test/ci/chore).
- Har logic task TDD: pehle failing test, phir implementation.

---

### Task 1: Project scaffold + env plumbing

**Files:**
- Create: project skeleton via `flutter create`, `.env`, `.env.example`
- Modify: `pubspec.yaml`, `android/app/src/main/AndroidManifest.xml`, `.gitignore`
- Delete: `test/widget_test.dart` (placeholder; Task 10 me real smoke test aayega)

**Interfaces:**
- Produces: compiles-clean Flutter Android project jisme sab dependencies registered hain aur `.env` asset bundle hota hai.

- [ ] **Step 1: Scaffold**

```bash
cd /root/ai_doubt_solver
/opt/flutter/bin/flutter create --org io.github.rajaf --project-name ai_doubt_solver --platforms android .
```

- [ ] **Step 2: Dependencies add karo**

```bash
/opt/flutter/bin/flutter pub add flutter_dotenv image_picker sqflite path_provider google_fonts gpt_markdown http image provider
/opt/flutter/bin/flutter pub add --dev sqflite_common_ffi
```

- [ ] **Step 3: `.env.example` banao (committed) aur `.env` (gitignored)**

`.env.example`:
```env
API_BASE_URL=https://openrouter.ai/api/v1/chat/completions
API_KEY=yahan_apna_key_daalo
API_MODEL=stealth/ox-alpha
```

`.env` — same content, placeholder key ke saath (local test/build ke liye zaroori kyunki pubspec asset declare karega).

- [ ] **Step 4: `.gitignore` me add karo**

```
.env
```

(flutter create ka default .gitignore already `build/`, `.dart_tool/` cover karta hai.)

- [ ] **Step 5: `pubspec.yaml` me .env asset register karo**

`flutter:` section me:

```yaml
flutter:
  uses-material-design: true
  assets:
    - .env
```

- [ ] **Step 6: AndroidManifest.xml update**

`android/app/src/main/AndroidManifest.xml` — `<manifest>` ke andar, `<application>` se pehle:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera.any" android:required="false" />
<queries>
    <intent>
        <action android:name="android.media.action.IMAGE_CAPTURE" />
    </intent>
    <intent>
        <action android:name="android.intent.action.GET_CONTENT" />
        <data android:mimeType="image/*" />
    </intent>
</queries>
```

`<application ...>` tag me `android:label="AI Doubt Solver"` set karo.

- [ ] **Step 7: Placeholder main.dart + purana counter test hatao**

`lib/main.dart` overwrite (Task 10 me replace hoga):

```dart
import 'package:flutter/material.dart';

void main() => runApp(const _Placeholder());

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) => const MaterialApp(home: Scaffold());
}
```

Delete: `rm test/widget_test.dart`

- [ ] **Step 8: Verify**

Run: `/opt/flutter/bin/flutter analyze && /opt/flutter/bin/flutter test`
Expected: `No issues found!`, `All tests passed!` (0 tests)

- [ ] **Step 9: Commit**

```bash
git add -A && git commit -m "chore: scaffold Flutter project with deps, env plumbing, Android permissions"
```

---

### Task 2: Theme module

**Files:**
- Create: `lib/theme/app_theme.dart`, `test/theme_test.dart`

**Interfaces:**
- Produces: `AppTheme.light()` → `ThemeData`, `AppTheme.dark()` → `ThemeData`, `AppTheme.teal/lime` constants (baaki UI tasks inhi ka use karenge).

- [ ] **Step 1: Failing test likho** — `test/theme_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_doubt_solver/theme/app_theme.dart';

void main() {
  test('light theme uses off-white bg and teal primary', () {
    final t = AppTheme.light();
    expect(t.colorScheme.primary, const Color(0xFF00BCC8));
    expect(t.scaffoldBackgroundColor, const Color(0xFFF6FAFB));
    expect(t.brightness, Brightness.light);
  });

  test('dark theme uses deep blue-black bg (not inverted white)', () {
    final t = AppTheme.dark();
    expect(t.colorScheme.primary, const Color(0xFF00BCC8));
    expect(t.scaffoldBackgroundColor, const Color(0xFF0A0E13));
    expect(t.cardTheme.color, const Color(0xFF131920));
  });

  test('both themes use Sora for display text', () {
    expect(AppTheme.light().textTheme.headlineSmall?.fontFamily, 'Sora');
    expect(AppTheme.dark().textTheme.bodyMedium?.fontFamily, 'Inter');
  });
}
```

- [ ] **Step 2: Run — fail confirm**

Run: `/opt/flutter/bin/flutter test test/theme_test.dart`
Expected: FAIL (`Error: Couldn't resolve the package 'ai_doubt_solver/theme/app_theme.dart'` type)

- [ ] **Step 3: Implement** — `lib/theme/app_theme.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App-wide palette + light/dark ThemeData.
class AppTheme {
  AppTheme._();

  static const teal = Color(0xFF00BCC8);
  static const lime = Color(0xFFD0FF00);

  static const _bgLight = Color(0xFFF6FAFB);
  static const _inkLight = Color(0xFF0E1A1C);
  static const _mutedLight = Color(0xFF5A6B6E);
  static const _bgDark = Color(0xFF0A0E13);
  static const _surfaceDark = Color(0xFF131920);
  static const _onDark = Color(0xFFE8EFF0);
  static const _mutedDark = Color(0xFF8FA3A6);
  static const _errorLight = Color(0xFFE5484D);
  static const _errorDark = Color(0xFFFF6369);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final isDark = b == Brightness.dark;
    const tealSwatch = MaterialColor(0xFF00BCC8, {});
    final cs = ColorScheme.fromSeed(
      seedColor: tealSwatch,
      brightness: b,
      primary: teal,
      secondary: lime,
      surface: isDark ? _surfaceDark : Colors.white,
      onSurface: isDark ? _onDark : _inkLight,
      error: isDark ? _errorDark : _errorLight,
      onError: Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: isDark ? _bgDark : _bgLight,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? _bgDark : _bgLight,
        foregroundColor: isDark ? _onDark : _inkLight,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.sora(
          fontSize: 20, fontWeight: FontWeight.w600,
          color: isDark ? _onDark : _inkLight,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? _surfaceDark : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? _surfaceDark : Colors.white,
        indicatorColor: teal.withValues(alpha: 0.18),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
            color: isDark ? _onDark : _inkLight),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: teal,
          foregroundColor: Colors.black,
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          minimumSize: const Size(0, 52),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? _onDark : _inkLight,
          side: BorderSide(color: isDark ? _mutedDark.withValues(alpha: .4) : _mutedLight.withValues(alpha: .35)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          minimumSize: const Size(0, 52),
        ),
      ),
      inputDialogRedirect: null, // placeholder-free guard: see note below
      dividerColor: isDark ? Colors.white.withValues(alpha: .06) : Colors.black.withValues(alpha: .06),
    );
  }
}
```

**Note:** `inputDialogRedirect: null` line mat likhna — ThemeData us param ko expose nahi karta. Wo line hatao; baaki as-is.

TextTheme add karo `_build` ke ThemeData me:

```dart
textTheme: (b == Brightness.dark
        ? Typography.material2021(colorScheme: cs).black
        : Typography.material2021(colorScheme: cs).black)
    .apply(bodyColor: isDark ? _onDark : _inkLight, displayColor: isDark ? _onDark : _inkLight)
    .merge(TextTheme(
      headlineLarge: GoogleFonts.sora(fontSize: 28, fontWeight: FontWeight.w700),
      headlineSmall: GoogleFonts.sora(fontSize: 22, fontWeight: FontWeight.w700),
      titleLarge: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w600),
      bodyMedium: GoogleFonts.inter(fontSize: 15),
      bodySmall: GoogleFonts.inter(fontSize: 13, color: isDark ? _mutedDark : _mutedLight),
    )),
```

- [ ] **Step 4: Run — pass**

Run: `/opt/flutter/bin/flutter test test/theme_test.dart`
Expected: PASS (3 tests)

- [ ] **Step 5: Analyze + commit**

```bash
/opt/flutter/bin/flutter analyze
git add -A && git commit -m "feat: app theme — teal/lime palette, Sora+Inter, polished dark mode"
```

---

### Task 3: Doubt model + DB service (TDD)

**Files:**
- Create: `lib/models/doubt.dart`, `lib/services/db_service.dart`, `test/db_service_test.dart`

**Interfaces:**
- Produces:
  - `Doubt { int? id; String imagePath; String title; String solution; DateTime createdAt; }` + `toMap()`/`Doubt.fromMap(Map)`
  - `DbService({String dbName = 'doubts.db'})` with `Future<List<Doubt>> getAll()` (DESC order), `Future<int> insert(Doubt)`, `Future<void> delete(int id)` (file bhi delete)

- [ ] **Step 1: Failing test** — `test/db_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_common_ffi.dart';
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
```

- [ ] **Step 2: Fail confirm** — Run: `/opt/flutter/bin/flutter test test/db_service_test.dart` → FAIL (missing imports)

- [ ] **Step 3: Implement** `lib/models/doubt.dart`:

```dart
class Doubt {
  const Doubt({
    this.id,
    required this.imagePath,
    required this.title,
    required this.solution,
    required this.createdAt,
  });

  final int? id;
  final String imagePath;
  final String title;
  final String solution;
  final DateTime createdAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'image_path': imagePath,
        'title': title,
        'solution': solution,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory Doubt.fromMap(Map<String, Object?> map) => Doubt(
        id: map['id'] as int?,
        imagePath: map['image_path'] as String,
        title: map['title'] as String,
        solution: map['solution'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );
}
```

`lib/services/db_service.dart`:

```dart
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
```

- [ ] **Step 4: Pass** — Run: `/opt/flutter/bin/flutter test test/db_service_test.dart` → PASS (3)

- [ ] **Step 5: Commit** — `git add -A && git commit -m "feat: Doubt model + sqflite DbService"`

---

### Task 4: Image pipeline service (TDD)

**Files:**
- Create: `lib/services/image_service.dart`, `test/image_service_test.dart`

**Interfaces:**
- Consumes: kuch nahi (standalone)
- Produces: `ImageService` → `Future<String> process(String sourcePath, String outputDir, {int maxWidth = 1024, int quality = 80})` — processed JPEG ka absolute path return karta hai.

- [ ] **Step 1: Failing test** — `test/image_service_test.dart`:

```dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:ai_doubt_solver/services/image_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('imgsvc_test');
  });

  tearDown(() async => tmp.delete(recursive: true));

  /// dart:ui se chhoti PNG generate karta hai (test fixture).
  Future<String> makePng(int w, int h) async {
    final rec = ui.PictureRecorder();
    final canvas = ui.Canvas(rec);
    canvas.drawPaint(ui.Paint()..color = const ui.Color(0xFF00BCC8));
    rec.endRecording().toImageSync(w, h);
    final bytes = await rec.endRecording().toImage(w, h);
    final data = await bytes.toByteData(format: ui.ImageByteFormat.png);
    final f = File('${tmp.path}/src.png')..writeAsBytesSync(data!.buffer.asUint8List());
    return f.path;
  }

  test('big image downscale hoti hai 1024 tak, JPEG output', () async {
    final src = await makePng(2048, 1024);
    final out = await ImageService().process(src, tmp.path);
    final outFile = File(out);
    expect(await outFile.exists(), isTrue);
    expect(outFile.lengthSync(), lessThan(File(src).lengthSync() * 2));
    // JPEG magic bytes
    expect(outFile.readAsBytesSync().sublist(0, 2), [0xFF, 0xD8]);

    final desc = await ui.ImageDescriptor.encoded(
        await ui.ImmutableBuffer.fromFilePath(out));
    expect(desc.width, 1024);
    expect(desc.height, 512);
  });

  test('chhoti image upscale NAHI hoti', () async {
    final src = await makePng(320, 240);
    final out = await ImageService().process(src, tmp.path);
    final desc = await ui.ImageDescriptor.encoded(
        await ui.ImmutableBuffer.fromFilePath(out));
    expect(desc.width, 320);
    expect(desc.height, 240);
  });
}
```

(Note: `makePng` me pehla `toImageSync` line redundant hai — sirf `rec.endRecording().toImage(w, h)` wala path rakho.)

- [ ] **Step 2: Fail confirm** — Run: `/opt/flutter/bin/flutter test test/image_service_test.dart` → FAIL (missing file)

- [ ] **Step 3: Implement** — `lib/services/image_service.dart`:

```dart
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;

/// Photo ko resize (width ≤ maxWidth) + JPEG (quality) compress karke
/// ek hi persistent file banata hai — wahi API payload, thumbnail aur
/// detail view sab ke liye use hogi.
class ImageService {
  Future<String> process(
    String sourcePath,
    String outputDir, {
    int maxWidth = 1024,
    int quality = 80,
  }) async {
    final bytes = await File(sourcePath).readAsBytes();
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final desc = await ui.ImageDescriptor.encoded(buffer);

    // Upscale kabhi nahi — chhoti image as-is dimensions rakhti hai.
    final tw = desc.width > maxWidth ? maxWidth : desc.width;
    final th = desc.width > maxWidth ? (desc.height * maxWidth / desc.width).round() : desc.height;

    final codec = await desc.instantiateCodec(targetWidth: tw, targetHeight: th);
    final frame = await codec!.getNextFrame();
    final data = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
    frame.image.dispose();
    codec.dispose();

    // rawRgba bytes → image package Image → JPEG encode (quality control).
    final px = data!.buffer.asUint32List();
    final image = img.Image(width: tw, height: th);
    for (var y = 0; y < th; y++) {
      for (var x = 0; x < tw; x++) {
        final c = px[y * tw + x];
        image.setPixelRgba(x, y, c & 0xFF, (c >> 8) & 0xFF, (c >> 16) & 0xFF, (c >> 24) & 0xFF);
      }
    }
    final jpg = img.encodeJpg(image, quality: quality);

    final name =
        '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(1 << 31)}.jpg';
    final out = File('$outputDir/$name');
    await out.writeAsBytes(jpg);
    return out.path;
  }
}
```

- [ ] **Step 4: Pass** — Run: `/opt/flutter/bin/flutter test test/image_service_test.dart` → PASS (2)

- [ ] **Step 5: Commit** — `git add -A && git commit -m "feat: image pipeline — native decode, 1024px cap, JPEG q80, single persisted file"`

---

### Task 5: API service (TDD, provider-agnostic)

**Files:**
- Create: `lib/services/api_service.dart`, `test/api_service_test.dart`

**Interfaces:**
- Consumes: dotenv (`API_BASE_URL`, `API_KEY`, `API_MODEL`), processed image file path
- Produces:
  - `SolvedAnswer { String title; String solution; }`
  - `abstract class AnswerProvider { Future<SolvedAnswer> solveQuestion(String imagePath); }`
  - `class ApiService implements AnswerProvider` — `ApiService({http.Client? client, Map<String, String>? envOverride})`
  - Errors: `MissingConfigError`, `NetworkError`, `HttpApiError{statusCode,message}`, `BadResponseError` — sab `ApiError extends Error`-family, `.message` Hinglish string

- [ ] **Step 1: Failing test** — `test/api_service_test.dart`:

```dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_doubt_solver/services/api_service.dart';

const env = {
  'API_BASE_URL': 'https://example.test/v1/chat/completions',
  'API_KEY': 'sk-test',
  'API_MODEL': 'test-model',
};

http.Response okBody(String content) => http.Response(
    jsonEncode({'choices': [
      {'message': {'role': 'assistant', 'content': content}}
    ]}), 200);

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('api_test');
    File('${tmp.path}/p.jpg').writeAsBytesSync(Uint8List.fromList([1, 2, 3]));
    dotenv.testLoad(fileInput: '''
API_BASE_URL=https://example.test/v1/chat/completions
API_KEY=sk-dotenv
API_MODEL=m-dotenv
''');
  });

  tearDown(() async => tmp.delete(recursive: true));

  test('TITLE: prefix parse hota hai', () async {
    final svc = ApiService(envOverride: env, client: MockClient(
        (_) async => okBody('TITLE: Integral of x^2\n\n## Step 1\n$\\int x^2 dx$\n')));
    final ans = await svc.solveQuestion('${tmp.path}/p.jpg');
    expect(ans.title, 'Integral of x^2');
    expect(ans.solution, '## Step 1\n\$\\int x^2 dx\$');
  });

  test('prefix na ho to fallback title', () async {
    final svc = ApiService(envOverride: env, client: MockClient(
        (_) async => okBody('Yeh raha solution.\nAur bhi steps.')));
    final ans = await svc.solveQuestion('${tmp.path}/p.jpg');
    expect(ans.title, 'Yeh raha solution.');
    expect(ans.solution, contains('Aur bhi steps.'));
  });

  test('request OpenAI-compatible shape me jaata hai', () async {
    Uri? capturedUri;
    Map<String, dynamic>? capturedBody;
    final svc = ApiService(envOverride: env, client: MockClient((req) async {
      capturedUri = req.url;
      capturedBody = jsonDecode(req.body) as Map<String, dynamic>;
      return okBody('TITLE: T\nSol');
    }));

    await svc.solveQuestion('${tmp.path}/p.jpg');

    expect(capturedUri.toString(), 'https://example.test/v1/chat/completions');
    expect(capturedBody!['model'], 'test-model');
    final msg = (capturedBody!['messages'] as List).single as Map<String, dynamic>;
    expect(msg['role'], 'user');
    final parts = msg['content'] as List;
    expect(parts[0]['type'], 'text');
    expect(parts[0]['text'], contains('TITLE:'));
    expect(parts[1]['type'], 'image_url');
    expect((parts[1]['image_url'] as Map)['url'], startsWith('data:image/jpeg;base64,'));
  });

  test('HTTP 401 → HttpApiError with friendly message', () async {
    final svc = ApiService(envOverride: env, client: MockClient(
        (_) async => http.Response('{"error":"bad key"}', 401)));
    await expectLater(svc.solveQuestion('${tmp.path}/p.jpg'),
        throwsA(isA<HttpApiError>().having((e) => e.message, 'msg', contains('key'))));
  });

  test('SocketException → NetworkError', () async {
    final svc = ApiService(envOverride: env, client: MockClient(
        (_) async => throw const SocketException('no net')));
    await expectLater(svc.solveQuestion('${tmp.path}/p.jpg'),
        throwsA(isA<NetworkError>()));
  });

  test('config missing → MissingConfigError', () async {
    final svc = ApiService(client: MockClient((_) async => okBody('x')),
        envOverride: {'API_BASE_URL': '', 'API_KEY': '', 'API_MODEL': ''});
    await expectLater(svc.solveQuestion('${tmp.path}/p.jpg'),
        throwsA(isA<MissingConfigError>()));
  });

  test('malformed JSON → BadResponseError', () async {
    final svc = ApiService(envOverride: env, client: MockClient(
        (_) async => http.Response(jsonEncode({'weird': true}), 200)));
    await expectLater(svc.solveQuestion('${tmp.path}/p.jpg'),
        throwsA(isA<BadResponseError>()));
  });
}
```

- [ ] **Step 2: Fail confirm** — Run: `/opt/flutter/bin/flutter test test/api_service_test.dart` → FAIL

- [ ] **Step 3: Implement** — `lib/services/api_service.dart`:

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'dart:typed_data';

/// Ek solved question ka parsed result.
class SolvedAnswer {
  const SolvedAnswer({required this.title, required this.solution});
  final String title;
  final String solution;
}

/// Kisi bhi OpenAI-compatible vision endpoint se answer la sakta hai.
abstract class AnswerProvider {
  Future<SolvedAnswer> solveQuestion(String imagePath);
}

sealed class ApiError implements Exception {
  const ApiError(this.message);
  final String message;
  @override
  String toString() => message;
}

class MissingConfigError extends ApiError {
  const MissingConfigError()
      : super('.env me API_BASE_URL / API_KEY / API_MODEL set karo — '
            'phir dubara try karo.');
}

class NetworkError extends ApiError {
  const NetworkError(super.message);
}

class HttpApiError extends ApiError {
  const HttpApiError(this.statusCode, String message)
      : super(message);
  final int statusCode;
}

class BadResponseError extends ApiError {
  const BadResponseError() : super('Server ka response samajh nahi aaya. Dubara try karo.');
}

class ApiService implements AnswerProvider {
  ApiService({http.Client? client, Map<String, String>? envOverride})
      : _client = client ?? http.Client(),
        _envOverride = envOverride;

  final http.Client _client;
  final Map<String, String>? _envOverride;

  static const _prompt = '''
Ye ek question ki photo hai. Isko solve karo:

Sabse pehli line par SIRF ye likho (uske baad kabhi repeat mat karna):
TITLE: <question ka chhota summary, max 60 characters>

Uske baad poora solution do:
- Step-by-step numbered, easy Hinglish me samjhao
- Formulas LaTeX me likho (\$...\$ ya \$\$...\$\$)
- End me "## Final Answer" section ho
''';

  String _env(String key) {
    final o = _envOverride?[key];
    if (o != null) return o.trim();
    return (dotenv.maybeGet(key) ?? '').trim();
  }

  @override
  Future<SolvedAnswer> solveQuestion(String imagePath) async {
    final base = _env('API_BASE_URL');
    final key = _env('API_KEY');
    final model = _env('API_MODEL');
    if (base.isEmpty || key.isEmpty || model.isEmpty) throw const MissingConfigError();

    final imageBytes = await File(imagePath).readAsBytes();
    final dataUrl = 'data:image/jpeg;base64,${base64Encode(imageBytes)}';

    final body = jsonEncode({
      'model': model,
      'messages': [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': _prompt},
            {'type': 'image_url', 'image_url': {'url': dataUrl}},
          ],
        }
      ],
    });

    http.Response resp;
    try {
      resp = await _client
          .post(Uri.parse(base),
              headers: {
                'Authorization': 'Bearer $key',
                'Content-Type': 'application/json',
              },
              body: body)
          .timeout(const Duration(seconds: 90));
    } on SocketException {
      throw const NetworkError('Internet nahi mil raha. Connection check karke retry karo.');
    } on http.ClientException {
      throw const NetworkError('Server tak nahi pahunch paaye. Thodi der baad retry karo.');
    } on TimeoutException {
      throw const NetworkError('Bahut time lag gaya (90s+). Dubara try karo.');
    }

    if (resp.statusCode != 200) throw HttpApiError(resp.statusCode, _friendly(resp.statusCode));

    final content = _extractContent(utf8.decode(resp.bodyBytes));
    return _splitTitle(content);
  }

  String _friendly(int code) {
    switch (code) {
      case 401 || 403:
        return 'API key galat ya expired lagti hai (.env check karo).';
      case 402:
        return 'Is provider ke credits khatam ho gaye.';
      case 429:
        return 'Bahut zyada requests — thoda ruk ke retry karo.';
      default:
        return 'Server ne error diya ($code). Thodi der baad retry karo.';
    }
  }

  String _extractContent(String responseBody) {
    try {
      final map = jsonDecode(responseBody) as Map<String, dynamic>;
      final choices = map['choices'] as List;
      final msg = choices.first as Map<String, dynamic>;
      final content = (msg['message'] as Map<String, dynamic>)['content'];
      if (content is String && content.trim().isNotEmpty) return content;
    } on FormatException {
      // fall through — JSON malformed
    } catch (_) {
      // structure unexpected
    }
    throw const BadResponseError();
  }

  /// "TITLE: ...\n<rest>" split; warna fallback pehli non-empty line.
  SolvedAnswer _splitTitle(String content) {
    final m = RegExp(r'^\s*TITLE:\s*(.*)\r?\n?', caseSensitive: false).firstMatch(content);
    if (m != null) {
      var title = m.group(1)?.trim() ?? '';
      if (title.isEmpty) title = 'Doubt';
      if (title.length > 60) title = '${title.substring(0, 57)}…';
      return SolvedAnswer(title: title, solution: content.substring(m.end).trim());
    }
    var title = content
        .split('\n')
        .map((l) => l.trim())
        .firstWhere((l) => l.isNotEmpty, orElse: () => 'Doubt');
    if (title.startsWith('#')) title = title.replaceAll('#', '').trim();
    if (title.length > 60) title = '${title.substring(0, 57)}…';
    return SolvedAnswer(title: title, solution: content.trim());
  }
}
```

- [ ] **Step 4: Pass** — Run: `/opt/flutter/bin/flutter test test/api_service_test.dart` → PASS (7)

- [ ] **Step 5: Commit** — `git add -A && git commit -m "feat: provider-agnostic OpenAI-compatible API service with TITLE parsing"`

---

### Task 6: DoubtStore (TDD)

**Files:**
- Create: `lib/store/doubt_store.dart`, `test/doubt_store_test.dart`

**Interfaces:**
- Consumes: `DbService` (Task 3), `SolvedAnswer` (Task 5)
- Produces: `class DoubtStore extends ChangeNotifier` —
  - `List<Doubt> get doubts`, `bool get loading`
  - `Future<void> refresh()`
  - `Future<void> addSaved(String imagePath, SolvedAnswer answer)` — insert + list-head me add + notify
  - `Future<void> remove(Doubt d)` — db+file delete + list se hatao + notify

- [ ] **Step 1: Failing test** — `test/doubt_store_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_common_ffi.dart';
import 'package:ai_doubt_solver/services/db_service.dart';
import 'package:ai_doubt_solver/services/api_service.dart';
import 'package:ai_doubt_solver/store/doubt_store.dart';

void main() {
  setUpAll(() {
    sqsliteFfiInitGuard();
  });

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

void sqsliteFfiInitGuard() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
```

(Correction: helper ka naam `initFfi()` rakho aur `setUpAll(initFfi)` use karo — typo `sqsliteFfiInitGuard` mat chhodna.)

- [ ] **Step 2: Fail confirm** → Run test → FAIL

- [ ] **Step 3: Implement** — `lib/store/doubt_store.dart`:

```dart
import 'package:flutter/foundation.dart';

import '../models/doubt.dart';
import '../services/api_service.dart';
import '../services/db_service.dart';

/// Single source of truth for saved doubts. UI isse listen karti hai.
class DoubtStore extends ChangeNotifier {
  DoubtStore(this._db);

  final DbService _db;
  List<Doubt> _doubts = [];
  bool _loading = false;

  List<Doubt> get doubts => _doubts;
  bool get loading => _loading;

  Future<void> refresh() async {
    _loading = true;
    notifyListeners();
    _doubts = await _db.getAll();
    _loading = false;
    notifyListeners();
  }

  Future<void> addSaved(String imagePath, SolvedAnswer answer) async {
    final draft = Doubt(
      id: null,
      imagePath: imagePath,
      title: answer.title,
      solution: answer.solution,
      createdAt: DateTime.now(),
    );
    final id = await _db.insert(draft);
    _doubts = [
      Doubt(id: id, imagePath: draft.imagePath, title: draft.title,
          solution: draft.solution, createdAt: draft.createdAt),
      ..._doubts,
    ];
    notifyListeners();
  }

  Future<void> remove(Doubt d) async {
    await _db.delete(d.id!);
    _doubts = _doubts.where((x) => x.id != d.id).toList();
    notifyListeners();
  }
}
```

- [ ] **Step 4: Pass** — Run: `/opt/flutter/bin/flutter test test/doubt_store_test.dart` → PASS (2)

- [ ] **Step 5: Commit** — `git add -A && git commit -m "feat: DoubtStore ChangeNotifier — refresh/addSaved/remove"`

---

### Task 7: SolveTab + route transition

**Files:**
- Create: `lib/screens/solve_tab.dart`, `lib/widgets/solution_route.dart`, `test/solve_tab_test.dart`

**Interfaces:**
- Consumes: `AppTheme` (Task 2), `ImageService` (Task 4), `path_provider`
- Produces:
  - `class SolveTab extends StatelessWidget` (constructor: `const SolveTab()`)
  - `class SolutionRoute extends PageRouteBuilder` — `SolutionRoute(String imagePath)`; slide-up+fade 300ms `Curves.easeOutCubic` (Task 8 isse consume karega)

- [ ] **Step 1: Widget test likho** — `test/solve_tab_test.dart`:

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
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
```

- [ ] **Step 2: Fail confirm** — Run: `/opt/flutter/bin/flutter test test/solve_tab_test.dart` → FAIL

- [ ] **Step 3: Implement** — `lib/widgets/solution_route.dart`:

```dart
import 'package:flutter/material.dart';

/// Photo-pick ke baad SolutionScreen tak ka custom transition:
/// slide-up + fade, 300ms, easeOutCubic.
class SolutionRoute extends PageRouteBuilder {
  SolutionRoute(String imagePath)
      : super(
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (_, __, ___) => Placeholder(), // Task 8 me SolutionScreen aayega
          settings: RouteSettings(arguments: imagePath),
        );

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation, Widget child) =>
      FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        child: SlideTransition(
          position: Tween(begin: const Offset(0, .06), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
      );
}
```

(Task 8 isme `pageBuilder` ko `SolutionScreen(imagePath)` se replace karega — abhi compile rahne do Placeholder se.)

`lib/screens/solve_tab.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../services/image_service.dart';
import '../theme/app_theme.dart';
import '../widgets/solution_route.dart';

/// Tab 1 — hero + photo pick actions.
class SolveTab extends StatelessWidget {
  const SolveTab({super.key});

  Future<void> _pick(BuildContext context, ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final picked = await ImagePicker().pickImage(source: source);
      if (picked == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final processed = await ImageService().process(picked.path, dir.path);
      navigator.push(SolutionRoute(processed));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Photo process nahi ho paayi: $e'),
        backgroundColor: AppTheme.teal,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Center(
              child: Container(
                width: 96, height: 96,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [AppTheme.teal, Color(0xFF0093A8)],
                  ),
                  boxShadow: [
                    BoxShadow(color: AppTheme.teal.withValues(alpha: .35), blurRadius: 32, offset: const Offset(0, 12)),
                  ],
                ),
                child: const Icon(Icons.auto_awesome, size: 44, color: AppTheme.lime),
              ),
            ),
            const SizedBox(height: 28),
            Text('Koi bhi doubt?\nPhoto kheencho!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 10),
            Text('Camera se question ki photo lo — step-by-step Hinglish solution turant.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 36),
            _ActionCard(
              icon: Icons.photo_camera_rounded,
              iconBg: AppTheme.teal.withValues(alpha: .15),
              iconColor: cs.primary,
              title: 'Camera se poochho',
              subtitle: 'Question ki photo click karo',
              onTap: () => _pick(context, ImageSource.camera),
            ),
            const SizedBox(height: 14),
            _ActionCard(
              icon: Icons.photo_library_rounded,
              iconBg: AppTheme.lime.withValues(alpha: .18),
              iconColor: const Color(0xFF7A9A00),
              title: 'Gallery se choose karo',
              subtitle: 'Pehle se saved screenshot/photo',
              onTap: () => _pick(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon, required this.iconBg, required this.iconColor,
    required this.title, required this.subtitle, required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF131920) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Container(width: 52, height: 52,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: iconColor, size: 26)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 3),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ])),
            Icon(Icons.chevron_right_rounded, color: Theme.of(context).textTheme.bodySmall?.color),
          ]),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Pass + analyze**

Run: `/opt/flutter/bin/flutter test test/solve_tab_test.dart && /opt/flutter/bin/flutter analyze`
Expected: PASS (2), No issues

- [ ] **Step 5: Commit** — `git add -A && git commit -m "feat: SolveTab hero UI + custom slide-fade SolutionRoute"`

---

### Task 8: SolutionScreen — analyzing → result → error

**Files:**
- Create: `lib/screens/solution_screen.dart`, `lib/widgets/shimmer_box.dart`, `test/solution_screen_test.dart`
- Modify: `lib/widgets/solution_route.dart` (pageBuilder → SolutionScreen)

**Interfaces:**
- Consumes: `AnswerProvider`/`ApiService`, `SolvedAnswer`, `ApiError` (Task 5); `DoubtStore.addSaved` (Task 6); `AppTheme` (Task 2)
- Produces: `class SolutionScreen extends StatefulWidget` — `SolutionScreen({required String imagePath, AnswerProvider? api})` (api null → `ApiService()`)

- [ ] **Step 1: Widget tests** — `test/solution_screen_test.dart`:

```dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:ai_doubt_solver/screens/solution_screen.dart';
import 'package:ai_doubt_solver/services/api_service.dart';
import 'package:ai_doubt_solver/services/db_service.dart';
import 'package:ai_doubt_solver/store/doubt_store.dart';
import 'package:sqflite_common_ffi/sqflite_common_ffi.dart';

class FakeApi implements AnswerProvider {
  FakeApi(this.delayMs, this.result);
  final int delayMs;
  final Object result; // SolvedAnswer ya ApiError
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

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

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
    final db = DbService(dbName: 't_a_${DateTime.now().microsecondsSinceEpoch}.db');
    final api = FakeApi(500, const SolvedAnswer(title: 'Pythagoras', solution: '## Step 1\n$a^2+b^2=c^2$'));
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
  });

  testWidgets('error par friendly message + Retry', (tester) async {
    final db = DbService(dbName: 't_b_${DateTime.now().microsecondsSinceEpoch}.db');
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
  });
}
```

(NOTE: `FakeApi.result` ko non-final rakna — `late Object result;` constructor assign se. Upar `final Object result;` ko `Object result;` se replace karo.)

- [ ] **Step 2: Fail confirm** — FAIL (solution_screen.dart missing)

- [ ] **Step 3: Implement** — `lib/widgets/shimmer_box.dart`:

```dart
import 'package:flutter/material.dart';

/// Lightweight shimmer skeleton block.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({super.key, this.width, this.height = 16, this.radius = 8});
  final double? width;
  final double height;
  final double radius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? Colors.white.withValues(alpha: .05) : Colors.black.withValues(alpha: .06);
    final hl = isDark ? Colors.white.withValues(alpha: .12) : Colors.black.withValues(alpha: .12);
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(-1 - 2 * _c.value + 1, 0),
            end: Alignment(1 * _c.value + 1, 0),
            colors: [base, hl, base],
          ),
        ),
      ),
    );
  }
}
```

`lib/screens/solution_screen.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../store/doubt_store.dart';
import '../theme/app_theme.dart';
import '../widgets/shimmer_box.dart';

enum _Phase { analyzing, done, error }

/// Photo → API call → markdown solution. Success par auto-save.
class SolutionScreen extends StatefulWidget {
  const SolutionScreen({super.key, required this.imagePath, AnswerProvider? api})
      : _api = api;

  final String imagePath;
  final AnswerProvider? _api;

  @override
  State<SolutionScreen> createState() => _SolutionScreenState();
}

class _SolutionScreenState extends State<SolutionScreen> {
  static const _statusMessages = [
    'Photo padh rahe hain…',
    'Question samajh rahe hain…',
    'Steps banaye ja rahe hain…',
    'Ox Alpha soch raha hai…',
  ];

  late final AnswerProvider _api = widget._api ?? ApiService();
  _Phase _phase = _Phase.analyzing;
  SolvedAnswer? _answer;
  String? _error;
  int _msgIndex = 0;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() => _msgIndex = (_msgIndex + 1) % _statusMessages.length);
    });
    _solve();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _solve() async {
    setState(() {
      _phase = _Phase.analyzing;
      _error = null;
    });
    try {
      final answer = await _api.solveQuestion(widget.imagePath);
      if (!mounted) return;
      await context.read<DoubtStore>().addSaved(widget.imagePath, answer);
      if (!mounted) return;
      setState(() {
        _answer = answer;
        _phase = _Phase.done;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _phase = _Phase.error;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Kuch galat ho gaya: $e';
        _phase = _Phase.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solution')),
      body: SafeArea(
        child: switch (_phase) {
          _Phase.analyzing => _AnalyzingView(imagePath: widget.imagePath, message: _statusMessages[_msgIndex]),
          _Phase.done => _ResultView(answer: _answer!, imagePath: widget.imagePath),
          _Phase.error => _ErrorView(error: _error!, onRetry: _solve),
        },
      ),
    );
  }
}

class _AnalyzingView extends StatelessWidget {
  const _AnalyzingView({required this.imagePath, required this.message});
  final String imagePath;
  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(padding: const EdgeInsets.all(20), children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 260),
          child: Image.file(File(imagePath), fit: BoxFit.cover, width: double.infinity),
        ),
      ),
      const SizedBox(height: 24),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        SizedBox(width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: Theme.of(context).colorScheme.primary)),
        const SizedBox(width: 12),
        AnimatedSwitcher(duration: const Duration(milliseconds: 350),
          child: Text(message, key: ValueKey(message),
              style: Theme.of(context).textTheme.titleMedium)),
      ]),
      const SizedBox(height: 28),
      ...List.generate(4, (i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ShimmerBox(height: 14 + (i % 2) * 6,
            width: double.infinity, radius: 7),
      )),
      const SizedBox(height: 8),
      Center(child: Text('Ho sakta hai 30–60 second lag jayein…',
          style: Theme.of(context).textTheme.bodySmall)),
      if (!isDark) const SizedBox(height: 8),
    ]);
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.answer, required this.imagePath});
  final SolvedAnswer answer;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(padding: const EdgeInsets.all(20), children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131920) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.teal.withValues(alpha: .25)),
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(File(imagePath), width: 56, height: 56, fit: BoxFit.cover),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(answer.title, style: Theme.of(context).textTheme.titleLarge)),
        ]),
      ),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131920) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: GptMarkdown(answer.solution, style: Theme.of(context).textTheme.bodyMedium),
      ),
      const SizedBox(height: 24),
      Row(children: [
        Icon(Icons.check_circle_rounded, color: AppTheme.lime, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text('Solution history me save ho gaya',
            style: Theme.of(context).textTheme.bodySmall)),
      ]),
    ]);
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 84, height: 84,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(24)),
            child: Icon(Icons.cloud_off_rounded, size: 40,
                color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: 20),
          Text(error, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 26),
          FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Retry')),
        ]),
      ),
    );
  }
}
```

(`import 'dart:io'` add karna bhoolna mat — File use ho raha hai.)

`lib/widgets/solution_route.dart` update:

```dart
pageBuilder: (_, __, ___) => SolutionScreen(imagePath: imagePath),
```

(import ke saath `import '../screens/solution_screen.dart';`, Placeholder hatao.)

- [ ] **Step 4: Pass + analyze**

Run: `/opt/flutter/bin/flutter test test/solution_screen_test.dart && /opt/flutter/bin/flutter analyze`
Expected: PASS (2), No issues. (Timer periodic test me pending timer warning de sakta hai — agar `A Timer is still pending` aaye to test ke end me `await tester.pumpWidget(const SizedBox());` add karke dispose trigger karo.)

- [ ] **Step 5: Commit** — `git add -A && git commit -m "feat: SolutionScreen — shimmer analyzing state, markdown result, retry error state"`

---

### Task 9: HistoryTab + DoubtCard + Empty state + DetailScreen

**Files:**
- Create: `lib/screens/history_tab.dart`, `lib/screens/detail_screen.dart`, `lib/widgets/doubt_card.dart`, `lib/widgets/empty_history.dart`, `lib/utils/time_ago.dart`, `test/history_ui_test.dart`

**Interfaces:**
- Consumes: `DoubtStore` (doubts/remove/loading), `Doubt`, `AppTheme`, `GptMarkdown`
- Produces:
  - `class HistoryTab extends StatelessWidget` — `HistoryTab({required VoidCallback onGoToSolve})`
  - `class DetailScreen extends StatelessWidget` — `DetailScreen({required Doubt doubt})`
  - `String timeAgo(DateTime dt)` — 'abhi' | '<n> min pehle' | '<n> ghante pehle' | '<n> din pehle' | 'd MMM yyyy'

- [ ] **Step 1: Tests** — `test/history_ui_test.dart`:

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ai_doubt_solver/models/doubt.dart';
import 'package:ai_doubt_solver/screens/history_tab.dart';
import 'package:ai_doubt_solver/store/doubt_store.dart';
import 'package:ai_doubt_solver/services/db_service.dart';
import 'package:ai_doubt_solver/utils/time_ago.dart';
import 'package:sqflite_common_ffi/sqflite_common_ffi.dart';

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

  Future<DoubtStore> storeWith(DbService db, {bool empty = false}) async {
    final store = DoubtStore(db);
    if (!empty) {
      await store.addSaved('/nonexistent_${DateTime.now().millisecond}.jpg',
          const AiAnswerShim('Pythagoras theorem proof'));
    }
    return store;
  }

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

  testWidgets('items hone par cards dikhte hain, tap par detail khulta hai', (tester) async {
    final db = DbService(dbName: 't_f_${DateTime.now().microsecondsSinceEpoch}.db');
    final store = DoubtStore(db);
    await store.addSaved('/nonexistent.jpg', const SolvedAnswer(title: 'Pythagoras Q', solution: 'Sol'));

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
```

NOTE: upar `AiAnswerShim` galti hai — wo `SolvedAnswer` hona chahiye (`import 'package:ai_doubt_solver/services/api_service.dart';` bhi chahiye). Sahi line:
```dart
await store.addSaved('/nonexistent_x.jpg', const SolvedAnswer(title: 'Pythagoras theorem proof', solution: 'S'));
```
aur test me `GptMarkdown` import bhi chahiye detail assertion ke liye: `import 'package:gpt_markdown/gpt_markdown.dart';`

- [ ] **Step 2: Fail confirm** — FAIL

- [ ] **Step 3: Implement**

`lib/utils/time_ago.dart`:

```dart
/// Compact Hinglish relative time.
String timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'abhi';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min pehle';
  if (diff.inHours < 24) return '${diff.inHours} ghante pehle';
  if (diff.inDays < 7) return '${diff.inDays} din pehle';
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
}
```

`lib/widgets/doubt_card.dart`:

```dart
import 'dart:io';

import 'package:flutter/material.dart';

import '../models/doubt.dart';
import '../utils/time_ago.dart';

/// History list ka single card — thumbnail + title + relative time.
class DoubtCard extends StatelessWidget {
  const DoubtCard({super.key, required this.doubt});
  final Doubt doubt;

  @override
  Widget build(BuildContext context) {
    final imgExists = File(doubt.imagePath).existsSync();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: imgExists
              ? Image.file(File(doubt.imagePath), width: 64, height: 64, fit: BoxFit.cover)
              : Container(width: 64, height: 64, color: Theme.of(context).dividerColor,
                  child: const Icon(Icons.image_not_supported_outlined, size: 24)),
        ),
        title: Text(doubt.title, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(timeAgo(doubt.createdAt), style: Theme.of(context).textTheme.bodySmall),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => DetailScreen(doubt: doubt))),
      ),
    );
  }
}
```

`lib/widgets/empty_history.dart`:

```dart
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Khali history ka illustration-style empty state.
class EmptyHistory extends StatelessWidget {
  const EmptyHistory({super.key, required this.onGoToSolve});
  final VoidCallback onGoToSolve;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(children: [
          Stack(alignment: Alignment.center, children: [
            Container(width: 132, height: 132,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  color: AppTheme.teal.withValues(alpha: .10))),
            Container(width: 96, height: 96,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  color: AppTheme.teal.withValues(alpha: .18)),
              child: Icon(Icons.help_outline_rounded, size: 42, color: AppTheme.teal)),
            Positioned(
              top: 4, right: 8,
              child: Container(width: 30, height: 30,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: AppTheme.lime.withValues(alpha: .9)),
                child: const Icon(Icons.auto_awesome, size: 15, color: Colors.black)),
            ),
          ]),
          const SizedBox(height: 28),
          Text('Abhi koi doubt solve nahi hua', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Koi bhi question ki photo kheencho —\nsolution yahan save hota rahega.',
              textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: onGoToSolve,
            icon: const Icon(Icons.camera_alt_rounded),
            label: const Text('Solve karo'),
          ),
        ]),
      ),
    );
  }
}
```

`lib/screens/history_tab.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../store/doubt_store.dart';
import '../widgets/doubt_card.dart';
import '../widgets/empty_history.dart';

/// Tab 2 — saare past doubts.
class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key, required this.onGoToSolve});
  final VoidCallback onGoToSolve;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<DoubtStore>();
    if (store.doubts.isEmpty) {
      return EmptyHistory(onGoToSolve: onGoToSolve);
    }
    return RefreshIndicator(
      onRefresh: store.refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        itemCount: store.doubts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 0),
        itemBuilder: (_, i) => DoubtCard(doubt: store.doubts[i]),
      ),
    );
  }
}
```

`lib/screens/detail_screen.dart`:

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:provider/provider.dart';

import '../models/doubt.dart';
import '../store/doubt_store.dart';
import '../utils/time_ago.dart';

/// Saved doubt ka poora view + delete action.
class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.doubt});
  final Doubt doubt;

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete karein?'),
        content: const Text('Ye doubt aur uski photo permanently delete ho jayegi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<DoubtStore>().remove(doubt);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(timeAgo(doubt.createdAt)),
        actions: [
          IconButton(icon: const Icon(Icons.delete_outline_rounded), onPressed: () => _confirmDelete(context)),
        ],
      ),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          if (File(doubt.imagePath).existsSync())
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: Image.file(File(doubt.imagePath), fit: BoxFit.cover, width: double.infinity),
              ),
            ),
          const SizedBox(height: 18),
          Text(doubt.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131920) : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: GptMarkdown(doubt.solution, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ]),
      ),
    );
  }
}
```

- [ ] **Step 4: Pass + analyze**

Run: `/opt/flutter/bin/flutter test test/history_ui_test.dart && /opt/flutter/bin/flutter analyze`
Expected: PASS, No issues

- [ ] **Step 5: Commit** — `git add -A && git commit -m "feat: HistoryTab with cards, empty state, detail view + delete"`

---

### Task 10: App shell wiring — main.dart + RootShell

**Files:**
- Modify: `lib/main.dart` (replace placeholder)
- Create: `lib/screens/root_shell.dart`, `test/smoke_test.dart`

**Interfaces:**
- Consumes: sab kuch (tasks 2–9)
- Produces: runnable app — `main()` dotenv safe-load + Provider + MaterialApp(themes) + RootShell(2 tabs, IndexedStack, NavigationBar)

- [ ] **Step 1: Smoke test** — `test/smoke_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ai_doubt_solver/screens/root_shell.dart';
import 'package:ai_doubt_solver/store/doubt_store.dart';
import 'package:ai_doubt_solver/services/db_service.dart';
import 'package:sqflite_common_ffi/sqflite_common_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('app shell render hota hai, tabs switch hote hain', (tester) async {
    final db = DbService(dbName: 't_smoke_${DateTime.now().microsecondsSinceEpoch}.db');
    final store = DoubtStore(db);
    await store.refresh();

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
```

NOTE: `RootShell` me `skipInitialRefresh` param add karo — `{bool skipInitialRefresh = false}` — taaki test ffi-db ke saath deterministic rahe (warna initState refresh double-load karta hai). Production call site skip nahi karega.

- [ ] **Step 2: Fail confirm** — FAIL (root_shell.dart missing)

- [ ] **Step 3: Implement** — `lib/screens/root_shell.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'history_tab.dart';
import 'solve_tab.dart';
import '../store/doubt_store.dart';

/// Bottom NavigationBar wala 2-tab shell. IndexedStack tab state preserve karta hai.
class RootShell extends StatefulWidget {
  const RootShell({super.key, this.skipInitialRefresh = false});
  final bool skipInitialRefresh;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    if (!widget.skipInitialRefresh) {
      context.read<DoubtStore>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          const SolveTab(),
          HistoryTab(onGoToSolve: () => setState(() => _index = 0)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Solve',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}
```

`lib/main.dart` (final):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'screens/root_shell.dart';
import 'services/db_service.dart';
import 'store/doubt_store.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env missing (fresh install/CI) — solve attempt par clear error dikhega.
    debugPrint('[solver] .env load nahi hua — API calls error denge jab tak set na ho');
  }
  runApp(MultiProvider(
    providers: [
      Provider<DbService>(create: (_) => DbService()),
      ChangeNotifierProvider<DoubtStore>(create: (ctx) => DoubtStore(ctx.read<DbService>())),
    ],
    child: const SolverApp(),
  ));
}

class SolverApp extends StatelessWidget {
  const SolverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Doubt Solver',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const RootShell(),
    );
  }
}
```

- [ ] **Step 4: Full suite + analyze**

Run: `/opt/flutter/bin/flutter test && /opt/flutter/bin/flutter analyze`
Expected: ALL PASS, No issues

- [ ] **Step 5: Commit** — `git add -A && git commit -m "feat: app shell — dotenv safe-load, providers, 2-tab NavigationBar root"`

---

### Task 11: Polish audit (dark mode + motion consistency)

**Files:**
- Modify: koi bhi screen/widget file jisme audit issue mile

**Interfaces:** koi naya interface nahi — visual/consistency pass.

- [ ] **Step 1: Checklist sweep** — har screen file me verify:
  1. Koi hardcoded `Colors.white`/`Colors.black` sirf wahan jahan intentional (lime badge icon black-on-lime theek hai)
  2. Dark surfaces `Color(0xFF131920)` ya theme se — kabhi `Colors.grey.shadeXXX` nahi
  3. Radius consistently 20 (cards) / 16 (buttons) / 12–14 (chhote elements)
  4. Transitions: SolutionRoute use ho raha hai (default MaterialPageRoute nahi) — detail screen ke liye MaterialPageRoute acceptable
  5. `gpt_markdown` ka style app text theme se aa raha hai

Jo bhi deviation mile, fix karo.

- [ ] **Step 2: Full verify** — Run: `/opt/flutter/bin/flutter test && /opt/flutter/bin/flutter analyze` → PASS

- [ ] **Step 3: Commit** — `git add -A && git commit -m "polish: dark-mode + spacing/motion consistency audit"`

---

### Task 12: CI workflow + GitHub remote

**Files:**
- Create: `.github/workflows/build-apk.yml`

**Interfaces:** repo-level CI — push par APK artifact.

- [ ] **Step 1: Workflow likho** — `.github/workflows/build-apk.yml`:

```yaml
name: Build Release APK

on:
  push:
    branches: ['**']
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'

      # .env gitignored hai — asset bundling ke liye dummy chahiye
      - name: Create placeholder .env
        run: |
          echo "API_BASE_URL=https://openrouter.ai/api/v1/chat/completions" >> .env
          echo "API_KEY=placeholder" >> .env
          echo "API_MODEL=stealth/ox-alpha" >> .env

      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true

      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
      - run: flutter build apk --release

      - uses: actions/upload-artifact@v4
        with:
          name: ai-doubt-solver-apk
          path: build/app/outputs/flutter-apk/app-release.apk
          retention-days: 30
```

- [ ] **Step 2: Remote add karo**

```bash
git remote add origin https://github.com/RAJ-af/Solver-.git
```

Push user-side auth maangega — user ko bolo ya `gh` available/authenticated ho to:
`git push -u origin master`

- [ ] **Step 3: Commit** — `git add -A && git commit -m "ci: release APK build workflow (analyze + test + artifact)"`

---

### Task 13: Local release build verification

**Files:** koi source change nahi — verification only.

- [ ] **Step 1: Environment ready**

```bash
export PATH="/opt/flutter/bin:$PATH"
export ANDROID_SDK_ROOT=/opt/android-sdk/sdk
yes | flutter doctor --android-licenses || true
flutter doctor -v
```

Expected: Flutter 3.47.1 stable, Android toolchain detected (license warnings ignore-able).

- [ ] **Step 2: Release APK build**

```bash
cd /root/ai_doubt_solver && flutter build apk --release
```

Expected: `✓ Built build/app/outputs/flutter-apk/app-release.apk` (pehli baar gradle download ~5–15 min lag sakta hai).

- [ ] **Step 3: Result report**

APK path + size report karo. Agar build fail ho → systematic-debugging skill use karke root cause nikalo, fix karo, dobara build.

---

## Plan Self-Review Notes

- Spec coverage: scaffold/env (T1), theme/colors/fonts (T2), DB schema (T3), image pipeline amendment (T4), provider-agnostic API + TITLE parsing + errors (T5), store (T6), home UI + transitions (T7), analyzing/result/error states (T8), history + empty + detail (T9), shell + dotenv (T10), polish/dark audit (T11), CI (T12), local verify (T13). ✅
- Type consistency: `SolvedAnswer(title:, solution:)`, `AnswerProvider.solveQuestion(String)`, `DoubtStore.addSaved(imagePath, answer)` / `remove(Doubt)`, `DbService.insert/getAll/delete`, `ImageService.process(src, outDir, {maxWidth, quality})`, `SolutionRoute(imagePath)`, `HistoryTab(onGoToSolve:)`, `RootShell({skipInitialRefresh})` — sab tasks me same naam. ✅
- Known test-code typos deliberately flagged inline (Task 6 helper name, Task 9 shim) — executors corrected version use karein jahan NOTE diya gaya hai.
