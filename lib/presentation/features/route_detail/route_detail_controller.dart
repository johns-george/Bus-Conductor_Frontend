import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/bus.dart';
import '../../../domain/entities/route.dart';
import '../../providers/repository_providers.dart';

/// Resolves a full [BusRoute] for the given routeId. Used when we navigate to
/// the route detail page without a pre-fetched search result (e.g. deep link).
final routeByIdProvider =
    FutureProvider.autoDispose.family<BusRoute?, String>((ref, routeId) async {
  final repo = ref.watch(routeRepositoryProvider);
  // RouteRepository intentionally doesn't expose `byId` directly yet;
  // we reconstruct via popularSuggestions until the real API lands.
  final suggestions = await repo.popularSuggestions(limit: 50);
  for (final s in suggestions) {
    if (s.route.id == routeId) return s.route;
  }
  return null;
});

/// Live list of upcoming buses on a given route.
final routeBusesProvider = FutureProvider.autoDispose
    .family<List<BusDetail>, String>((ref, routeId) async {
  final repo = ref.watch(busRepositoryProvider);
  return repo.byRoute(routeId);
});
