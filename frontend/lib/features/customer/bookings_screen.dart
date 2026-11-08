import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/ergo_widgets.dart';
import '../../shared/data/repositories.dart';
import '../../shared/models/models.dart';

Color bucketColor(BuildContext context, BookingBucket b) {
  final c = context.ergo;
  switch (b) {
    case BookingBucket.upcoming: return c.accent;
    case BookingBucket.completed: return c.success;
    case BookingBucket.pending: return c.textSecondary;
    case BookingBucket.failed: return c.error;
  }
}

/// Shared by customer ("Bookings") and provider ("Bookings") tabs.
class BookingsScreen extends ConsumerStatefulWidget {
  final bool provider;
  const BookingsScreen({super.key, this.provider = false});
  @override
  ConsumerState<BookingsScreen> createState() => _BookingsState();
}

class _BookingsState extends ConsumerState<BookingsScreen> {
  BookingBucket _tab = BookingBucket.upcoming;

  @override
  Widget build(BuildContext context) {
    final c = context.ergo;
    final res = ref.watch(myBookingsProvider);
    final now = DateTime.now();
    final tabs = widget.provider
        ? const [(BookingBucket.completed, 'Completed'), (BookingBucket.pending, 'Pending'), (BookingBucket.failed, 'Failed')]
        : const [(BookingBucket.upcoming, 'Upcoming'), (BookingBucket.completed, 'Completed'), (BookingBucket.pending, 'Pending'), (BookingBucket.failed, 'Failed')];
    if (!tabs.any((t) => t.$1 == _tab)) _tab = tabs.first.$1;
    return SafeArea(
      bottom: false,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(24, 16, 24, 16), child: Text(widget.provider ? 'Bookings' : 'My bookings', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800))),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Segmented<BookingBucket>(options: [for (final t in tabs) (t.$1, t.$2)], value: _tab, onChanged: (v) => setState(() => _tab = v))),
        const SizedBox(height: 16),
        Expanded(
          child: res.when(
            loading: () => ListView(padding: const EdgeInsets.symmetric(horizontal: 24), children: const [Skeleton(height: 110), SizedBox(height: 12), Skeleton(height: 110), SizedBox(height: 12), Skeleton(height: 110)]),
            error: (e, _) => ErrorView(e, onRetry: () => ref.invalidate(myBookingsProvider)),
            data: (all) {
              // Provider "Completed" = confirmed bookings (paid), regardless of date.
              final list = all.where((b) {
                final bk = b.bucketAt(now);
                if (widget.provider && _tab == BookingBucket.completed) return bk == BookingBucket.completed || bk == BookingBucket.upcoming;
                return bk == _tab;
              }).toList();
              return RefreshIndicator(
                color: c.accent, backgroundColor: c.surface,
                onRefresh: () async => ref.invalidate(myBookingsProvider),
                child: list.isEmpty
                    ? ListView(children: [SizedBox(height: 380, child: EmptyView(title: 'Nothing here yet', message: widget.provider ? 'Bookings made on your workspaces will appear here.' : 'Bookings in this state will appear here.', icon: Icons.confirmation_number_outlined))])
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32), itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => BookingTile(list[i], showCustomer: widget.provider),
                      ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class BookingTile extends StatelessWidget {
  final Booking b;
  final bool showCustomer;
  const BookingTile(this.b, {super.key, this.showCustomer = false});
  @override
  Widget build(BuildContext context) {
    final c = context.ergo;
    final col = bucketColor(context, b.bucketAt(DateTime.now()));
    return GestureDetector(
      onTap: () => showModalBottomSheet(context: context, builder: (_) => _Detail(b, showCustomer)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: c.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(b.workspaceName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
            Tag(b.status, color: col, filled: true),
          ]),
          const SizedBox(height: 4),
          Text(showCustomer ? '${b.seatName} · ${b.customer}' : b.seatName, style: TextStyle(color: c.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          Row(children: [
            Icon(Icons.schedule_rounded, size: 14, color: c.muted), const SizedBox(width: 6),
            Expanded(child: Text('${fmtDateTime(b.start)} → ${fmtDateTime(b.end)}', style: tabular(TextStyle(color: c.textSecondary, fontSize: 12)))),
            if (b.amount != null) Price(b.amount!, size: 16),
          ]),
        ]),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  final Booking b;
  final bool showCustomer;
  const _Detail(this.b, this.showCustomer);
  Widget _row(BuildContext context, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 110, child: Text(k.toUpperCase(), style: labelStyle(context))),
          Expanded(child: Text(v, style: tabular(const TextStyle(fontWeight: FontWeight.w600)))),
        ]),
      );
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(b.workspaceName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _row(context, 'Booking', '#${b.id}'),
          _row(context, 'Seat', b.seatName),
          if (showCustomer) _row(context, 'Customer', b.customer),
          _row(context, 'Starts', fmtDateTime(b.start)),
          _row(context, 'Ends', fmtDateTime(b.end)),
          if (b.amount != null) _row(context, 'Amount', '₹${money(b.amount!)}'),
          _row(context, 'Status', b.status),
          if (b.orderId != null) _row(context, 'Order', b.orderId!),
        ]),
      );
}
