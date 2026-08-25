import '../../core/network/api_client.dart';
import '../../domain/entities/bus.dart';
import '../../domain/repositories/bus_repository.dart';

class ApiBusRepository implements BusRepository {
  ApiBusRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<BusDetail>> byRoute(String routeId, {DateTime? on}) async {
    try {
      final raw = await _apiClient.getJson('/buses/by-route/$routeId');

      if (raw is! Map<String, dynamic>) {
        return const <BusDetail>[];
      }

      final List<dynamic> items = (raw['items'] ?? <dynamic>[]) as List<dynamic>;

      final List<BusDetail> results = <BusDetail>[];
      for (final item in items.whereType<Map<String, dynamic>>()) {
        final busId = item['id']?.toString() ?? '';
        final busName = item['name']?.toString() ?? '';
        final busNumber = item['bus_number']?.toString() ?? '';
        final startTimeStr = item['start_time']?.toString();

        if (busId.isEmpty || startTimeStr == null) continue;

        // Parse time-only string with today's date
        final now = DateTime.now();
        final timeParts = startTimeStr.split(':');
        if (timeParts.length != 3) continue;
        
        final startTime = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
          int.parse(timeParts[2]),
        );

        // Parse bus type from backend
        BusType busType;
        final busTypeStr = item['bus_type']?.toString() ?? 'non_ac_seater';
        switch (busTypeStr) {
          case 'ac_seater':
            busType = BusType.acSeater;
            break;
          case 'non_ac_seater':
            busType = BusType.nonAcSeater;
            break;
          case 'ac_sleeper':
            busType = BusType.acSleeper;
            break;
          case 'volvo':
            busType = BusType.volvo;
            break;
          case 'electric':
            busType = BusType.electric;
            break;
          case 'mini_bus':
            busType = BusType.miniBus;
            break;
          default:
            busType = BusType.nonAcSeater;
        }

        // Create a Bus entity with data from backend
        final bus = Bus(
          id: busId,
          name: busName.isNotEmpty ? busName : 'Bus $busNumber',
          number: busNumber,
          type: busType,
          operatorName: item['operator_name']?.toString() ?? 'Default Operator',
          capacity: int.tryParse(item['capacity']?.toString() ?? '40') ?? 40,
        );

        // Calculate estimated arrival time (30 minutes after departure as default)
        final arrivalTime = startTime.add(const Duration(minutes: 30));

        results.add(
          BusDetail(
            bus: bus,
            routeId: routeId,
            departureAt: startTime,
            arrivalAt: arrivalTime,

            isLive: startTime.difference(DateTime.now()).inMinutes <= 15,
            platform: item['platform']?.toString() ?? 'P1',
          ),
        );
      }

      // Sort by departure time
      results.sort((a, b) => a.departureAt.compareTo(b.departureAt));
      return results;
    } catch (e) {
      // Return empty list on error to avoid breaking the UI
      return const <BusDetail>[];
    }
  }

  @override
  Future<BusDetail?> byId(String id) async {
    try {
      final raw = await _apiClient.getJson('/buses/$id');

      if (raw is! Map<String, dynamic>) {
        return null;
      }

      final busId = raw['id']?.toString() ?? '';
      final busName = raw['name']?.toString() ?? '';
      final busNumber = raw['bus_number']?.toString() ?? '';
      final busTypeStr = raw['bus_type']?.toString() ?? 'non_ac_seater';
      final operatorName = raw['operator_name']?.toString() ?? 'Default Operator';
      final capacity = int.tryParse(raw['capacity']?.toString() ?? '40') ?? 40;

      if (busId.isEmpty) return null;

      // Parse bus type
      BusType busType;
      switch (busTypeStr) {
        case 'ac_seater':
          busType = BusType.acSeater;
          break;
        case 'non_ac_seater':
          busType = BusType.nonAcSeater;
          break;
        case 'ac_sleeper':
          busType = BusType.acSleeper;
          break;
        case 'volvo':
          busType = BusType.volvo;
          break;
        case 'electric':
          busType = BusType.electric;
          break;
        case 'mini_bus':
          busType = BusType.miniBus;
          break;
        default:
          busType = BusType.nonAcSeater;
      }

      final bus = Bus(
        id: busId,
        name: busName.isNotEmpty ? busName : 'Bus $busNumber',
        number: busNumber,
        type: busType,
        capacity: capacity,
        operatorName: operatorName,
      );

      return BusDetail(
        bus: bus,
        routeId: '', // Not provided by this endpoint
        departureAt: DateTime.now(),
        arrivalAt: DateTime.now().add(const Duration(minutes: 30)),
        isLive: false,
        platform: 'P1',
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<BusDetail?> byQrToken(String token) async {
    try {
      final raw = await _apiClient.getJson('/buses/by-qr/$token');

      if (raw is! Map<String, dynamic>) {
        return null;
      }

      final busData = raw['bus'];
      if (busData is! Map<String, dynamic>) {
        return null;
      }

      final busId = busData['id']?.toString() ?? '';
      final busName = busData['name']?.toString() ?? '';
      final busNumber = busData['bus_number']?.toString() ?? '';
      final busTypeStr = busData['bus_type']?.toString() ?? 'non_ac_seater';
      final operatorName = busData['operator_name']?.toString() ?? 'Default Operator';
      final capacity = int.tryParse(busData['capacity']?.toString() ?? '40') ?? 40;

      if (busId.isEmpty) return null;

      // Parse bus type
      BusType busType;
      switch (busTypeStr) {
        case 'ac_seater':
          busType = BusType.acSeater;
          break;
        case 'non_ac_seater':
          busType = BusType.nonAcSeater;
          break;
        case 'ac_sleeper':
          busType = BusType.acSleeper;
          break;
        case 'volvo':
          busType = BusType.volvo;
          break;
        case 'electric':
          busType = BusType.electric;
          break;
        case 'mini_bus':
          busType = BusType.miniBus;
          break;
        default:
          busType = BusType.nonAcSeater;
      }

      final bus = Bus(
        id: busId,
        name: busName.isNotEmpty ? busName : 'Bus $busNumber',
        number: busNumber,
        type: busType,
        capacity: capacity,
        operatorName: operatorName,
      );

      return BusDetail(
        bus: bus,
        routeId: '', // Not provided by this endpoint
        departureAt: DateTime.now(),
        arrivalAt: DateTime.now().add(const Duration(minutes: 30)),
        isLive: false,
        platform: 'P1',
      );
    } catch (e) {
      return null;
    }
  }
}
