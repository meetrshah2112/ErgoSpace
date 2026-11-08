import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../features/auth/auth_models.dart';

class SessionStore {
  final _s = const FlutterSecureStorage();
  String? _token;
  String? get token => _token;

  Future<AuthSession?> read() async {
    final t = await _s.read(key: 'token');
    if (t == null || t.isEmpty) return null;
    _token = t;
    return AuthSession(
      token: t,
      id: int.tryParse(await _s.read(key: 'uid') ?? ''),
      name: await _s.read(key: 'name') ?? '',
      userType: await _s.read(key: 'utype') ?? 'customer',
    );
  }

  Future<void> save(AuthSession s) async {
    _token = s.token;
    await _s.write(key: 'token', value: s.token);
    await _s.write(key: 'uid', value: '${s.id ?? ''}');
    await _s.write(key: 'name', value: s.name);
    await _s.write(key: 'utype', value: s.userType);
  }

  Future<void> clear() async {
    _token = null;
    await _s.deleteAll();
  }
}
