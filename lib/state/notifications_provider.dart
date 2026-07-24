import 'dart:async';

import 'package:flutter/widgets.dart';

import '../data/service_locator.dart';
import '../models/app_notification.dart';

/// Holds the notifications inbox and polls it while the app is foregrounded,
/// per §5.8 / §8 (no push channel exists). Screens read [items] / [unread];
/// the shell shows the unread badge.
class NotificationsProvider extends ChangeNotifier with WidgetsBindingObserver {
  final _services = Services.I;

  List<AppNotification> _items = const [];
  bool _loading = false;
  Timer? _timer;

  static const _pollInterval = Duration(seconds: 45);

  List<AppNotification> get items => _items;
  bool get loading => _loading;
  int get unread => _items.where((n) => !n.isRead).length;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    refresh();
    _timer ??= Timer.periodic(_pollInterval, (_) => refresh());
  }

  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    notifyListeners();
    try {
      _items = await _services.notifications.list();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markRead(String id) async {
    await _services.notifications.markRead(id);
    _items = _items
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
    notifyListeners();
  }

  Future<void> markAllRead() async {
    await _services.notifications.markAllRead();
    _items = _items.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Poll immediately on foreground, pause the timer in background.
    if (state == AppLifecycleState.resumed) {
      refresh();
      _timer ??= Timer.periodic(_pollInterval, (_) => refresh());
    } else if (state == AppLifecycleState.paused) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
