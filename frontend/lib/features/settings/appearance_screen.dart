import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cur = ref.watch(themeControllerProvider);
    final c = context.ergo;
    final items = <(AppThemeChoice, String, String, List<ErgoColors>)>[
      (AppThemeChoice.system, 'System default', 'Follows your device (Porcelain / Carbon)', [ErgoColors.porcelain, ErgoColors.carbon]),
      (AppThemeChoice.light, 'Light mode', 'Porcelain / Ink', [ErgoColors.porcelain]),
      (AppThemeChoice.dark, 'Dark mode', 'Carbon / Electric Lime', [ErgoColors.carbon]),
      (AppThemeChoice.carbon, 'Carbon / Electric Lime', 'The ErgoSpace signature', [ErgoColors.carbon]),
      (AppThemeChoice.porcelain, 'Porcelain / Ink', 'Premium light theme', [ErgoColors.porcelain]),
      (AppThemeChoice.midnight, 'Midnight / Electric Ice', 'Cool alternative dark theme', [ErgoColors.midnight]),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: ListView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 32), children: [
        for (final t in items)
          GestureDetector(
            onTap: () => ref.read(themeControllerProvider.notifier).set(t.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: cur == t.$1 ? c.accent : c.border, width: cur == t.$1 ? 1.6 : 1)),
              child: Row(children: [
                SizedBox(width: 56, height: 40, child: Row(children: [
                  for (final p in t.$4) Expanded(child: Container(
                    decoration: BoxDecoration(color: p.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: p.border)),
                    child: Align(alignment: Alignment.bottomRight, child: Padding(padding: const EdgeInsets.all(6), child: Container(width: 10, height: 10, decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle)))),
                  )),
                ])),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.$2, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(t.$3, style: TextStyle(color: c.textSecondary, fontSize: 12)),
                ])),
                if (cur == t.$1) Icon(Icons.check_circle_rounded, color: c.accent),
              ]),
            ),
          ),
      ]),
    );
  }
}
