import '../entities/bus.dart';

/// Maps to `GET BUS DETAIL`.
abstract class BusRepository {
  Future<List<BusDetail>> byRoute(String routeId, {DateTime? on});
  Future<BusDetail?> byId(String id);
  Future<BusDetail?> byQrToken(String token);
}
