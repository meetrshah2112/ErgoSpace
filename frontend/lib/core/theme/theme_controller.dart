import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';

final sharedPrefsProvider = Provider<SharedPreferences>((_) => throw UnimplementedError());

enum AppThemeChoice { system, light, dark, carbon, porcelain, midnight }

class ThemeState {
  final ErgoColors light, dark;
  final ThemeMode mode;
  const ThemeState(this.light, this.dark, this.mode);
}

ThemeState resolveTheme(AppThemeChoice c) {
  switch (c) {
    case AppThemeChoice.system:
      return const ThemeState(ErgoColors.porcelain, ErgoColors.carbon, ThemeMode.system);
    case AppThemeChoice.light:
      return const ThemeState(ErgoColors.porcelain, ErgoColors.carbon, ThemeMode.light);
    case AppThemeChoice.dark:
      return const ThemeState(ErgoColors.porcelain, ErgoColors.carbon, ThemeMode.dark);
    case AppThemeChoice.carbon:
      return const ThemeState(ErgoColors.carbon, ErgoColors.carbon, ThemeMode.dark);
    case AppThemeChoice.porcelain:
      return const ThemeState(ErgoColors.porcelain, ErgoColors.porcelain, ThemeMode.light);
    case AppThemeChoice.midnight:
      return const ThemeState(ErgoColors.midnight, ErgoColors.midnight, ThemeMode.dark);
  }
}

class ThemeController extends Notifier<AppThemeChoice> {
  static const _key = 'theme_choice';
  @override
  AppThemeChoice build() {
    final v = ref.read(sharedPrefsProvider).getString(_key);
    return AppThemeChoice.values.firstWhere((e) => e.name == v, orElse: () => AppThemeChoice.carbon);
  }

  Future<void> set(AppThemeChoice c) async {
    state = c;
    await ref.read(sharedPrefsProvider).setString(_key, c.name);
  }
}

final themeControllerProvider = NotifierProvider<ThemeController, AppThemeChoice>(ThemeController.new);
final themeStateProvider = Provider<ThemeState>((ref) => resolveTheme(ref.watch(themeControllerProvider)));
