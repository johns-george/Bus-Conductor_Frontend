import '../entities/stop.dart';

/// Maps to `GET STOPS`.
abstract class StopRepository {
  /// Returns stops matching [query]. Empty query returns a popular set.
  Future<List<Stop>> search(String query, {int limit = 20});

  Future<List<Stop>> popular();

  Future<Stop?> byId(String id);
}
