import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

/// Chooser for the admin "add" button on the Home tab.
///
/// Returns true if whatever the admin picked was actually created, so the
/// caller knows whether to refresh.
Future<bool> showAdminAddSheet(BuildContext context) async {
  final created = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AdminAddSheet(),
  );
  return created == true;
}

class _AdminAddSheet extends StatelessWidget {
  const _AdminAddSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Add',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _Option(
              icon: Icons.event_outlined,
              title: 'Schedule',
              subtitle: 'A trip passengers can book',
              route: '/staff/schedules/new',
            ),
            _Option(
              icon: Icons.train_outlined,
              title: 'Train',
              subtitle: 'A train that schedules run on',
              route: '/staff/trains/new',
            ),
            _Option(
              icon: Icons.location_on_outlined,
              title: 'Station',
              subtitle: 'A stop routes can run between',
              route: '/staff/stations/new',
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  const _Option({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: AppColors.textSecondary)),
      onTap: () async {
        // Close the sheet first, then push, so the created flag flows back to
        // the Home tab rather than being swallowed by the sheet.
        final navigator = Navigator.of(context);
        final created = await context.push<bool>(route);
        navigator.pop(created == true);
      },
    );
  }
}
