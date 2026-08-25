import 'package:flutter/foundation.dart';

import 'stop.dart';

/// A published bus route with its overall start → destination, plus the
/// searched subsegment when produced from a route search.
@immutable
class BusRoute {
  const BusRoute({
    required this.id,
    required this.name,
    required this.origin,
    required this.destination,
    required this.distanceKm,
    required this.fare,
    required this.stops,
    this.tags = const [],
  });

  final String id;
  final String name;
  final Stop origin;
  final Stop destination;
  final double distanceKm;
  final num fare;
  final List<Stop> stops;
  final List<String> tags;
}

/// Result of a route search — a route constrained to a searched subsegment
/// with the next upcoming bus time.
@immutable
class RouteSearchResult {
  const RouteSearchResult({
    required this.route,
    required this.searchedFrom,
    required this.searchedTo,
    required this.searchedDistanceKm,
    required this.searchedFare,
    required this.nextBusAt,
    required this.estimatedTravel,
    required this.totalBusesToday,
  });

  final BusRoute route;
  final Stop searchedFrom;
  final Stop searchedTo;
  final double searchedDistanceKm;
  final num searchedFare;
  final DateTime nextBusAt;
  final Duration estimatedTravel;
  final int totalBusesToday;

  bool get isDepartingSoon =>
      nextBusAt.difference(DateTime.now()).inMinutes <= 20;
}

@immutable
class RouteSearchRequest {
  const RouteSearchRequest({
    required this.from,
    required this.to,
    required this.date,
  });

  final Stop from;
  final Stop to;
  final DateTime date;
}
