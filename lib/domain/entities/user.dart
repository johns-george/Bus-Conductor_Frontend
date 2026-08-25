import 'package:flutter/foundation.dart';

@immutable
class AppUser {
  const AppUser({
    required this.id,
    required this.displayName,
    this.email,
    this.phone,
    this.avatarUrl,
    this.role,
    this.createdAt,
  });

  final String id;
  final String displayName;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String? role;
  final DateTime? createdAt;

  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).isEmpty ? '?' : (first + last).toUpperCase();
  }

  AppUser copyWith({
    String? displayName,
    String? email,
    String? phone,
    String? avatarUrl,
    String? role,
  }) =>
      AppUser(
        id: id,
        displayName: displayName ?? this.displayName,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        role: role ?? this.role,
        createdAt: createdAt,
      );
}

@immutable
class AuthSession {
  const AuthSession({
    required this.user,
    required this.token,
    required this.issuedAt,
    required this.expiresAt,
  });

  final AppUser user;
  final String token;
  final DateTime issuedAt;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt.toUtc());
}
