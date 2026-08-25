import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/bus.dart';
import '../../providers/repository_providers.dart';

/// Resolves a bus detail from a bus id, used when coming from a deep link or
/// QR scan where the caller doesn't already have the BusDetail in hand.
final busDetailByIdProvider =
    FutureProvider.autoDispose.family<BusDetail?, String>((ref, busId) {
  return ref.watch(busRepositoryProvider).byId(busId);
});
