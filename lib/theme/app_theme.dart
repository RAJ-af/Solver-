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
      dividerColor: isDark ? Colors.white.withValues(alpha: .06) : Colors.black.withValues(alpha: .06),
      textTheme: Typography.material2021(colorScheme: cs).black
          .apply(bodyColor: isDark ? _onDark : _inkLight, displayColor: isDark ? _onDark : _inkLight)
          .merge(TextTheme(
            headlineLarge: GoogleFonts.sora(fontSize: 28, fontWeight: FontWeight.w700),
            headlineSmall: GoogleFonts.sora(fontSize: 22, fontWeight: FontWeight.w700),
            titleLarge: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w600),
            titleMedium: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w600),
            bodyMedium: GoogleFonts.inter(fontSize: 15),
            bodySmall: GoogleFonts.inter(fontSize: 13, color: isDark ? _mutedDark : _mutedLight),
          )),
    );
  }
}
