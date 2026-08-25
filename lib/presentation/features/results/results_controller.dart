import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/route.dart';
import '../../../domain/entities/saved_route.dart';
import '../../../domain/entities/stop.dart';
import '../../providers/repository_providers.dart';

@immutable
class RouteResultsRequest {
  const RouteResultsRequest({
    required this.from,
    required this.to,
    required this.date,
  });

  final Stop from;
  final Stop to;
  final DateTime? date;

  @override
  bool operator ==(Object other) =>
      other is RouteResultsRequest &&
      other.from.id == from.id &&
      other.to.id == to.id &&
      other.date == date;

  @override
  int get hashCode => Object.hash(from.id, to.id, date);
}

/// Fetches route search results and remembers the search in recents.
final routeResultsProvider = FutureProvider.family
    .autoDispose<List<RouteSearchResult>, RouteResultsRequest>((ref, req) async {
  final routes = ref.watch(routeRepositoryProvider);
  final results = await routes.search(
    from: req.from,
    to: req.to,
    date: req.date,
  );
  await routes.rememberSearch(
    RecentSearch(from: req.from, to: req.to, searchedAt: DateTime.now()),
  );
  return results;
});
