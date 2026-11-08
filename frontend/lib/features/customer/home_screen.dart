import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/ergo_widgets.dart';
import '../../core/widgets/workspace_card.dart';
import '../../shared/data/repositories.dart';
import '../auth/auth_controller.dart';
import 'customer_shell.dart';

const _all = WorkspaceQuery();
const _hot = WorkspaceQuery(type: 'Hotdesk');
const _teams = WorkspaceQuery(type: 'Workspace');

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.ergo;
    final session = ref.watch(authControllerProvider).valueOrNull;
    final popular = ref.watch(workspacesProvider(_all));
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: c.accent,
        backgroundColor: c.surface,
        onRefresh: () async {
          ref.invalidate(workspacesProvider);
          await ref.read(workspacesProvider(_all).future).catchError((_) => <dynamic>[] as dynamic);
        },
        child: ListView(padding: const EdgeInsets.only(bottom: 32), children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Row(children: [
              const Wordmark(size: 16),
              const Spacer(),
              GestureDetector(
                onTap: () => ref.read(customerTabProvider.notifier).state = 3,
                child: Container(
                  width: 40, height: 40, alignment: Alignment.center,
                  decoration: BoxDecoration(color: c.surface2, shape: BoxShape.circle, border: Border.all(color: c.border)),
                  child: Text((session?.firstName.isNotEmpty ?? false) ? session!.firstName[0].toUpperCase() : 'E', style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(greeting().replaceAll('.', session?.firstName.isNotEmpty == true ? ', ${session!.firstName}.' : '.'), style: TextStyle(color: c.textSecondary, fontSize: 15)),
              const SizedBox(height: 4),
              const Text('Where will you work today?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, height: 1.15)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Container(
              height: 190,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: c.border)),
              child: Stack(children: [
                const Positioned.fill(child: DotMatrix(spacing: 13)),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Your next great workspace is closer than you think.', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.2)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => ref.read(customerTabProvider.notifier).state = 1,
                      child: Container(
                        height: 52, padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
                        child: Row(children: [
                          Icon(Icons.search_rounded, color: c.accent),
                          const SizedBox(width: 12),
                          Text('Search spaces, areas, or locations', style: TextStyle(color: c.muted)),
                        ]),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
          popular.when(
            loading: () => const _RowSkeleton(),
            error: (e, _) => SizedBox(height: 260, child: ErrorView(e, onRetry: () => ref.invalidate(workspacesProvider))),
            data: (list) => list.isEmpty
                ? const SizedBox(height: 320, child: EmptyView(title: 'No workspaces yet', message: 'Spaces listed by providers will appear here.'))
                : Column(children: [
                    _Row(title: 'Popular workspaces', q: _all, section: 'pop'),
                    _Row(title: 'Hot desks', q: _hot, section: 'hot'),
                    _Row(title: 'Workspaces for teams', q: _teams, section: 'team'),
                  ]),
          ),
        ]),
      ),
    );
  }
}

class _RowSkeleton extends StatelessWidget {
  const _RowSkeleton();
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 300,
        child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 24), children: const [
          Skeleton(width: 270, height: 290, radius: 22), SizedBox(width: 16), Skeleton(width: 270, height: 290, radius: 22),
        ]),
      );
}

class _Row extends ConsumerWidget {
  final String title, section;
  final WorkspaceQuery q;
  const _Row({required this.title, required this.q, required this.section});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final res = ref.watch(workspacesProvider(q));
    return res.maybeWhen(
      data: (list) => list.isEmpty
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: SectionHeader(title, trailing: '${list.length}')),
                const SizedBox(height: 14),
                SizedBox(
                  height: 440,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (_, i) => SizedBox(
                      width: 300,
                      child: WorkspaceCard(list[i], section: section, expand: true, onTap: () => context.push('/customer/workspace/${list[i].id}?s=$section')),
                    ),
                  ),
                ),
              ]),
            ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}
