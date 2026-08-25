import 'package:flutter/foundation.dart';

enum NotificationKind { booking, ticket, payment, system, promo }

@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.kind,
    this.read = false,
    this.deeplink,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final NotificationKind kind;
  final bool read;
  final String? deeplink;
}
