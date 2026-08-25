import '../entities/booking.dart';
import '../entities/ticket.dart';

/// Result of a ticket cancellation.
class CancelTicketResult {
  const CancelTicketResult({
    required this.success,
    this.refundAmount,
    this.walletBalance,
    this.errorMessage,
  });

  final bool success;
  final num? refundAmount;
  final num? walletBalance;
  final String? errorMessage;
}

/// Maps to `GET TICKET`.
abstract class TicketRepository {
  Future<List<Ticket>> byUser(String userId);
  Future<Ticket?> byId(String id);

  /// Issues a ticket from a confirmed [Booking].
  Future<Ticket> issueFromBooking(Booking booking);

  Future<Ticket> markValidated(String ticketId);

  /// Cancel a ticket and refund to wallet.
  Future<CancelTicketResult> cancelTicket(String ticketId);

  /// Edit passenger details on a non-validated ticket.
  Future<Ticket> editTicket({
    required String ticketId,
    String? passengerName,
    String? passengerPhone,
    int? passengerCount,
  });
}
