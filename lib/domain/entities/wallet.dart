import 'package:flutter/foundation.dart';

/// User wallet balance. Mirrors the in-app wallet the real backend will surface
/// once payments are live; for now it's seeded and mutated through the mock
/// repository so the Wallet tab and booking flow feel real.
@immutable
class Wallet {
  const Wallet({
    required this.userId,
    required this.balance,
    required this.lastUpdated,
    this.passes = const [],
  });

  final String userId;
  final num balance;
  final DateTime lastUpdated;
  final List<TravelPass> passes;

  Wallet copyWith({
    num? balance,
    DateTime? lastUpdated,
    List<TravelPass>? passes,
  }) =>
      Wallet(
        userId: userId,
        balance: balance ?? this.balance,
        lastUpdated: lastUpdated ?? this.lastUpdated,
        passes: passes ?? this.passes,
      );
}

/// A pre-paid pass (weekly/monthly) that the user can apply at checkout. Not
/// deeply modeled — but visible on the Wallet tab so the feature surface is
/// complete.
@immutable
class TravelPass {
  const TravelPass({
    required this.id,
    required this.label,
    required this.validTill,
    required this.ridesRemaining,
  });

  final String id;
  final String label;
  final DateTime validTill;
  final int ridesRemaining;
}
