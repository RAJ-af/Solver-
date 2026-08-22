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
    try {
      // Upscale kabhi nahi — chhoti image as-is dimensions rakhti hai.
      final tw = desc.width > maxWidth ? maxWidth : desc.width;
      final th = desc.width > maxWidth
          ? (desc.height * maxWidth / desc.width).round()
          : desc.height;

      final codec =
          await desc.instantiateCodec(targetWidth: tw, targetHeight: th);
      final frame = await codec.getNextFrame();
      final data =
          await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
      frame.image.dispose();
      codec.dispose();

      // rawRgba bytes → image package Image → JPEG encode (quality control).
      final px = data!.buffer.asUint32List();
      final image = img.Image(width: tw, height: th);
      for (var y = 0; y < th; y++) {
        for (var x = 0; x < tw; x++) {
          final c = px[y * tw + x];
          image.setPixelRgba(
              x, y, c & 0xFF, (c >> 8) & 0xFF, (c >> 16) & 0xFF, (c >> 24) & 0xFF);
        }
      }
      final jpg = img.encodeJpg(image, quality: quality);

      final name =
          '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(1 << 31)}.jpg';
      final out = File('$outputDir/$name');
      await out.writeAsBytes(jpg);
      return out.path;
    } finally {
      // Creator dispose ka zimmedar hai — warna encoded source bytes
      // native side par leak hoti hain (descriptor pehle, phir buffer).
      desc.dispose();
      buffer.dispose();
    }
  }
}
