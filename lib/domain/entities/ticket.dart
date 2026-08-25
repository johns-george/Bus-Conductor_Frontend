import 'package:flutter/foundation.dart';

import 'bus.dart';
import 'route.dart';
import 'stop.dart';

enum TicketStatus {
  pendingValidation,
  active,
  validated,
  expired,
  cancelled,
}

extension TicketStatusLabel on TicketStatus {
  String get label => switch (this) {
        TicketStatus.pendingValidation => 'Awaiting boarding',
        TicketStatus.active => 'Active',
        TicketStatus.validated => 'Validated',
        TicketStatus.expired => 'Expired',
        TicketStatus.cancelled => 'Cancelled',
      };
}

@immutable
class Ticket {
  const Ticket({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.route,
    required this.from,
    required this.to,
    required this.fare,
    required this.bookedAt,
    required this.expiresAt,
    required this.status,
    this.bus,
    this.validatedAt,
    this.qrToken,
    this.seatLabels = const [],
    this.passengerName,
    this.passengerPhone,
    this.passengerCount = 1,
  });

  final String id;
  final String bookingId;
  final String userId;
  final BusRoute route;
  final Stop from;
  final Stop to;
  final num fare;
  final DateTime bookedAt;
  final DateTime expiresAt;
  final TicketStatus status;
  final BusDetail? bus;
  final DateTime? validatedAt;
  final String? qrToken;
  final List<String> seatLabels;
  final String? passengerName;
  final String? passengerPhone;
  final int passengerCount;

  Ticket copyWith({
    TicketStatus? status,
    DateTime? validatedAt,
    String? qrToken,
  }) =>
      Ticket(
        id: id,
        bookingId: bookingId,
        userId: userId,
        route: route,
        from: from,
        to: to,
        fare: fare,
        bookedAt: bookedAt,
        expiresAt: expiresAt,
        status: status ?? this.status,
        bus: bus,
        validatedAt: validatedAt ?? this.validatedAt,
        qrToken: qrToken ?? this.qrToken,
        seatLabels: seatLabels,
        passengerName: passengerName,
        passengerPhone: passengerPhone,
        passengerCount: passengerCount,
      );
}
