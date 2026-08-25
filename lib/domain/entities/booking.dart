import 'package:flutter/foundation.dart';

import 'bus.dart';
import 'route.dart';
import 'stop.dart';

enum BookingStatus {
  pendingValidation,
  confirmed,
  cancelled,
  expired,
}

extension BookingStatusLabel on BookingStatus {
  String get label => switch (this) {
        BookingStatus.pendingValidation => 'Awaiting validation',
        BookingStatus.confirmed => 'Confirmed',
        BookingStatus.cancelled => 'Cancelled',
        BookingStatus.expired => 'Expired',
      };
}

@immutable
class Booking {
  const Booking({
    required this.id,
    required this.userId,
    required this.route,
    required this.from,
    required this.to,
    required this.fare,
    required this.bookedAt,
    required this.expiresAt,
    required this.status,
    this.bus,
    this.qrToken,
    this.seatLabels = const [],
    this.passengerName,
    this.passengerPhone,
  });

  final String id;
  final String userId;
  final BusRoute route;
  final Stop from;
  final Stop to;
  final num fare;
  final DateTime bookedAt;
  final DateTime expiresAt;
  final BookingStatus status;
  final BusDetail? bus;
  final String? qrToken;
  final List<String> seatLabels;
  final String? passengerName;
  final String? passengerPhone;

  Booking copyWith({
    BookingStatus? status,
    BusDetail? bus,
    String? qrToken,
    List<String>? seatLabels,
    String? passengerName,
    String? passengerPhone,
  }) =>
      Booking(
        id: id,
        userId: userId,
        route: route,
        from: from,
        to: to,
        fare: fare,
        bookedAt: bookedAt,
        expiresAt: expiresAt,
        status: status ?? this.status,
        bus: bus ?? this.bus,
        qrToken: qrToken ?? this.qrToken,
        seatLabels: seatLabels ?? this.seatLabels,
        passengerName: passengerName ?? this.passengerName,
        passengerPhone: passengerPhone ?? this.passengerPhone,
      );
}
