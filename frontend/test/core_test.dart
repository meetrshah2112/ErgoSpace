import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:ergospace/core/network/api_exceptions.dart';
import 'package:ergospace/core/theme/theme_controller.dart';
import 'package:ergospace/core/utils/format.dart';
import 'package:ergospace/features/auth/auth_models.dart';
import 'package:ergospace/features/provider/workspace_payload.dart';
import 'package:ergospace/shared/data/repositories.dart';
import 'package:ergospace/shared/models/models.dart';
import 'package:flutter/material.dart';

void main() {
  test('login parsing is case-insensitive and detects role', () {
    final s = AuthSession.fromLogin({'Token': 'abc', 'Full_name': 'Meet Shah', 'username': 'm', 'user_type': 'provider', 'id': 4});
    expect(s.token, 'abc');
    expect(s.isProvider, true);
    expect(s.firstName, 'Meet');
  });

  test('confirm payload wraps razorpay fields as JSON string in "response"', () {
    final p = confirmPayload(orderId: 'o', paymentId: 'p', signature: 's');
    expect(p.keys, ['response']);
    expect(jsonDecode(p['response'] as String), {'razorpay_order_id': 'o', 'razorpay_payment_id': 'p', 'razorpay_signature': 's'});
  });

  test('search params only include set filters', () {
    expect(const WorkspaceQuery().isEmpty, true);
    final q = const WorkspaceQuery(search: ' cafe ', type: 'Hotdesk', amenities: [1, 2]);
    expect(q.toParams(), {'search': 'cafe', 'type': 'Hotdesk', 'amenities': [1, 2]});
  });

  test('booking buckets follow status strings', () {
    Booking b(String s, DateTime end) => Booking(id: 1, workspaceName: 'w', seatName: 's', status: s, customer: 'c', end: end);
    final now = DateTime(2027, 1, 1);
    expect(b('Failed', now).bucketAt(now), BookingBucket.failed);
    expect(b('Pending', now).bucketAt(now), BookingBucket.pending);
    expect(b('Paid', now.add(const Duration(days: 1))).bucketAt(now), BookingBucket.upcoming);
    expect(b('Paid', now.subtract(const Duration(days: 1))).bucketAt(now), BookingBucket.completed);
  });

  test('workspace parses PostGIS-style location defensively', () {
    final w = Workspace.fromJson({'id': 1, 'name': 'A', 'workspace_type': 'Hotdesk', 'location': 'SRID=4326;POINT (72.8777 19.076)'});
    expect(w.lat, 19.076);
    expect(w.lon, 72.8777);
  });

  test('capacity JSON built for multipart omits blank rates', () {
    final c = CapacityDraft(name: 'Desk', capacity: 5, perHour: 100);
    expect(c.toJson().containsKey('rate_per_day'), false);
    expect(c.toJson()['rate_per_hour'], 100);
  });

  test('iso timestamps carry a UTC offset', () {
    expect(RegExp(r'^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d[+-]\d\d:\d\d$').hasMatch(isoWithOffset(DateTime(2027, 1, 10, 10))), true);
  });

  test('theme choices resolve to modes', () {
    expect(resolveTheme(AppThemeChoice.system).mode, ThemeMode.system);
    expect(resolveTheme(AppThemeChoice.midnight).mode, ThemeMode.dark);
    expect(resolveTheme(AppThemeChoice.porcelain).mode, ThemeMode.light);
  });

  test('field validation errors are surfaced', () {
    const e = ApiException('x', status: 400, fieldErrors: {'email': 'bad'});
    expect(e.fieldErrors['email'], 'bad');
  });
}
