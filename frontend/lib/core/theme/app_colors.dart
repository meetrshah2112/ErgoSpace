import 'package:flutter/material.dart';

class ErgoColors extends ThemeExtension<ErgoColors> {
  final String name;
  final Brightness brightness;
  final Color bg, surface, surface2, elevated, text, textSecondary, muted, border, accent, accent2, onAccent, error, success;
  const ErgoColors({
    required this.name,
    required this.brightness,
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.elevated,
    required this.text,
    required this.textSecondary,
    required this.muted,
    required this.border,
    required this.accent,
    required this.accent2,
    required this.onAccent,
    required this.error,
    required this.success,
  });

  static const carbon = ErgoColors(
    name: 'Carbon / Electric Lime', brightness: Brightness.dark,
    bg: Color(0xFF0B0D0E), surface: Color(0xFF141819), surface2: Color(0xFF1D2324), elevated: Color(0xFF252C2D),
    text: Color(0xFFF4F6F0), textSecondary: Color(0xFFA0AAA6), muted: Color(0xFF6E7975), border: Color(0xFF303938),
    accent: Color(0xFFC8FF45), accent2: Color(0xFF9BE86A), onAccent: Color(0xFF0B0D0E),
    error: Color(0xFFFF5B62), success: Color(0xFF9AE6A0),
  );

  static const porcelain = ErgoColors(
    name: 'Porcelain / Ink', brightness: Brightness.light,
    bg: Color(0xFFF5F6F1), surface: Color(0xFFFFFFFF), surface2: Color(0xFFECEFE9), elevated: Color(0xFFF0F2EC),
    text: Color(0xFF151A18), textSecondary: Color(0xFF69716C), muted: Color(0xFF9AA39E), border: Color(0xFFDEE3DC),
    accent: Color(0xFF9ACB36), accent2: Color(0xFF7FB023), onAccent: Color(0xFF151A18),
    error: Color(0xFFD94747), success: Color(0xFF377D51),
  );

  static const midnight = ErgoColors(
    name: 'Midnight / Electric Ice', brightness: Brightness.dark,
    bg: Color(0xFF0B1117), surface: Color(0xFF121D25), surface2: Color(0xFF1C2932), elevated: Color(0xFF243540),
    text: Color(0xFFEDF5F8), textSecondary: Color(0xFF9EAFB9), muted: Color(0xFF6F8591), border: Color(0xFF2B3A43),
    accent: Color(0xFF74E8FF), accent2: Color(0xFF4FC8E0), onAccent: Color(0xFF0B1117),
    error: Color(0xFFFF5B62), success: Color(0xFF7CE0A5),
  );

  @override
  ErgoColors copyWith() => this;
  @override
  ErgoColors lerp(ThemeExtension<ErgoColors>? other, double t) => other is ErgoColors && t > 0.5 ? other : this;
}

extension ErgoContext on BuildContext {
  ErgoColors get ergo => Theme.of(this).extension<ErgoColors>()!;
}
