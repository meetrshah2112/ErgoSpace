import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ergo_widgets.dart';
import '../../core/widgets/workspace_card.dart';
import '../../shared/data/repositories.dart';

final searchQueryProvider = StateProvider<WorkspaceQuery>((_) => const WorkspaceQuery());

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchState();
}

class _SearchState extends ConsumerState<SearchScreen> {
  final _ctl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() { _debounce?.cancel(); _ctl.dispose(); super.dispose(); }

  void _onText(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(searchQueryProvider.notifier).update((q) => q.copyWith(search: v));
    });
  }

  void _filters() {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => const _FilterSheet());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ergo;
    final q = ref.watch(searchQueryProvider);
    final res = ref.watch(workspacesProvider(q));
    final activeFilters = q.amenities.length;
    return SafeArea(
      bottom: false,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(padding: EdgeInsets.fromLTRB(24, 16, 24, 0), child: Text('Search', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800))),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _ctl, onChanged: _onText, textInputAction: TextInputAction.search,
              decoration: InputDecoration(hintText: 'Name, description or city', prefixIcon: Icon(Icons.search_rounded, color: c.muted)),
            )),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _filters,
              child: Container(
                width: 54, height: 54,
                decoration: BoxDecoration(color: activeFilters > 0 ? c.accent : c.surface2, borderRadius: BorderRadius.circular(Rd.input), border: Border.all(color: c.border)),
                child: Icon(Icons.tune_rounded, color: activeFilters > 0 ? c.onAccent : c.text),
              ),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Segmented<String?>(
            options: const [(null, 'All'), ('Workspace', 'Workspace'), ('Hotdesk', 'Hot desk')],
            value: q.type,
            onChanged: (v) => ref.read(searchQueryProvider.notifier).update((s) => v == null ? s.copyWith(clearType: true) : s.copyWith(type: v)),
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: res.when(
            loading: () => ListView(padding: const EdgeInsets.symmetric(horizontal: 24), children: const [Skeleton(height: 300, radius: 22), SizedBox(height: 16), Skeleton(height: 300, radius: 22)]),
            error: (e, _) => ErrorView(e, onRetry: () => ref.invalidate(workspacesProvider(q))),
            data: (list) => list.isEmpty
                ? EmptyView(
                    title: 'No spaces found',
                    message: q.isEmpty ? 'There are no workspaces to show yet.' : 'Try a different keyword or loosen your filters.',
                    actionLabel: q.isEmpty ? null : 'Clear filters',
                    onAction: () { _ctl.clear(); ref.read(searchQueryProvider.notifier).state = const WorkspaceQuery(); },
                    icon: Icons.search_off_rounded)
                : RefreshIndicator(
                    color: c.accent, backgroundColor: c.surface,
                    onRefresh: () async => ref.invalidate(workspacesProvider(q)),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                      itemCount: list.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (_, i) => i == 0
                          ? Row(children: [
                              Text('${list.length} ${list.length == 1 ? 'SPACE' : 'SPACES'}', style: labelStyle(context)),
                              const Spacer(),
                              if (!q.isEmpty) GestureDetector(onTap: () { _ctl.clear(); ref.read(searchQueryProvider.notifier).state = const WorkspaceQuery(); }, child: Text('Clear filters', style: TextStyle(color: c.accent, fontWeight: FontWeight.w700, fontSize: 12))),
                            ])
                          : WorkspaceCard(list[i - 1], section: 'search', onTap: () => context.push('/customer/workspace/${list[i - 1].id}?s=search')),
                    ),
                  ),
          ),
        ),
      ]),
    );
  }
}

class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.ergo;
    final q = ref.watch(searchQueryProvider);
    final am = ref.watch(amenitiesProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Amenities', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        am.when(
          loading: () => const Skeleton(height: 80),
          error: (e, _) => ErrorView(e, compact: true, onRetry: () => ref.invalidate(amenitiesProvider)),
          data: (list) => list.isEmpty
              ? Text('No amenities available.', style: TextStyle(color: c.textSecondary))
              : Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final a in list.where((a) => a.id != null))
                    GestureDetector(
                      onTap: () {
                        final s = {...q.amenities};
                        s.contains(a.id) ? s.remove(a.id) : s.add(a.id!);
                        ref.read(searchQueryProvider.notifier).update((x) => x.copyWith(amenities: s.toList()));
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: q.amenities.contains(a.id) ? c.accent : c.surface2,
                          borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
                        child: Text(a.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: q.amenities.contains(a.id) ? c.onAccent : c.text)),
                      ),
                    ),
                ]),
        ),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: ErgoButton('Reset', secondary: true, onPressed: () => ref.read(searchQueryProvider.notifier).update((x) => x.copyWith(amenities: [])))),
          const SizedBox(width: 12),
          Expanded(child: ErgoButton('Show results', onPressed: () => Navigator.pop(context))),
        ]),
      ]),
    );
  }
}
