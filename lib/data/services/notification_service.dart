import '../../models/app_notification.dart';
import '../mock/mock_backend.dart';

abstract class NotificationService {
  Future<List<AppNotification>> list();
  Future<void> markRead(String id);
  Future<void> markAllRead();
}

class MockNotificationService implements NotificationService {
  final _backend = MockBackend.instance;

  @override
  Future<List<AppNotification>> list() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_backend.notifications);
  }

  @override
  Future<void> markRead(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _backend.markRead(id);
  }

  @override
  Future<void> markAllRead() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _backend.markAllRead();
  }
}
