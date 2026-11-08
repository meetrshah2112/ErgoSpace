import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/ergo_widgets.dart';
import '../../shared/data/repositories.dart';
import '../../shared/models/models.dart';
import 'booking_ticket.dart';
import 'customer_shell.dart';

enum _Mode { hourly, daily, monthly }

class BookingScreen extends ConsumerStatefulWidget {
  final int workspaceId;
  final int? initialSeatId;
  const BookingScreen({super.key, required this.workspaceId, this.initialSeatId});
  @override
  ConsumerState<BookingScreen> createState() => _BookingState();
}

class _BookingState extends ConsumerState<BookingScreen> {
  late final Razorpay _rz = Razorpay();
  Capacity? _cap;
  _Mode _mode = _Mode.hourly;
  late DateTime _start = _nextHour();
  int _count = 1;
  Map<String, dynamic>? _avail;
  Map<String, dynamic>? _booking; // server response after create-booking
  bool _checking = false, _creating = false, _paying = false;
  String? _error;
  String _wsName = '';

  static DateTime _nextHour() {
    final n = DateTime.now().add(const Duration(hours: 1));
    return DateTime(n.year, n.month, n.day, n.hour);
  }

  @override
  void initState() {
    super.initState();
    _rz.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess);
    _rz.on(Razorpay.EVENT_PAYMENT_ERROR, _onError);
  }

  @override
  void dispose() { _rz.clear(); super.dispose(); }

  DateTime get _end {
    switch (_mode) {
      case _Mode.hourly: return _start.add(Duration(hours: _count));
      case _Mode.daily: return _start.add(Duration(days: _count));
      case _Mode.monthly: return DateTime(_start.year, _start.month + _count, _start.day, _start.hour, _start.minute);
    }
  }

  List<_Mode> _modes(Capacity c) => [
        if (c.perHour != null) _Mode.hourly,
        if (c.perDay != null) _Mode.daily,
        if (c.perMonth != null) _Mode.monthly,
      ];

  void _invalidate() { _avail = null; _error = null; }

  double? _rate(Capacity c) => _mode == _Mode.hourly ? c.perHour : _mode == _Mode.daily ? c.perDay : c.perMonth;
  String get _perLabel => _mode == _Mode.hourly ? 'hr' : _mode == _Mode.daily ? 'day' : 'month';

  void _pickCap(Capacity c) {
    final m = _modes(c);
    setState(() { _cap = c; if (!m.contains(_mode) && m.isNotEmpty) _mode = m.first; _invalidate(); });
  }

  Future<void> _pickStart() async {
    final d = await showDatePicker(context: context, initialDate: _start, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_start));
    if (t == null) return;
    setState(() { _start = DateTime(d.year, d.month, d.day, t.hour, t.minute); _invalidate(); });
  }

  Future<void> _check() async {
    if (_cap == null || _checking) return;
    setState(() { _checking = true; _error = null; });
    try {
      final r = await ref.read(bookingRepoProvider).check(_cap!.id, isoWithOffset(_start), isoWithOffset(_end));
      if (mounted) setState(() { _avail = r; _checking = false; });
    } catch (e) {
      if (mounted) setState(() { _checking = false; _error = ApiException.from(e).message; });
    }
  }

  Future<void> _create() async {
    if (_creating || _booking != null || _cap == null) return;
    setState(() { _creating = true; _error = null; });
    try {
      final r = await ref.read(bookingRepoProvider).create(_cap!.id, isoWithOffset(_start), isoWithOffset(_end));
      if (mounted) setState(() { _booking = r; _creating = false; });
    } catch (e) {
      if (mounted) setState(() { _creating = false; _error = ApiException.from(e).message; });
    }
  }

  String? get _orderId => (_booking?['order_id'] ?? _booking?['razorpay_order_id'])?.toString();

  void _pay() {
    final key = (_booking?['key'] ?? ApiConfig.razorpayKey).toString();
    if (key.isEmpty) { setState(() => _error = 'Razorpay key missing. Run the app with --dart-define=RAZORPAY_KEY=rzp_test_…'); return; }
    if (_orderId == null) { setState(() => _error = 'The server did not return a payment order.'); return; }
    setState(() { _paying = true; _error = null; });
    try {
      _rz.open({'key': key, 'order_id': _orderId, 'name': 'ErgoSpace', 'description': _wsName, 'theme': {'color': '#C8FF45'}});
    } catch (e) {
      setState(() { _paying = false; _error = 'Could not open checkout.'; });
    }
  }

  Future<void> _onSuccess(PaymentSuccessResponse r) async {
    try {
      await ref.read(bookingRepoProvider).confirm(confirmPayload(
          orderId: r.orderId ?? _orderId ?? '', paymentId: r.paymentId ?? '', signature: r.signature ?? ''));
      ref.invalidate(myBookingsProvider);
      if (mounted) await _ticket();
    } catch (e) {
      ref.invalidate(myBookingsProvider);
      if (mounted) await _notice(Icons.hourglass_top_rounded, false, 'Payment pending confirmation', 'We could not verify your payment yet (${ApiException.from(e).message}). If money was debited, check Bookings shortly or contact support — do not pay again.');
    }
  }

  Future<void> _onError(PaymentFailureResponse r) async {
    if (!mounted) return;
    setState(() => _paying = false);
    final cancelled = r.code == Razorpay.PAYMENT_CANCELLED;
    await _notice(Icons.close_rounded, true, cancelled ? 'Payment cancelled' : 'Payment failed', cancelled ? 'No money was taken. You can retry from this screen.' : (r.message ?? 'The payment could not be completed. You can retry.'), stay: true);
  }

  void _goBookings(int tab) {
    ref.read(customerTabProvider.notifier).state = tab;
    context.go('/customer');
  }

  /// Success: a full-screen ticket that "prints" instead of a bottom sheet.
  Future<void> _ticket() {
    final cap = _cap;
    final rate = cap == null ? null : _rate(cap);
    final amount = double.tryParse('${_booking?['amount']}') ?? (rate == null ? null : rate * _count);
    final rawId = _booking?['id'];
    String code;
    if (rawId != null) {
      code = 'ERG-${rawId.toString().padLeft(6, '0')}';
    } else {
      final o = (_orderId ?? 'ERGOSPACE').toUpperCase();
      code = o.length > 10 ? o.substring(o.length - 10) : o;
    }
    final unit = _mode == _Mode.hourly ? 'hour' : _mode == _Mode.daily ? 'day' : 'month';
    final duration = '$_count $unit${_count == 1 ? '' : 's'}';
    return showBookingTicket(
      context,
      data: TicketData(workspace: _wsName, seat: cap?.name ?? 'Seat', reference: code, duration: duration, start: _start, end: _end, amount: amount),
      onViewBookings: () => _goBookings(2),
      onExplore: () => _goBookings(0),
    );
  }

  /// Failure / pending: a centred card (fade + scale) instead of a bottom sheet.
  Future<void> _notice(IconData icon, bool error, String title, String msg, {bool stay = false}) {
    final c = context.ergo;
    final col = error ? c.error : c.accent;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: c.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: BorderSide(color: c.border)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 64, height: 64, decoration: BoxDecoration(shape: BoxShape.circle, color: col.withOpacity(.12), border: Border.all(color: col, width: 1.5)), child: Icon(icon, color: col, size: 30)),
            const SizedBox(height: 18),
            Text(title, textAlign: TextAlign.center, style: serif(22)),
            const SizedBox(height: 8),
            Text(msg, textAlign: TextAlign.center, style: TextStyle(color: c.textSecondary, height: 1.45)),
            const SizedBox(height: 24),
            ErgoButton(stay ? 'Back to booking' : 'View my bookings', onPressed: () {
              Navigator.pop(ctx);
              if (!stay) _goBookings(2);
            }),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ergo;
    final ws = ref.watch(workspaceDetailProvider(widget.workspaceId));
    final locked = _booking != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Book a space')),
      body: ws.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(e, onRetry: () => ref.invalidate(workspaceDetailProvider(widget.workspaceId))),
        data: (w) {
          _wsName = w.name;
          if (_cap == null && widget.initialSeatId != null) {
            for (final x in w.capacities) {
              if (x.id == widget.initialSeatId) {
                _cap = x;
                final mm = _modes(x);
                if (mm.isNotEmpty) _mode = mm.first;
              }
            }
          }
          return ListView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 40), children: [
            Text(w.name, style: TextStyle(color: c.textSecondary)),
            const SizedBox(height: 20),
            Text('1  ·  CHOOSE A SEAT TYPE', style: labelStyle(context)), const SizedBox(height: 12),
            for (final cap in w.capacities)
              GestureDetector(
                onTap: locked ? null : () => _pickCap(cap),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: _cap?.id == cap.id ? c.accent : c.border, width: _cap?.id == cap.id ? 1.6 : 1)),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(cap.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      if (cap.description.isNotEmpty) Text(cap.description, style: TextStyle(color: c.textSecondary, fontSize: 12)),
                    ])),
                    Builder(builder: (_) {
                      final v = _rate(cap);
                      return v == null
                          ? Text('Not offered', style: TextStyle(color: c.muted, fontSize: 12))
                          : Price(v, per: _perLabel, size: 16);
                    }),
                  ]),
                ),
              ),
            if (_cap != null) ...[
              const SizedBox(height: 20),
              Text('2  ·  DURATION', style: labelStyle(context)), const SizedBox(height: 12),
              IgnorePointer(ignoring: locked, child: Segmented<_Mode>(
                options: [for (final m in _modes(_cap!)) (m, m == _Mode.hourly ? 'Hourly' : m == _Mode.daily ? 'Daily' : 'Monthly')],
                value: _mode, onChanged: (m) => setState(() { _mode = m; _invalidate(); }),
              )),
              const SizedBox(height: 20),
              Text('3  ·  WHEN', style: labelStyle(context)), const SizedBox(height: 12),
              GestureDetector(
                onTap: locked ? null : _pickStart,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(Rd.input), border: Border.all(color: c.border)),
                  child: Row(children: [
                    Icon(Icons.calendar_today_outlined, size: 18, color: c.accent), const SizedBox(width: 12),
                    Expanded(child: Text(fmtDateTime(_start), style: tabular(const TextStyle(fontWeight: FontWeight.w700)))),
                    Text('Change', style: TextStyle(color: c.textSecondary, fontSize: 12)),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Text(_mode == _Mode.hourly ? 'Hours' : _mode == _Mode.daily ? 'Days' : 'Months', style: TextStyle(color: c.textSecondary)),
                const Spacer(),
                _Stepper(value: _count, onChanged: locked ? null : (v) => setState(() { _count = v; _invalidate(); })),
              ]),
              const SizedBox(height: 8),
              Text('Ends  ${fmtDateTime(_end)}', style: tabular(TextStyle(color: c.muted, fontSize: 12))),
              if (_rate(_cap!) != null) ...[
                const SizedBox(height: 12),
                Row(children: [
                  Text('Estimated total', style: TextStyle(color: c.textSecondary)),
                  const Spacer(),
                  Price(_rate(_cap!)! * _count, size: 20),
                ]),
              ],
              const SizedBox(height: 24),
              if (!locked) ErgoButton('Check availability', secondary: true, loading: _checking, onPressed: _check),
              if (_avail != null) ...[const SizedBox(height: 16), _AvailabilityCard(_avail!)],
              if (_avail?['selected_slot_available'] == true && !locked) ...[
                const SizedBox(height: 16),
                ErgoButton('Reserve & continue', loading: _creating, onPressed: _create),
              ],
              if (locked) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: c.accent)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('BOOKING SUMMARY', style: labelStyle(context)), const SizedBox(height: 12),
                    Text('${_cap!.name} · ${w.name}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('${fmtDateTime(_start)} → ${fmtDateTime(_end)}', style: tabular(TextStyle(color: c.textSecondary, fontSize: 13))),
                    const SizedBox(height: 16),
                    if (double.tryParse('${_booking?['amount']}') != null) Price(double.parse('${_booking!['amount']}'), size: 30) else Text('Amount will be shown at checkout', style: TextStyle(color: c.textSecondary)),
                    const SizedBox(height: 4),
                    Text('Amount calculated by ErgoSpace', style: TextStyle(color: c.muted, fontSize: 11)),
                  ]),
                ),
                const SizedBox(height: 16),
                ErgoButton('Pay with Razorpay', icon: Icons.lock_outline_rounded, loading: _paying, onPressed: _pay),
              ],
              if (_error != null) ...[const SizedBox(height: 16), Text(_error!, style: TextStyle(color: c.error, height: 1.4))],
            ],
          ]);
        },
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int value;
  final ValueChanged<int>? onChanged;
  const _Stepper({required this.value, this.onChanged});
  @override
  Widget build(BuildContext context) {
    final c = context.ergo;
    Widget b(IconData i, VoidCallback? t) => GestureDetector(onTap: t, child: Container(width: 40, height: 40, decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)), child: Icon(i, size: 18, color: t == null ? c.muted : c.text)));
    return Row(children: [
      b(Icons.remove_rounded, onChanged == null || value <= 1 ? null : () => onChanged!(value - 1)),
      SizedBox(width: 48, child: Text('$value', textAlign: TextAlign.center, style: tabular(const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)))),
      b(Icons.add_rounded, onChanged == null || value >= 31 ? null : () => onChanged!(value + 1)),
    ]);
  }
}

class _AvailabilityCard extends StatelessWidget {
  final Map<String, dynamic> a;
  const _AvailabilityCard(this.a);
  String _flat(dynamic v) => v is List ? v.map(_flat).join(', ') : (v is Map ? v.values.map(_flat).join(' – ') : v.toString());
  @override
  Widget build(BuildContext context) {
    final c = context.ergo;
    final ok = a['selected_slot_available'] == true;
    final extras = <String, String>{
      'conflicting_hours': 'Conflicting hours', 'suggested_free_hours': 'Free hours',
      'busy_days': 'Busy days', 'suggested_free_days': 'Free days',
      'busy_months': 'Busy months', 'suggested_free_months': 'Free months',
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: ok ? c.success : c.error)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(ok ? Icons.check_circle_outline_rounded : Icons.block_rounded, color: ok ? c.success : c.error, size: 20), const SizedBox(width: 10),
          Text(ok ? 'This slot is available' : 'This slot is not available', style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
        for (final e in extras.entries)
          if (a[e.key] != null && _flat(a[e.key]).isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(e.value.toUpperCase(), style: labelStyle(context)), const SizedBox(height: 4),
            Text(_flat(a[e.key]), style: tabular(TextStyle(color: c.textSecondary, fontSize: 13, height: 1.4))),
          ],
      ]),
    );
  }
}
