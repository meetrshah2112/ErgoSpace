import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../../shared/data/repositories.dart';
import 'auth_models.dart';

class AuthController extends AsyncNotifier<AuthSession?> {
  @override
  Future<AuthSession?> build() => ref.read(sessionStoreProvider).read();

  Future<void> login(String email, String password) async {
    final s = await ref.read(authRepoProvider).login(email.trim(), password);
    await ref.read(sessionStoreProvider).save(s);
    state = AsyncData(s);
  }

  Future<void> register({required String first, required String last, required String email, required String password, required String userType}) async {
    await ref.read(authRepoProvider).register(first: first.trim(), last: last.trim(), email: email.trim(), password: password, userType: userType);
    await login(email, password);
  }

  Future<void> logout() async {
    try {
      await ref.read(authRepoProvider).logout();
    } catch (_) {/* clear locally regardless */}
    await ref.read(sessionStoreProvider).clear();
    state = const AsyncData(null);
  }

  Future<void> sessionExpired() async {
    if (state.valueOrNull == null) return;
    await ref.read(sessionStoreProvider).clear();
    state = const AsyncData(null);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthSession?>(AuthController.new);
