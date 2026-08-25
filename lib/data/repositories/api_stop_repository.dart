import '../../core/network/api_client.dart';
import '../../domain/entities/stop.dart';
import '../../domain/repositories/stop_repository.dart';

class ApiStopRepository implements StopRepository {
  ApiStopRepository(this._apiClient);

  final ApiClient _apiClient;

  List<Stop>? _cachedStops;

  @override
  Future<Stop?> byId(String id) async {
    final stops = await _allStops();
    for (final stop in stops) {
      if (stop.id == id) return stop;
    }
    return null;
  }

  @override
  Future<List<Stop>> popular() async {
    final stops = await _allStops();
    return stops;  // Return all stops, already sorted by location or alphabetically
  }

  @override
  Future<List<Stop>> search(String query, {int limit = 20}) async {
    if (query.trim().isEmpty) return [];
    
    try {
      final response = await _apiClient.getJson('/stops/search?q=${Uri.encodeComponent(query)}&limit=$limit');
      if (response is! List) {
        throw const ApiException(statusCode: 500, message: 'Invalid search response');
      }
      return response
          .whereType<Map<String, dynamic>>()
          .map(_parseStop)
          .toList();
    } catch (e) {
      // Fallback to client-side search if API fails
      return _fallbackSearch(query, limit);
    }
  }

  List<Stop> _fallbackSearch(String query, int limit) {
    if (_cachedStops == null) return [];
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _cachedStops!.take(limit).toList();
    final matches = _cachedStops!.where((s) {
      final name = s.name.toLowerCase();
      final city = s.city.toLowerCase();
      final area = s.area?.toLowerCase() ?? '';
      return name.contains(q) || city.contains(q) || area.contains(q);
    }).toList();
    return matches.take(limit).toList();
  }

  Future<List<Stop>> _allStops({double? lat, double? lng}) async {
    if (_cachedStops != null) return _cachedStops!;
    String url = '/stops/get-all-stops';
    final params = <String>[];
    if (lat != null) params.add('lat=$lat');
    if (lng != null) params.add('lng=$lng');
    if (params.isNotEmpty) url += '?${params.join('&')}';
    final raw = await _apiClient.getJson(url);
    if (raw is! List) {
      throw const ApiException(statusCode: 500, message: 'Invalid stops payload');
    }
    _cachedStops = raw
        .whereType<Map<String, dynamic>>()
        .map(_parseStop)
        .toList();
    return _cachedStops!;
  }

  Stop _parseStop(Map<String, dynamic> json) {
    final id = json['id'];
    final name = (json['name'] ?? '').toString();
    final address = (json['address'] ?? '').toString();
    final area = json['area']?.toString();
    final city = json['city']?.toString();
    final lat = (json['latitude'] as num?)?.toDouble();
    final lng = (json['longitude'] as num?)?.toDouble();
    return Stop(
      id: id.toString(),
      name: name,
      city: (city != null && city.isNotEmpty) ? city : (address.isEmpty ? 'Unknown' : address),
      area: area,
      latitude: lat,
      longitude: lng,
      isPopular: false,
    );
  }
}
