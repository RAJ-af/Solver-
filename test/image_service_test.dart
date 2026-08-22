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
