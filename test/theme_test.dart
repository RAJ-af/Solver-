import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_doubt_solver/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
    // google_fonts 8.x returns variant-suffixed families (e.g. 'Sora_700'),
    // with the plain family name as fontFamilyFallback.
    expect(AppTheme.light().textTheme.headlineSmall?.fontFamily, startsWith('Sora'));
    expect(AppTheme.dark().textTheme.bodyMedium?.fontFamily, startsWith('Inter'));
  });
}
