import 'package:intl/intl.dart';

final _inr = NumberFormat.decimalPattern('en_IN');
String money(num v) => _inr.format(v);

/// ISO-8601 with the device's UTC offset, e.g. 2027-01-10T10:00:00+05:30
String isoWithOffset(DateTime d) {
  final o = d.timeZoneOffset;
  final sign = o.isNegative ? '-' : '+';
  final h = o.inHours.abs().toString().padLeft(2, '0');
  final m = (o.inMinutes.abs() % 60).toString().padLeft(2, '0');
  return '${DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(d)}$sign$h:$m';
}

String greeting() {
  final h = DateTime.now().hour;
  return h < 12 ? 'Good morning.' : (h < 17 ? 'Good afternoon.' : 'Good evening.');
}

String fmtDateTime(DateTime? d) => d == null ? '—' : DateFormat('d MMM, h:mm a').format(d.toLocal());
