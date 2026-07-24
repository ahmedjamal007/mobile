/// All backend paths in one place. When you wire the real API, only the
/// [baseUrl] and (if needed) individual paths change — call sites in the
/// service layer already reference these constants.
class ApiConstants {
  ApiConstants._();

  /// Android emulator maps the host machine's localhost to 10.0.2.2. Override
  /// for a device or a real host with:
  ///   flutter run --dart-define=SRRS_BASE_URL=http://192.168.1.20:8000
  static const String baseUrl = String.fromEnvironment(
    'SRRS_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
  static const String apiPrefix = '/api';

  /// Django serializes file fields as a relative `/media/...` path whenever the
  /// serializer was built without a request in context (as `ProfileView` does).
  /// Image widgets need an absolute URL, so resolve it against [baseUrl].
  static String? mediaUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return '$baseUrl${path.startsWith('/') ? path : '/$path'}';
  }

  // Auth
  static const String register = '$apiPrefix/auth/register/';
  static const String login = '$apiPrefix/auth/login/';
  static const String token = '$apiPrefix/token/';
  static const String tokenRefresh = '$apiPrefix/token/refresh/';
  static const String logout = '$apiPrefix/auth/logout/';
  static const String profile = '$apiPrefix/auth/profile/';
  static const String profileUpdate = '$apiPrefix/auth/profile/update/';

  // Catalog
  static const String schedules = '$apiPrefix/schedules/';
  static const String trains = '$apiPrefix/trains/';
  static const String stations = '$apiPrefix/stations/';
  static const String stationCreate = '$apiPrefix/stations/create/';
  static const String scheduleCreate = '$apiPrefix/schedules/create/';
  static String scheduleDetail(String id) => '$apiPrefix/schedules/$id/';

  // Reservations
  static const String reservations = '$apiPrefix/reservations/';
  static const String reservationCreate = '$apiPrefix/reservations/create/';
  static String reservationDetail(String id) => '$apiPrefix/reservations/$id/';

  // Payments
  static const String payments = '$apiPrefix/payments/';
  static const String paymentCreate = '$apiPrefix/payments/create/';
  static const String paymentsPending = '$apiPrefix/payments/pending/';
  static String paymentDetail(String id) => '$apiPrefix/payments/$id/';
  static String paymentReview(String id) => '$apiPrefix/payments/$id/review/';

  // Tickets
  static const String tickets = '$apiPrefix/tickets/';
  static String ticketDetail(String id) => '$apiPrefix/tickets/$id/';

  // Notifications
  static const String notifications = '$apiPrefix/notifications/';
  static String notificationRead(String id) =>
      '$apiPrefix/notifications/$id/read/';
  static const String notificationsMarkAllRead =
      '$apiPrefix/notifications/mark-all-read/';
}
