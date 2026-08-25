import 'package:flutter/foundation.dart';

enum BusType {
  acSeater,
  nonAcSeater,
  acSleeper,
  volvo,
  electric,
  miniBus,
}

extension BusTypeLabel on BusType {
  String get label => switch (this) {
        BusType.acSeater => 'AC Seater',
        BusType.nonAcSeater => 'Non-AC Seater',
        BusType.acSleeper => 'AC Sleeper',
        BusType.volvo => 'Volvo Multi-Axle',
        BusType.electric => 'Electric',
        BusType.miniBus => 'Mini Bus',
      };
}

@immutable
class Bus {
  const Bus({
    required this.id,
    required this.name,
    required this.number,
    required this.type,
    required this.operatorName,
    required this.capacity,
  });

  final String id;
  final String name;
  final String number;
  final BusType type;
  final String operatorName;
  final int capacity;
}

/// A bus running a specific route at a specific time. Mirrors the
/// `GET BUS DETAIL` API response.
@immutable
class BusDetail {
  const BusDetail({
    required this.bus,
    required this.routeId,
    required this.departureAt,
    required this.arrivalAt,
    this.isLive = false,
    this.platform,
  });

  final Bus bus;
  final String routeId;
  final DateTime departureAt;
  final DateTime arrivalAt;
  final bool isLive;
  final String? platform;

  Duration get travelDuration => arrivalAt.difference(departureAt);
}
