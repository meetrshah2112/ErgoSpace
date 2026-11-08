import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/ergo_widgets.dart';
import '../customer/bookings_screen.dart';
import '../settings/profile_screen.dart';
import 'dashboard_screen.dart';
import 'my_spaces_screen.dart';

final providerTabProvider = StateProvider<int>((_) => 0);

class ProviderShell extends ConsumerWidget {
  const ProviderShell({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i = ref.watch(providerTabProvider);
    return Scaffold(
      body: IndexedStack(index: i, children: const [DashboardScreen(), MySpacesScreen(), BookingsScreen(provider: true), ProfileScreen()]),
      bottomNavigationBar: ErgoNavBar(
        index: i,
        onTap: (v) => ref.read(providerTabProvider.notifier).state = v,
        items: const [
          ErgoNavItem(Icons.space_dashboard_outlined, 'Overview'),
          ErgoNavItem(Icons.apartment_rounded, 'My Spaces'),
          ErgoNavItem(Icons.receipt_long_outlined, 'Bookings'),
          ErgoNavItem(Icons.person_outline_rounded, 'Profile'),
        ],
      ),
    );
  }
}
