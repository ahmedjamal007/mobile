import 'api_client.dart';
import 'services/api/api_auth_service.dart';
import 'services/api/api_catalog_service.dart';
import 'services/api/api_notification_service.dart';
import 'services/api/api_payment_service.dart';
import 'services/api/api_reservation_service.dart';
import 'services/api/api_ticket_service.dart';
import 'services/auth_service.dart';
import 'services/catalog_service.dart';
import 'services/notification_service.dart';
import 'services/payment_service.dart';
import 'services/reservation_service.dart';
import 'services/ticket_service.dart';
import 'token_storage.dart';

/// Single place that decides which service implementations the app uses.
///
/// Everything points at the live Django API. The `Mock*` classes alongside
/// each interface are kept for running the UI without a server — swap any
/// assignment below to fall back to one.
class Services {
  Services._();
  static final Services I = Services._();

  final TokenStorage tokenStorage = TokenStorage();

  /// One client for the whole app so the 401-refresh-and-retry interceptor
  /// shares its in-flight state across every call.
  late final ApiClient _client = ApiClient(tokens: tokenStorage);

  late final AuthService auth = ApiAuthService(_client);
  late final CatalogService catalog = ApiCatalogService(_client);
  late final ReservationService reservations = ApiReservationService(_client);
  late final PaymentService payments = ApiPaymentService(_client);
  late final TicketService tickets = ApiTicketService(_client);
  late final NotificationService notifications =
      ApiNotificationService(_client);
}
