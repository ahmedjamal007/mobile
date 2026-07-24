import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../state/auth_provider.dart';
import '../../state/notifications_provider.dart';
import '../profile/profile_screen.dart';
import '../reservations/reservations_screen.dart';
import '../schedules/schedules_screen.dart';
import '../staff/review_queue_screen.dart';
import '../tickets/tickets_screen.dart';

/// Bottom-nav container. Tab set depends on role: staff/admin get an extra
/// "Review" tab for the payment queue. The notifications bell (with unread
/// badge) lives in each tab's app bar.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Kick off notification polling once the shell is up.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsProvider>().start();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isStaff = context.watch<AuthProvider>().isStaff;

    final tabs = <_TabDef>[
      const _TabDef('Home', Icons.explore_outlined, Icons.explore, SchedulesScreen()),
      const _TabDef('Trips', Icons.event_seat_outlined, Icons.event_seat,
          ReservationsScreen()),
      const _TabDef('Tickets', Icons.confirmation_number_outlined,
          Icons.confirmation_number, TicketsScreen()),
      if (isStaff)
        const _TabDef('Review', Icons.fact_check_outlined, Icons.fact_check,
            ReviewQueueScreen(embedded: true)),
      const _TabDef('Profile', Icons.person_outline, Icons.person,
          ProfileScreen()),
    ];

    final safeIndex = _index.clamp(0, tabs.length - 1);

    return Scaffold(
      appBar: AppBar(
        title: Text(tabs[safeIndex].label == 'Home'
            ? 'Sudan Railways'
            : tabs[safeIndex].label),
        actions: [const _NotificationsBell()],
      ),
      body: IndexedStack(
        index: safeIndex,
        children: tabs.map((t) => t.screen).toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIndex,
        onTap: (i) => setState(() => _index = i),
        items: [
          for (final t in tabs)
            BottomNavigationBarItem(
              icon: Icon(t.icon),
              activeIcon: Icon(t.activeIcon),
              label: t.label,
            ),
        ],
      ),
    );
  }
}

class _TabDef {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget screen;
  const _TabDef(this.label, this.icon, this.activeIcon, this.screen);
}

class _NotificationsBell extends StatelessWidget {
  const _NotificationsBell();

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationsProvider>().unread;
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => context.push('/notifications'),
        ),
        if (unread > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: Text(
                unread > 9 ? '9+' : '$unread',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
