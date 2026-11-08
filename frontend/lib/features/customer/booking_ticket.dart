import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/ergo_widgets.dart';

class TicketData {
  final String workspace, seat, reference, duration;
  final DateTime start, end;
  final double? amount;
  const TicketData({
    required this.workspace,
    required this.seat,
    required this.reference,
    required this.duration,
    required this.start,
    required this.end,
    this.amount,
  });
}

/// Full-screen confirmation: the ticket "prints" out of a slot.
Future<void> showBookingTicket(
  BuildContext context, {
  required TicketData data,
  required VoidCallback onViewBookings,
  required VoidCallback onExplore,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Booking confirmed',
    barrierColor: Colors.black,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (ctx, _, __) => _TicketOverlay(
      data: data,
      onViewBookings: () { Navigator.of(ctx).pop(); onViewBookings(); },
      onExplore: () { Navigator.of(ctx).pop(); onExplore(); },
    ),
    transitionBuilder: (ctx, a, _, child) => FadeTransition(opacity: CurvedAnimation(parent: a, curve: Curves.easeOut), child: child),
  );
}

class _TicketOverlay extends StatefulWidget {
  final TicketData data;
  final VoidCallback onViewBookings, onExplore;
  const _TicketOverlay({required this.data, required this.onViewBookings, required this.onExplore});
  @override
  State<_TicketOverlay> createState() => _TicketOverlayState();
}

class _TicketOverlayState extends State<_TicketOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
  late final Animation<double> _slide = CurvedAnimation(parent: _c, curve: const Interval(0.1, 0.85, curve: Curves.easeInOutCubic));
  late final Animation<double> _fade = CurvedAnimation(parent: _c, curve: const Interval(0.8, 1.0, curve: Curves.easeOut));
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 350), () { if (mounted) _c.forward(); });
    var n = 0;
    _tick = Timer.periodic(const Duration(milliseconds: 120), (t) {
      if (_c.value > 0 && n < 12) { HapticFeedback.selectionClick(); n++; }
      if (n >= 12) t.cancel();
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ergo;
    return Material(
      color: c.bg,
      child: Stack(children: [
        const Positioned(top: 0, left: 0, right: 0, height: 320, child: DotMatrix(spacing: 16)),
        SafeArea(
          child: Column(children: [
            Expanded(child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
              child: Column(children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.elasticOut,
                  builder: (_, v, child) => Transform.scale(scale: v, child: child),
                  child: Container(width: 58, height: 58, decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle), child: Icon(Icons.check_rounded, size: 32, color: c.onAccent)),
                ),
                const SizedBox(height: 18),
                Text('Booking confirmed', style: serif(28)),
                const SizedBox(height: 6),
                Text('Your seat is reserved. Show this ticket at the entrance.', textAlign: TextAlign.center, style: TextStyle(color: c.textSecondary, height: 1.45)),
                const SizedBox(height: 28),
                Stack(clipBehavior: Clip.none, children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: ClipRect(
                      child: AnimatedBuilder(
                        animation: _slide,
                        builder: (_, child) => FractionalTranslation(translation: Offset(0, _slide.value - 1), child: child),
                        child: _Ticket(data: widget.data),
                      ),
                    ),
                  ),
                  Positioned(top: 0, left: -8, right: -8, child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: c.elevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: c.border),
                      boxShadow: [BoxShadow(color: c.accent.withOpacity(.35), blurRadius: 16)],
                    ),
                  )),
                ]),
              ]),
            )),
            FadeTransition(
              opacity: _fade,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  ErgoButton('View my bookings', icon: Icons.confirmation_number_outlined, onPressed: widget.onViewBookings),
                  const SizedBox(height: 6),
                  TextButton(onPressed: widget.onExplore, child: Text('Back to explore', style: TextStyle(color: c.textSecondary, fontWeight: FontWeight.w700))),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _Ticket extends StatelessWidget {
  final TicketData data;
  const _Ticket({required this.data});

  @override
  Widget build(BuildContext context) {
    final c = context.ergo;
    final bg = c.text;                       // paper
    final fg = c.bg;                         // ink
    final sub = c.bg.withOpacity(.55);
    final d = data;
    final dateFmt = DateFormat('EEE, d MMM');
    final timeFmt = DateFormat('h:mm a');

    Widget label(String t) => Text(t, style: TextStyle(fontSize: 10, letterSpacing: 1.4, fontWeight: FontWeight.w700, color: sub));
    Widget when(String l, DateTime t, {bool end = false}) => Column(
          crossAxisAlignment: end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            label(l), const SizedBox(height: 6),
            Text(dateFmt.format(t.toLocal()), style: tabular(TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: fg))),
            const SizedBox(height: 2),
            Text(timeFmt.format(t.toLocal()), style: tabular(TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: sub))),
          ],
        );
    Widget kv(String l, String v, {bool bold = false}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          label(l), const SizedBox(height: 5),
          Text(v, maxLines: 1, overflow: TextOverflow.ellipsis, style: tabular(TextStyle(fontSize: bold ? 17 : 14, fontWeight: FontWeight.w800, color: fg))),
        ]);

    final top = ClipPath(
      clipper: const _PartClipper(_Part.top),
      child: Container(
        color: bg,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(height: 6, color: c.accent),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Image.asset('assets/images/logo.png', width: 22, height: 22, fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(width: 10, height: 10, decoration: BoxDecoration(color: fg, shape: BoxShape.circle))),
                const SizedBox(width: 8),
                Text('ERGOSPACE', style: TextStyle(fontSize: 11, letterSpacing: 2.4, fontWeight: FontWeight.w800, color: fg)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: fg, borderRadius: BorderRadius.circular(20)),
                  child: Text('CONFIRMED', style: TextStyle(fontSize: 9.5, letterSpacing: 1.3, fontWeight: FontWeight.w800, color: c.accent)),
                ),
              ]),
              const SizedBox(height: 24),
              label('WORKSPACE'), const SizedBox(height: 6),
              Text(d.workspace, maxLines: 2, overflow: TextOverflow.ellipsis, style: serif(26, color: fg, height: 1.1)),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.event_seat_outlined, size: 16, color: sub), const SizedBox(width: 6),
                Expanded(child: Text(d.seat, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: sub))),
              ]),
              const SizedBox(height: 24),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: when('CHECK-IN', d.start)),
                Padding(padding: const EdgeInsets.fromLTRB(8, 18, 8, 0), child: Icon(Icons.east_rounded, size: 18, color: sub)),
                Expanded(child: when('CHECK-OUT', d.end, end: true)),
              ]),
            ]),
          ),
        ]),
      ),
    );

    final mid = ClipPath(
      clipper: const _PartClipper(_Part.mid),
      child: Container(color: bg, height: 28, child: CustomPaint(painter: _DashPainter(fg.withOpacity(.28)))),
    );

    final bottom = ClipPath(
      clipper: const _PartClipper(_Part.bottom),
      child: Container(
        color: bg,
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: kv('DURATION', d.duration)),
            Expanded(child: kv('AMOUNT PAID', d.amount == null ? '—' : '₹${money(d.amount!)}', bold: true)),
            Expanded(child: kv('STATUS', 'Paid')),
          ]),
          const SizedBox(height: 20),
          SizedBox(height: 46, width: double.infinity, child: CustomPaint(painter: _BarcodePainter(d.reference, fg))),
          const SizedBox(height: 10),
          Center(child: Text(d.reference, style: TextStyle(fontSize: 11, letterSpacing: 4, fontWeight: FontWeight.w700, color: sub))),
        ]),
      ),
    );

    return Column(mainAxisSize: MainAxisSize.min, children: [top, mid, bottom]);
  }
}

enum _Part { top, mid, bottom }

class _PartClipper extends CustomClipper<Path> {
  final _Part part;
  const _PartClipper(this.part);
  static const double _r = 26, _n = 13;

  @override
  Path getClip(Size s) {
    final rect = Offset.zero & s;
    switch (part) {
      case _Part.top:
        return Path()..addRRect(RRect.fromRectAndCorners(rect, topLeft: const Radius.circular(_r), topRight: const Radius.circular(_r)));
      case _Part.bottom:
        return Path()..addRRect(RRect.fromRectAndCorners(rect, bottomLeft: const Radius.circular(_r), bottomRight: const Radius.circular(_r)));
      case _Part.mid:
        final holes = Path()
          ..addOval(Rect.fromCircle(center: Offset(0, s.height / 2), radius: _n))
          ..addOval(Rect.fromCircle(center: Offset(s.width, s.height / 2), radius: _n));
        return Path.combine(PathOperation.difference, Path()..addRect(rect), holes);
    }
  }

  @override
  bool shouldReclip(covariant _PartClipper old) => old.part != part;
}

class _DashPainter extends CustomPainter {
  final Color color;
  _DashPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..strokeWidth = 1.5..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    double x = 22;
    while (x < size.width - 22) {
      canvas.drawLine(Offset(x, y), Offset(x + 6, y), p);
      x += 12;
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

class _BarcodePainter extends CustomPainter {
  final String seed;
  final Color color;
  _BarcodePainter(this.seed, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    var s = seed.codeUnits.fold<int>(7, (a, b) => (a * 31 + b) & 0x7fffffff);
    final p = Paint()..color = color;
    double x = 0;
    while (x < size.width) {
      s = (s * 1103515245 + 12345) & 0x7fffffff;
      final w = 1.0 + ((s >> 16) % 3);
      final gap = 1.5 + ((s >> 8) % 3);
      if (x + w > size.width) break;
      canvas.drawRect(Rect.fromLTWH(x, 0, w, size.height), p);
      x += w + gap;
    }
  }

  @override
  bool shouldRepaint(_BarcodePainter old) => old.seed != seed || old.color != color;
}
