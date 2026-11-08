import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/ergo_widgets.dart';
import '../../shared/data/repositories.dart';
import '../../shared/models/models.dart';
import '../auth/auth_controller.dart';
import '../customer/bookings_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.ergo;
    final s = ref.watch(authControllerProvider).valueOrNull;
    final ws = ref.watch(myWorkspacesProvider);
    final bk = ref.watch(myBookingsProvider);
    Future<void> refresh() async { ref.invalidate(myWorkspacesProvider); ref.invalidate(myBookingsProvider); }

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: c.accent, backgroundColor: c.surface, onRefresh: refresh,
        child: ListView(padding: const EdgeInsets.fromLTRB(24, 16, 24, 32), children: [
          const Wordmark(size: 16),
          const SizedBox(height: 28),
          Text(greeting().replaceAll('.', s != null && s.firstName.isNotEmpty ? ', ${s.firstName}.' : '.'), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text("Here's how your workspace business is performing.", style: TextStyle(color: c.textSecondary)),
          const SizedBox(height: 24),
          if (ws.hasError) ErrorView(ws.error!, compact: true, onRetry: refresh)
          else if (bk.hasError) ErrorView(bk.error!, compact: true, onRetry: refresh)
          else if (!ws.hasValue || !bk.hasValue) const _Loading()
          else ..._content(context, ws.value!, bk.value!),
        ]),
      ),
    );
  }

  List<Widget> _content(BuildContext context, List<Workspace> ws, List<Booking> bk) {
    final c = context.ergo;
    final now = DateTime.now();
    int n(BookingBucket b) => bk.where((x) => x.bucketAt(now) == b).length;
    final confirmed = bk.where((b) => b.isConfirmed).toList();
    final revenue = confirmed.fold<double>(0, (a, b) => a + (b.amount ?? 0));
    final completed = n(BookingBucket.completed) + n(BookingBucket.upcoming);
    final pending = n(BookingBucket.pending), failed = n(BookingBucket.failed);

    if (ws.isEmpty) {
      return [
        SizedBox(height: 380, child: EmptyView(
          title: 'Your workspace journey starts here.',
          message: 'List your first space and make it available to professionals around you.',
          actionLabel: 'Create workspace', onAction: () => context.push('/provider/create'), icon: Icons.add_business_outlined)),
      ];
    }
    final per = <String, int>{};
    for (final b in confirmed) { per[b.workspaceName] = (per[b.workspaceName] ?? 0) + 1; }
    final top = per.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return [
      GridView.count(
        crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.35,
        children: [
          _Metric('Workspaces', '${ws.length}'),
          _Metric('Total bookings', '${bk.length}'),
          _Metric('Confirmed', '$completed', accent: true),
          _Metric('Pending', '$pending'),
        ],
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: c.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('BOOKING REVENUE', style: labelStyle(context)), const SizedBox(height: 10),
          Price(revenue, size: 34),
          const SizedBox(height: 6),
          Text('Derived from the amounts on your confirmed bookings.', style: TextStyle(color: c.muted, fontSize: 11)),
        ]),
      ),
      const SizedBox(height: 28),
      const SectionHeader('Booking status'), const SizedBox(height: 14),
      _StatusBar(completed: completed, pending: pending, failed: failed),
      if (top.isNotEmpty) ...[
        const SizedBox(height: 28), const SectionHeader('Workspace performance'), const SizedBox(height: 14),
        for (final e in top.take(4)) Container(
          margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: c.border)),
          child: Row(children: [Expanded(child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w700))), Text('${e.value} booking${e.value == 1 ? '' : 's'}', style: tabular(TextStyle(color: c.accent, fontWeight: FontWeight.w700, fontSize: 13)))]),
        ),
      ],
      const SizedBox(height: 18), const SectionHeader('Recent bookings'), const SizedBox(height: 14),
      if (bk.isEmpty) Text('No bookings yet.', style: TextStyle(color: c.textSecondary))
      else for (final b in bk.take(5)) Padding(padding: const EdgeInsets.only(bottom: 12), child: BookingTile(b, showCustomer: true)),
      const SizedBox(height: 12),
      ErgoButton('Create workspace', icon: Icons.add_rounded, onPressed: () => context.push('/provider/create')),
    ];
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const Column(children: [
        Row(children: [Expanded(child: Skeleton(height: 100)), SizedBox(width: 12), Expanded(child: Skeleton(height: 100))]),
        SizedBox(height: 12),
        Row(children: [Expanded(child: Skeleton(height: 100)), SizedBox(width: 12), Expanded(child: Skeleton(height: 100))]),
        SizedBox(height: 12), Skeleton(height: 120),
      ]);
}

class _Metric extends StatelessWidget {
  final String label, value;
  final bool accent;
  const _Metric(this.label, this.value, {this.accent = false});
  @override
  Widget build(BuildContext context) {
    final c = context.ergo;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: c.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [Container(width: 6, height: 6, decoration: BoxDecoration(color: accent ? c.accent : c.muted, shape: BoxShape.circle)), const SizedBox(width: 8), Text(label.toUpperCase(), style: labelStyle(context))]),
        Text(value, style: tabular(TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: accent ? c.accent : c.text))),
      ]),
    );
  }
}

class _StatusBar extends StatelessWidget {
  final int completed, pending, failed;
  const _StatusBar({required this.completed, required this.pending, required this.failed});
  @override
  Widget build(BuildContext context) {
    final c = context.ergo;
    final total = completed + pending + failed;
    Widget seg(int v, Color col) => v == 0 ? const SizedBox.shrink() : Expanded(flex: v, child: Container(height: 10, margin: const EdgeInsets.only(right: 3), decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(3))));
    Widget legend(String t, int v, Color col) => Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: col, shape: BoxShape.circle)), const SizedBox(width: 6), Text('$t  $v', style: tabular(TextStyle(color: c.textSecondary, fontSize: 12)))]);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: c.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        total == 0 ? Text('No bookings to chart yet.', style: TextStyle(color: c.textSecondary)) : Row(children: [seg(completed, c.accent), seg(pending, c.muted), seg(failed, c.error)]),
        const SizedBox(height: 14),
        Wrap(spacing: 18, runSpacing: 8, children: [legend('Confirmed', completed, c.accent), legend('Pending', pending, c.muted), legend('Failed', failed, c.error)]),
      ]),
    );
  }
}
