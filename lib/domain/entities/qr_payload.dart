import 'package:flutter/foundation.dart';

enum QrKind { busBoarding, bookingToken, ticket }

@immutable
class QrPayload {
  const QrPayload({
    required this.kind,
    required this.referenceId,
    required this.issuedAt,
    this.routeId,
    this.busId,
    this.metadata = const {},
  });

  final QrKind kind;
  final String referenceId;
  final DateTime issuedAt;
  final String? routeId;
  final String? busId;
  final Map<String, String> metadata;
}
