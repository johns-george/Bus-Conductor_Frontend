import 'package:flutter/foundation.dart';

import 'stop.dart';

@immutable
class SavedRoute {
  const SavedRoute({
    required this.id,
    required this.label,
    required this.from,
    required this.to,
    required this.savedAt,
  });

  final String id;
  final String label;
  final Stop from;
  final Stop to;
  final DateTime savedAt;
}

@immutable
class RecentSearch {
  const RecentSearch({
    required this.from,
    required this.to,
    required this.searchedAt,
  });

  final Stop from;
  final Stop to;
  final DateTime searchedAt;

  String get key => '${from.id}->${to.id}';
}
