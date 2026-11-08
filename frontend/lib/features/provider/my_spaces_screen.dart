import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/ergo_widgets.dart';
import '../../shared/data/repositories.dart';
import '../../shared/models/models.dart';

class MySpacesScreen extends ConsumerWidget {
  const MySpacesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.ergo;
    final res = ref.watch(myWorkspacesProvider);
    return SafeArea(
      bottom: false,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Row(children: [
            const Expanded(child: Text('My spaces', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800))),
            GestureDetector(
              onTap: () => context.push('/provider/create'),
              child: Container(width: 44, height: 44, decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(14)), child: Icon(Icons.add_rounded, color: c.onAccent)),
            ),
          ]),
        ),
        Expanded(
          child: res.when(
            loading: () => ListView(padding: const EdgeInsets.symmetric(horizontal: 24), children: const [Skeleton(height: 120, radius: 22), SizedBox(height: 12), Skeleton(height: 120, radius: 22)]),
            error: (e, _) => ErrorView(e, onRetry: () => ref.invalidate(myWorkspacesProvider)),
            data: (list) => RefreshIndicator(
              color: c.accent, backgroundColor: c.surface,
              onRefresh: () async => ref.invalidate(myWorkspacesProvider),
              child: list.isEmpty
                  ? ListView(children: [SizedBox(height: 420, child: EmptyView(title: 'Your workspace journey starts here.', message: 'List your first space and make it available to professionals around you.', actionLabel: 'Create workspace', onAction: () => context.push('/provider/create'), icon: Icons.add_business_outlined))])
                  : ListView.separated(padding: const EdgeInsets.fromLTRB(24, 0, 24, 32), itemCount: list.length, separatorBuilder: (_, __) => const SizedBox(height: 12), itemBuilder: (_, i) => _SpaceTile(list[i])),
            ),
          ),
        ),
      ]),
    );
  }
}

class _SpaceTile extends ConsumerWidget {
  final Workspace w;
  const _SpaceTile(this.w);

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete ${w.name}?'),
        content: const Text('This permanently removes the listing. Records linked to it, such as capacity options and bookings, may also be affected according to the database relationships. This cannot be undone.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep')), TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: TextStyle(color: context.ergo.error)))],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(workspaceRepoProvider).delete(w.id);
      ref.invalidate(myWorkspacesProvider);
      if (context.mounted) toast(context, 'Workspace deleted');
    } catch (e) {
      if (context.mounted) toast(context, ApiException.from(e).message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.ergo;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: c.border)),
      child: Row(children: [
        SizedBox(width: 112, height: 132, child: ErgoImage(w.logo ?? w.cover)),
        Expanded(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Tag(w.type, color: c.accent, filled: true), const SizedBox(height: 8),
            Text(w.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 2),
            Text(w.city, style: TextStyle(color: c.textSecondary, fontSize: 13)),
            if (w.amenities.isNotEmpty) ...[const SizedBox(height: 6), Text(w.amenities.take(3).map((a) => a.name).join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.muted, fontSize: 12))],
          ]),
        )),
        IconButton(onPressed: () => _delete(context, ref), icon: Icon(Icons.delete_outline_rounded, color: c.error)),
      ]),
    );
  }
}
