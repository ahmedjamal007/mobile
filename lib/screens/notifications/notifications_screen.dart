import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/enums/app_enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/ui_helpers.dart';
import '../../models/app_notification.dart';
import '../../state/notifications_provider.dart';
import '../../widgets/state_views.dart';

/// Polling-based inbox (§5.8 / §8). Newest first; tap to mark read; a header
/// action marks all read.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationsProvider>();
    final items = provider.items;
    final hasUnread = provider.unread > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: () async {
                await context.read<NotificationsProvider>().markAllRead();
                if (context.mounted) {
                  Toast.info(context, 'All notifications marked as read.');
                }
              },
              child: const Text('Mark all read',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<NotificationsProvider>().refresh(),
        child: items.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  EmptyView(
                    icon: Icons.notifications_none,
                    title: 'You are all caught up',
                    subtitle: 'New updates about your trips will show here.',
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                itemBuilder: (context, i) => _NotificationTile(item: items[i]),
              ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification item;
  const _NotificationTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: item.isRead
          ? Colors.transparent
          : AppColors.primary.withValues(alpha: 0.05),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: item.type.color.withValues(alpha: 0.15),
          child: Icon(item.type.icon, color: item.type.color, size: 20),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w700,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(item.message),
            const SizedBox(height: 4),
            Text(
              Formatters.relative(item.createdAt),
              style:
                  const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        trailing: item.isRead
            ? null
            : Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: item.isRead
            ? null
            : () => context.read<NotificationsProvider>().markRead(item.id),
      ),
    );
  }
}
