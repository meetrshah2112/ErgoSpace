import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/ergo_widgets.dart';
import '../../shared/data/repositories.dart';
import '../auth/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.ergo;
    final res = ref.watch(profileProvider);
    return SafeArea(
      bottom: false,
      child: res.when(
        loading: () => ListView(padding: const EdgeInsets.all(24), children: const [Skeleton(height: 140, radius: 24), SizedBox(height: 16), Skeleton(height: 200)]),
        error: (e, _) => ErrorView(e, onRetry: () => ref.invalidate(profileProvider)),
        data: (p) {
          final first = '${p['first_name'] ?? ''}', last = '${p['last_name'] ?? ''}';
          final type = '${p['user_type'] ?? ''}';
          return ListView(padding: const EdgeInsets.fromLTRB(24, 16, 24, 32), children: [
            const Text('Profile', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            Container(
              height: 150, clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: c.border)),
              child: Stack(children: [
                const Positioned.fill(child: DotMatrix(spacing: 12)),
                Padding(padding: const EdgeInsets.all(20), child: Row(children: [
                  Container(width: 64, height: 64, alignment: Alignment.center, decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                      child: Text(first.isEmpty ? 'E' : first[0].toUpperCase(), style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: c.onAccent))),
                  const SizedBox(width: 16),
                  Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('$first $last'.trim(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('${p['email'] ?? ''}', style: TextStyle(color: c.textSecondary, fontSize: 13)),
                    const SizedBox(height: 8),
                    Tag(type == 'provider' ? 'Provider' : 'Customer', color: c.accent, filled: true),
                  ])),
                ])),
              ]),
            ),
            const SizedBox(height: 24),
            _Item(Icons.edit_outlined, 'Edit profile', () => showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => _EditSheet(p))),
            _Item(Icons.palette_outlined, 'Appearance', () => context.push('/appearance')),
            _Item(Icons.logout_rounded, 'Log out', () => _logout(context, ref), danger: true),
          ]);
        },
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Log out?'), content: const Text('You will need to sign in again to access your account.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Log out', style: TextStyle(color: context.ergo.error)))],
      ),
    );
    if (ok == true) await ref.read(authControllerProvider.notifier).logout();
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  const _Item(this.icon, this.label, this.onTap, {this.danger = false});
  @override
  Widget build(BuildContext context) {
    final c = context.ergo;
    return GestureDetector(
      onTap: onTap, behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: c.border)),
        child: Row(children: [
          Icon(icon, color: danger ? c.error : c.textSecondary), const SizedBox(width: 14),
          Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: danger ? c.error : c.text))),
          Icon(Icons.chevron_right_rounded, color: c.muted),
        ]),
      ),
    );
  }
}

class _EditSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> p;
  const _EditSheet(this.p);
  @override
  ConsumerState<_EditSheet> createState() => _EditState();
}

class _EditState extends ConsumerState<_EditSheet> {
  late final _f = TextEditingController(text: '${widget.p['first_name'] ?? ''}');
  late final _l = TextEditingController(text: '${widget.p['last_name'] ?? ''}');
  late final _e = TextEditingController(text: '${widget.p['email'] ?? ''}');
  bool _busy = false;
  String? _error;
  @override
  void dispose() { _f.dispose(); _l.dispose(); _e.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_busy) return;
    setState(() { _busy = true; _error = null; });
    try {
      await ref.read(authRepoProvider).updateProfile({'first_name': _f.text.trim(), 'last_name': _l.text.trim(), 'email': _e.text.trim()});
      ref.invalidate(profileProvider);
      if (mounted) { Navigator.pop(context); toast(context, 'Profile updated'); }
    } catch (e) {
      if (mounted) setState(() { _busy = false; _error = ApiException.from(e).message; });
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Edit profile', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          ErgoField(label: 'First name', controller: _f), const SizedBox(height: 12),
          ErgoField(label: 'Last name', controller: _l), const SizedBox(height: 12),
          ErgoField(label: 'Email', controller: _e, keyboard: TextInputType.emailAddress),
          if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: TextStyle(color: context.ergo.error))],
          const SizedBox(height: 20),
          ErgoButton('Save changes', loading: _busy, onPressed: _save),
        ]),
      );
}
