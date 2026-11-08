import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/auth_screens.dart';
import 'features/customer/booking_flow.dart';
import 'features/customer/customer_shell.dart';
import 'features/customer/workspace_details.dart';
import 'features/provider/create_workspace.dart';
import 'features/provider/provider_shell.dart';
import 'features/settings/appearance_screen.dart';

CustomTransitionPage<void> _page(Widget child, GoRouterState s) => CustomTransitionPage<void>(
      key: s.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (c, a, _, w) {
        final curve = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curve,
          child: SlideTransition(position: Tween(begin: const Offset(0, .03), end: Offset.zero).animate(curve), child: w),
        );
      },
    );

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (ctx, st) {
      final auth = ref.read(authControllerProvider);
      final loc = st.matchedLocation;
      if (auth.isLoading) return loc == '/splash' ? null : '/splash';
      final s = auth.valueOrNull;
      const public = ['/welcome', '/login', '/register'];
      if (s == null) return public.contains(loc) ? null : '/welcome';
      final home = s.isProvider ? '/provider' : '/customer';
      if (public.contains(loc) || loc == '/splash' || loc == '/') return home;
      // Role guards (UI-level only; the backend remains the authority).
      if (s.isProvider && loc.startsWith('/customer')) return home;
      if (!s.isProvider && loc.startsWith('/provider')) return home;
      return null;
    },
    routes: [
      GoRoute(path: '/splash', pageBuilder: (c, s) => _page(const SplashScreen(), s)),
      GoRoute(path: '/welcome', pageBuilder: (c, s) => _page(const WelcomeScreen(), s)),
      GoRoute(path: '/login', pageBuilder: (c, s) => _page(const LoginScreen(), s)),
      GoRoute(path: '/register', pageBuilder: (c, s) => _page(RegisterScreen(initialType: s.uri.queryParameters['type'] ?? 'customer'), s)),
      GoRoute(path: '/customer', pageBuilder: (c, s) => _page(const CustomerShell(), s), routes: [
        GoRoute(path: 'workspace/:id', pageBuilder: (c, s) => _page(WorkspaceDetailsScreen(id: int.parse(s.pathParameters['id']!), heroSection: s.uri.queryParameters['s'] ?? 'list'), s)),
        GoRoute(path: 'book/:id', pageBuilder: (c, s) => _page(BookingScreen(workspaceId: int.parse(s.pathParameters['id']!), initialSeatId: int.tryParse(s.uri.queryParameters['seat'] ?? '')), s)),
      ]),
      GoRoute(path: '/provider', pageBuilder: (c, s) => _page(const ProviderShell(), s), routes: [
        GoRoute(path: 'create', pageBuilder: (c, s) => _page(const CreateWorkspaceScreen(), s)),
      ]),
      GoRoute(path: '/appearance', pageBuilder: (c, s) => _page(const AppearanceScreen(), s)),
    ],
  );
});
