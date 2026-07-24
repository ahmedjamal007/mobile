import '../../../core/constants/api_constants.dart';
import '../../../models/ticket.dart';
import '../../api_client.dart';
import '../ticket_service.dart';
import 'api_parsing.dart';

/// Tickets are issued by the backend when staff approve a payment; the app
/// only ever reads them.
class ApiTicketService implements TicketService {
  final ApiClient _client;

  ApiTicketService(this._client);

  @override
  Future<List<Ticket>> myTickets() async {
    final res = await _client.get(ApiConstants.tickets);
    return asList(res.data).map(Ticket.fromJson).toList();
  }

  @override
  Future<Ticket> detail(String id) async {
    final res = await _client.get(ApiConstants.ticketDetail(id));
    return Ticket.fromJson(asMap(res.data));
  }
}
