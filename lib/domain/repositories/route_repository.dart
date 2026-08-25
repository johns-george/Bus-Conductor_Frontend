import '../entities/route.dart';
import '../entities/saved_route.dart';
import '../entities/stop.dart';

/// Maps to `GET ROUTES` plus app-local concepts like saved routes and
/// recent searches which the real backend may also surface later.
abstract class RouteRepository {
  Future<List<RouteSearchResult>> search({
    required Stop from,
    required Stop to,
    DateTime? date,
  });

  Future<List<RouteSearchResult>> popularSuggestions({int limit = 6});

  Future<List<RecentSearch>> recentSearches();
  Future<void> rememberSearch(RecentSearch search);
  Future<void> clearRecentSearches();

  Future<List<SavedRoute>> savedRoutes();
  Future<void> toggleSaved(SavedRoute route);
  bool isSaved(String fromId, String toId);
}
