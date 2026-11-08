import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/network/dio_client.dart';
import '../../features/auth/auth_models.dart';
import '../models/models.dart';

class WorkspaceQuery {
  final String search;
  final String? type;
  final List<int> amenities;
  const WorkspaceQuery({this.search = '', this.type, this.amenities = const []});
  bool get isEmpty => search.trim().isEmpty && type == null && amenities.isEmpty;
  WorkspaceQuery copyWith({String? search, String? type, bool clearType = false, List<int>? amenities}) =>
      WorkspaceQuery(
        search: search ?? this.search,
        type: clearType ? null : (type ?? this.type),
        amenities: amenities ?? this.amenities,
      );
  Map<String, dynamic> toParams() => {
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (type != null) 'type': type,
        if (amenities.isNotEmpty) 'amenities': amenities,
      };
  @override
  bool operator ==(Object o) =>
      o is WorkspaceQuery && o.search == search && o.type == type && _eq(o.amenities, amenities);
  static bool _eq(List a, List b) => a.length == b.length && a.every(b.contains);
  @override
  int get hashCode => Object.hash(search, type, Object.hashAll(amenities));
}

/// Builds the body for POST /booking/confirm-booking/ – the backend expects a
/// field "response" holding a JSON-encoded string of the Razorpay callback.
Map<String, dynamic> confirmPayload({required String orderId, required String paymentId, required String signature}) => {
      'response': jsonEncode({
        'razorpay_order_id': orderId,
        'razorpay_payment_id': paymentId,
        'razorpay_signature': signature,
      }),
    };

class AuthRepository {
  final Dio _d;
  AuthRepository(this._d);
  final _noAuth = Options(extra: {noAuth: true});

  Future<AuthSession> login(String email, String password) => guard(() async {
        final r = await _d.post('/auth/login/', data: {'email': email, 'password': password}, options: _noAuth);
        return AuthSession.fromLogin(r.data as Map);
      });

  Future<void> register({required String first, required String last, required String email, required String password, required String userType}) =>
      guard(() => _d.post('/auth/register/',
          data: {'first_name': first, 'last_name': last, 'email': email, 'password': password, 'user_type': userType},
          options: _noAuth));

  Future<void> logout() => guard(() => _d.post('/auth/logout/'));

  Future<Map<String, dynamic>> profile() =>
      guard(() async => Map<String, dynamic>.from((await _d.get('/auth/profile/')).data as Map));

  Future<void> updateProfile(Map<String, dynamic> data) => guard(() => _d.patch('/auth/profile/update/', data: data));
}

class WorkspaceRepository {
  final Dio _d;
  WorkspaceRepository(this._d);

  Future<List<Workspace>> list(WorkspaceQuery q) => guard(() async {
        final r = q.isEmpty ? await _d.get('/workspace/') : await _d.get('/workspace/search/', queryParameters: q.toParams());
        return extractList(r.data).whereType<Map>().map(Workspace.fromJson).toList();
      });

  Future<Workspace> detail(int id) => guard(() async => Workspace.fromJson((await _d.get('/workspace/$id/')).data as Map));

  Future<List<Amenity>> amenities() => guard(() async =>
      extractList((await _d.get('/workspace/amenities/')).data).map(Amenity.from).toList());

  Future<List<Workspace>> mine() => guard(() async =>
      extractList((await _d.get('/workspace/new-workspace/')).data).whereType<Map>().map(Workspace.fromJson).toList());

  Future<void> create(FormData fd) => guard(() => _d.post('/workspace/new-workspace/', data: fd));
  Future<void> delete(int id) => guard(() => _d.delete('/workspace/$id/delete/'));

  Future<void> review(int workspaceId, int rating, String text) =>
      guard(() => _d.post('/workspace/reviews/', data: {'Workspace': workspaceId, 'rating': rating, 'review': text}));
}

class BookingRepository {
  final Dio _d;
  BookingRepository(this._d);

  Future<Map<String, dynamic>> check(int seatId, String start, String end) => guard(() async => Map<String, dynamic>.from(
      (await _d.post('/booking/check-availability/', data: {'seat_id': seatId, 'start_time': start, 'end_time': end})).data as Map));

  Future<Map<String, dynamic>> create(int seatId, String start, String end) => guard(() async => Map<String, dynamic>.from(
      (await _d.post('/booking/create-booking/', data: {'seat': seatId, 'start_time': start, 'end_time': end})).data as Map));

  Future<void> confirm(Map<String, dynamic> payload) => guard(() => _d.post('/booking/confirm-booking/', data: payload));

  Future<List<Booking>> mine() => guard(() async {
        final list = extractList((await _d.get('/booking/mybookings/')).data).whereType<Map>().map(Booking.fromJson).toList();
        list.sort((a, b) => (b.start ?? DateTime(0)).compareTo(a.start ?? DateTime(0)));
        return list;
      });
}

final authRepoProvider = Provider((r) => AuthRepository(r.watch(dioProvider)));
final workspaceRepoProvider = Provider((r) => WorkspaceRepository(r.watch(dioProvider)));
final bookingRepoProvider = Provider((r) => BookingRepository(r.watch(dioProvider)));

final workspacesProvider = FutureProvider.family<List<Workspace>, WorkspaceQuery>((ref, q) => ref.watch(workspaceRepoProvider).list(q));
final workspaceDetailProvider = FutureProvider.autoDispose.family<Workspace, int>((ref, id) => ref.watch(workspaceRepoProvider).detail(id));
final amenitiesProvider = FutureProvider<List<Amenity>>((ref) => ref.watch(workspaceRepoProvider).amenities());
final myWorkspacesProvider = FutureProvider.autoDispose<List<Workspace>>((ref) => ref.watch(workspaceRepoProvider).mine());
final myBookingsProvider = FutureProvider.autoDispose<List<Booking>>((ref) => ref.watch(bookingRepoProvider).mine());
final profileProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) => ref.watch(authRepoProvider).profile());
