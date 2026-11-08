import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/auth_controller.dart';
import '../config/api_config.dart';
import '../storage/session_store.dart';

final sessionStoreProvider = Provider<SessionStore>((_) => SessionStore());

const noAuth = 'noAuth';

/// The backend's CustomTokenAuthentication reads the token from a cookie named
/// "Token". We send that cookie manually (Secure cookies are not persisted over
/// plain HTTP) and also the standard Authorization header, so the app keeps
/// working if the backend later accepts the header.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Accept': 'application/json'},
  ));
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (o, h) {
      final t = ref.read(sessionStoreProvider).token;
      if (t != null && o.extra[noAuth] != true) {
        o.headers['Cookie'] = 'Token=$t';
        o.headers['Authorization'] = 'Token $t';
      }
      h.next(o);
    },
    onError: (e, h) {
      if (e.response?.statusCode == 401 && e.requestOptions.extra[noAuth] != true) {
        ref.read(authControllerProvider.notifier).sessionExpired();
      }
      h.next(e);
    },
  ));
  return dio;
});
