import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/ergo_widgets.dart';
import '../settings/profile_screen.dart';
import 'bookings_screen.dart';
import 'home_screen.dart';
import 'search_screen.dart';

final customerTabProvider = StateProvider<int>((_) => 0);

class CustomerShell extends ConsumerWidget {
  const CustomerShell({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i = ref.watch(customerTabProvider);
    return Scaffold(
      body: IndexedStack(index: i, children: const [HomeScreen(), SearchScreen(), BookingsScreen(), ProfileScreen()]),
      bottomNavigationBar: ErgoNavBar(
        index: i,
        onTap: (v) => ref.read(customerTabProvider.notifier).state = v,
        items: const [
          ErgoNavItem(Icons.explore_outlined, 'Discover'),
          ErgoNavItem(Icons.search_rounded, 'Search'),
          ErgoNavItem(Icons.confirmation_number_outlined, 'Bookings'),
          ErgoNavItem(Icons.person_outline_rounded, 'Profile'),
        ],
      ),
    );
  }
}
