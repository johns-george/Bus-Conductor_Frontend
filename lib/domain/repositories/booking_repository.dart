import '../entities/booking.dart';
import '../entities/bus.dart';
import '../entities/route.dart';
import '../entities/stop.dart';

/// Maps to `BOOK TICKET` and booking-state transitions.
abstract class BookingRepository {
  Future<Booking> createRouteBooking({
    required String userId,
    required BusRoute route,
    required Stop from,
    required Stop to,
    BusDetail? bus,
    List<String> seatLabels = const [],
    num? fareOverride,
    String? passengerName,
    String? passengerPhone,
  });

  Future<Booking> createDirectBusBooking({
    required String userId,
    required BusDetail bus,
    required Stop from,
    required Stop to,
  });

  Future<Booking?> byId(String id);

  Future<List<Booking>> byUser(String userId);

  Future<Booking> cancel(String bookingId);

  Future<Booking> markValidated(String bookingId);
}
