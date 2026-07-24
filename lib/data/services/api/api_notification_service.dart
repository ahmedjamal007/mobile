import '../../../core/constants/api_constants.dart';
import '../../../models/app_notification.dart';
import '../../api_client.dart';
import '../notification_service.dart';
import 'api_parsing.dart';

/// Polling inbox — there is no push channel, so `NotificationsProvider` calls
/// [list] on a timer while the app is foregrounded.
class ApiNotificationService implements NotificationService {
  final ApiClient _client;

  ApiNotificationService(this._client);

  @override
  Future<List<AppNotification>> list() async {
    final res = await _client.get(ApiConstants.notifications);
    return asList(res.data).map(AppNotification.fromJson).toList();
  }

  @override
  Future<void> markRead(String id) async {
    await _client.post(ApiConstants.notificationRead(id));
  }

  @override
  Future<void> markAllRead() async {
    await _client.post(ApiConstants.notificationsMarkAllRead);
  }
}
