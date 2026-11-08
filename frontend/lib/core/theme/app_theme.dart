import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class Sp {
  static const double x1 = 8, x2 = 16, x3 = 24, x4 = 32, x5 = 40;
}

class Rd {
  static const double card = 22, button = 16, input = 14;
}

TextStyle labelStyle(BuildContext c) =>
    TextStyle(fontSize: 11, letterSpacing: 1.4, fontWeight: FontWeight.w600, color: c.ergo.muted);
/// Editorial serif used for titles on premium surfaces (workspace page, ticket).
TextStyle serif(double size, {FontWeight weight = FontWeight.w600, Color? color, double? height, double? letterSpacing}) =>
    GoogleFonts.playfairDisplay(fontSize: size, fontWeight: weight, color: color, height: height, letterSpacing: letterSpacing);
TextStyle tabular(TextStyle s) => s.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

class AppTheme {
  static ThemeData build(ErgoColors c) {
    final base = ThemeData(brightness: c.brightness, useMaterial3: true);
    final text = GoogleFonts.manropeTextTheme(base.textTheme).apply(bodyColor: c.text, displayColor: c.text);
    OutlineInputBorder b(Color col, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(Rd.input), borderSide: BorderSide(color: col, width: w));
    return base.copyWith(
      scaffoldBackgroundColor: c.bg,
      textTheme: text,
      extensions: [c],
      dividerColor: c.border,
      colorScheme: ColorScheme(
        brightness: c.brightness,
        primary: c.accent, onPrimary: c.onAccent,
        secondary: c.accent2, onSecondary: c.onAccent,
        error: c.error, onError: Colors.white,
        surface: c.surface, onSurface: c.text,
        surfaceContainerHigh: c.surface, surfaceContainerHighest: c.surface2,
        outline: c.border,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg, foregroundColor: c.text, elevation: 0, scrolledUnderElevation: 0,
        titleTextStyle: text.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: c.text),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: c.surface2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: c.muted),
        border: b(c.border), enabledBorder: b(c.border),
        focusedBorder: b(c.accent, 1.5), errorBorder: b(c.error), focusedErrorBorder: b(c.error, 1.5),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface, modalBackgroundColor: c.surface, showDragHandle: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating, backgroundColor: c.elevated,
        contentTextStyle: TextStyle(color: c.text),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.accent),
    );
  }
}
