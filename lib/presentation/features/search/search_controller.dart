import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/saved_route.dart';
import '../../../domain/entities/stop.dart';
import '../../providers/repository_providers.dart';

@immutable
class SearchFormState {
  const SearchFormState({this.from, this.to, this.date, this.error});

  final Stop? from;
  final Stop? to;
  final DateTime? date;
  final String? error;

  bool get isReady => from != null && to != null && from!.id != to!.id;

  SearchFormState copyWith({
    Stop? from,
    Stop? to,
    DateTime? date,
    String? error,
    bool clearFrom = false,
    bool clearTo = false,
    bool clearDate = false,
    bool clearError = false,
  }) =>
      SearchFormState(
        from: clearFrom ? null : (from ?? this.from),
        to: clearTo ? null : (to ?? this.to),
        date: clearDate ? null : (date ?? this.date),
        error: clearError ? null : (error ?? this.error),
      );
}

class SearchFormController extends Notifier<SearchFormState> {
  @override
  SearchFormState build() => const SearchFormState();

  void setFrom(Stop stop) {
    if (state.to?.id == stop.id) {
      state = state.copyWith(from: stop, to: null, clearError: true);
      return;
    }
    state = state.copyWith(from: stop, clearError: true);
  }

  void setTo(Stop stop) {
    if (state.from?.id == stop.id) {
      state = state.copyWith(to: stop, from: null, clearError: true);
      return;
    }
    state = state.copyWith(to: stop, clearError: true);
  }

  void swap() {
    state = SearchFormState(
      from: state.to,
      to: state.from,
      date: state.date,
    );
  }

  void clearFrom() =>
      state = state.copyWith(clearFrom: true, clearError: true);

  void clearTo() => state = state.copyWith(clearTo: true, clearError: true);

  void setDate(DateTime? date) {
    state = state.copyWith(date: date, clearDate: date == null, clearError: true);
  }

  String? validate() {
    if (state.from == null) return 'Pick a starting stop';
    if (state.to == null) return 'Pick a destination stop';
    if (state.from!.id == state.to!.id) return 'Source and destination must differ';
    return null;
  }

  void setError(String? error) =>
      state = state.copyWith(error: error, clearError: error == null);
}

final searchFormProvider =
    NotifierProvider<SearchFormController, SearchFormState>(
  SearchFormController.new,
);

/// Provides autocomplete suggestions for stop pickers.
final stopSuggestionsProvider =
    FutureProvider.family.autoDispose<List<Stop>, String>((ref, query) async {
  final repo = ref.watch(stopRepositoryProvider);
  return repo.search(query);
});

final popularStopsProvider = FutureProvider.autoDispose<List<Stop>>((ref) {
  return ref.watch(stopRepositoryProvider).popular();
});

final recentSearchesProvider =
    FutureProvider.autoDispose<List<RecentSearch>>((ref) {
  return ref.watch(routeRepositoryProvider).recentSearches();
});

final savedRoutesProvider =
    FutureProvider.autoDispose<List<SavedRoute>>((ref) {
  return ref.watch(routeRepositoryProvider).savedRoutes();
});
