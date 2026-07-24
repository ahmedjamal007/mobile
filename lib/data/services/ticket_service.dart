import '../../models/ticket.dart';
import '../api_exception.dart';
import '../mock/mock_backend.dart';

abstract class TicketService {
  Future<List<Ticket>> myTickets();
  Future<Ticket> detail(String id);
}

class MockTicketService implements TicketService {
  final _backend = MockBackend.instance;

  @override
  Future<List<Ticket>> myTickets() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.unmodifiable(_backend.tickets);
  }

  @override
  Future<Ticket> detail(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _backend.tickets.firstWhere(
      (t) => t.id == id,
      orElse: () =>
          throw const ApiException('Ticket not found.', statusCode: 404),
    );
  }
}
