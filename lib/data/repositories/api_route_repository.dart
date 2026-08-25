import '../../core/network/api_client.dart';
import '../../domain/entities/route.dart';
import '../../domain/entities/saved_route.dart';
import '../../domain/entities/stop.dart';
import '../../domain/repositories/route_repository.dart';

class ApiRouteRepository implements RouteRepository {
  ApiRouteRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  final List<RecentSearch> _recent = <RecentSearch>[];
  final List<SavedRoute> _saved = <SavedRoute>[];

  @override
  Future<void> clearRecentSearches() async {
    _recent.clear();
  }

  @override
  bool isSaved(String fromId, String toId) =>
      _saved.any((r) => r.from.id == fromId && r.to.id == toId);

  @override
  Future<void> rememberSearch(RecentSearch search) async {
    _recent.removeWhere((item) => item.key == search.key);
    _recent.insert(0, search);
    if (_recent.length > 8) {
      _recent.removeRange(8, _recent.length);
    }
  }

  @override
  Future<List<RecentSearch>> recentSearches() async =>
      List.unmodifiable(_recent);

  @override
  Future<List<SavedRoute>> savedRoutes() async => List.unmodifiable(_saved);

  @override
  Future<List<RouteSearchResult>> search({
    required Stop from,
    required Stop to,
    DateTime? date,
  }) async {
    final fromStopId = int.tryParse(from.id);
    final toStopId = int.tryParse(to.id);
    if (fromStopId == null || toStopId == null) {
      throw const ApiException(
        statusCode: 400,
        message: 'Invalid stop id format for route search',
      );
    }

    try {
      final raw = await _apiClient.postJson(
        '/search/',
        body: {
          'from_stop_id': fromStopId,
          'to_stop_id': toStopId,
          if (date != null)
            'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        },
      );

      if (raw is! Map<String, dynamic>) {
        return const <RouteSearchResult>[];
      }

      final routesData = raw['route_ids'] ?? raw['routes'];
      if (routesData is! List) {
        return const <RouteSearchResult>[];
      }

      final results = <RouteSearchResult>[];
      final now = DateTime.now();

      for (final map in routesData.whereType<Map<String, dynamic>>()) {
        final routeId = map['route_id']?.toString() ?? 'unknown';
        final routeName =
            map['route_name']?.toString() ?? 'Route $routeId';
        final stopsRaw = map['stops'];

        if (stopsRaw is! List || stopsRaw.isEmpty) continue;

        final stopMaps = stopsRaw.whereType<Map<String, dynamic>>().toList();
        if (stopMaps.length < 2) continue;

        // Use backend-provided total distance
        final totalDistance =
            (map['total_distance'] as num?)?.toDouble() ?? 0.0;

        // Build stops from real stop names
        final stops = _buildRouteStops(
          stopMaps: stopMaps,
          from: from,
          to: to,
        );
        if (stops.length < 2) continue;

        final route = BusRoute(
          id: routeId,
          name: routeName,
          origin: stops.first,
          destination: stops.last,
          distanceKm: totalDistance,
          fare: (map['estimated_fare'] as num?)?.toInt() ?? 0,
          stops: stops,
          tags: _buildTags(map),
        );

        // Parse next departure time from backend
        final nextDepartureStr = map['next_departure']?.toString();
        DateTime nextBusAt;
        if (nextDepartureStr != null && nextDepartureStr.isNotEmpty) {
          nextBusAt = _parseTimeToday(nextDepartureStr, now);
        } else {
          // Fallback: first bus schedule time
          final busesRaw = map['buses'] as List?;
          if (busesRaw != null && busesRaw.isNotEmpty) {
            final firstBus =
                busesRaw.first as Map<String, dynamic>;
            final startTime = firstBus['start_time']?.toString();
            if (startTime != null) {
              nextBusAt = _parseTimeToday(startTime, now);
            } else {
              nextBusAt = now.add(const Duration(minutes: 15));
            }
          } else {
            nextBusAt = now.add(const Duration(minutes: 15));
          }
        }

        // Parse estimated travel time
        final travelMinutes =
            (map['estimated_travel_minutes'] as num?)?.toInt() ??
            (totalDistance * 3).round();

        // Total buses on this route for the selected date
        final totalBusesToday =
            (map['total_buses_on_date'] as num?)?.toInt() ??
            (map['total_buses_today'] as num?)?.toInt() ?? 0;

        results.add(
          RouteSearchResult(
            route: route,
            searchedFrom: from,
            searchedTo: to,
            searchedDistanceKm: totalDistance,
            searchedFare: (map['estimated_fare'] as num?)?.toInt() ?? 0,
            nextBusAt: nextBusAt,
            estimatedTravel: Duration(minutes: travelMinutes),
            totalBusesToday: totalBusesToday,
          ),
        );
      }

      return results;
    } on ApiException catch (e) {
      // 404 means no routes found — return empty list
      if (e.statusCode == 404) {
        return const <RouteSearchResult>[];
      }
      rethrow;
    }
  }

  @override
  Future<List<RouteSearchResult>> popularSuggestions({int limit = 6}) async {
    // TODO(api): implement real popular routes endpoint
    return const <RouteSearchResult>[];
  }

  @override
  Future<void> toggleSaved(SavedRoute route) async {
    final index = _saved.indexWhere(
      (item) => item.from.id == route.from.id && item.to.id == route.to.id,
    );
    if (index >= 0) {
      _saved.removeAt(index);
      return;
    }
    _saved.insert(0, route);
  }

  // ---------- helpers ----------

  /// Parse a time string like "08:30:00" into today's DateTime.
  DateTime _parseTimeToday(String timeStr, DateTime now) {
    final parts = timeStr.split(':');
    if (parts.length < 2) return now.add(const Duration(minutes: 15));
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  List<Stop> _buildRouteStops({
    required List<Map<String, dynamic>> stopMaps,
    required Stop from,
    required Stop to,
  }) {
    final stops = <Stop>[];

    for (var i = 0; i < stopMaps.length; i++) {
      final name = (stopMaps[i]['stop_name'] ?? '').toString().trim();
      if (name.isEmpty) continue;

      stops.add(
        Stop(
          id: 'route-stop-$i',
          name: name,
          city: name,
        ),
      );
    }

    // Force searched from/to
    if (stops.isNotEmpty) {
      stops[0] = from;
    }
    if (stops.length > 1) {
      stops[stops.length - 1] = to;
    }

    return stops;
  }

  /// Build tags from bus type info.
  List<String> _buildTags(Map<String, dynamic> map) {
    final tags = <String>['Live'];
    final buses = map['buses'] as List?;
    if (buses != null && buses.isNotEmpty) {
      final firstBus = buses.first as Map<String, dynamic>;
      final busType = firstBus['bus_type']?.toString();
      if (busType != null) {
        tags.add(busType.replaceAll('_', ' ').toUpperCase());
      }
      final operator = firstBus['operator_name']?.toString();
      if (operator != null && operator.isNotEmpty) {
        tags.add(operator);
      }
    }
    return tags;
  }
}
