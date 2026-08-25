import 'package:uuid/uuid.dart';

import '../../core/network/api_client.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/bus.dart';
import '../../domain/entities/route.dart';
import '../../domain/entities/stop.dart';
import '../../domain/repositories/booking_repository.dart';

/// API-backed booking repository.
/// Bookings are ephemeral — they exist during the payment flow only.
/// The actual ticket is created by the payment endpoint, not here.
class ApiBookingRepository implements BookingRepository {
  ApiBookingRepository();

  final Uuid _uuid = const Uuid();

  @override
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
  }) async {
    final now = DateTime.now();
    final fare = fareOverride ?? route.fare;

    // Return a local Booking — no backend call.
    // The payment endpoint (POST /payments/process) creates the actual ticket.
    return Booking(
      id: 'bk_${_uuid.v4().substring(0, 8).toUpperCase()}',
      userId: userId,
      route: route,
      from: from,
      to: to,
      fare: fare,
      bookedAt: now,
      expiresAt: now.add(const Duration(hours: 4)),
      status: BookingStatus.pendingValidation,
      bus: bus,
      seatLabels: seatLabels,
      passengerName: passengerName,
      passengerPhone: passengerPhone,
    );
  }

  @override
  Future<Booking> createDirectBusBooking({
    required String userId,
    required BusDetail bus,
    required Stop from,
    required Stop to,
  }) async {
    throw const ApiException(
      statusCode: 501,
      message: 'Direct bus booking is not supported yet',
    );
  }

  @override
  Future<Booking?> byId(String id) async {
    return null;
  }

  @override
  Future<List<Booking>> byUser(String userId) async {
    return const [];
  }

  @override
  Future<Booking> cancel(String bookingId) async {
    throw const ApiException(
      statusCode: 501,
      message: 'Booking cancellation not supported yet',
    );
  }

  @override
  Future<Booking> markValidated(String bookingId) async {
    throw const ApiException(
      statusCode: 501,
      message: 'Booking validation not supported yet',
    );
  }
}
