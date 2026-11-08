import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'router.dart';

class ErgoApp extends ConsumerWidget {
  const ErgoApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(themeStateProvider);
    return MaterialApp.router(
      title: 'ErgoSpace',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(t.light),
      darkTheme: AppTheme.build(t.dark),
      themeMode: t.mode,
      themeAnimationDuration: const Duration(milliseconds: 250),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
