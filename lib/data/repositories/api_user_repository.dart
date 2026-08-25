import '../../core/network/api_client.dart';
import '../../domain/entities/notification.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';

/// API-backed user repository.
class ApiUserRepository implements UserRepository {
  ApiUserRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<AppUser?> byId(String id) async {
    final numericId = int.tryParse(id);
    if (numericId == null) return null;

    try {
      final raw = await _apiClient.getJson('/users/$numericId');
      if (raw is! Map<String, dynamic>) return null;

      return AppUser(
        id: raw['id']?.toString() ?? id,
        displayName:
            raw['full_name']?.toString() ?? raw['username']?.toString() ?? '',
        email: raw['email']?.toString(),
        phone: raw['mobile_number']?.toString(),
        avatarUrl: raw['avatar_url']?.toString(),
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AppUser> updateProfile(AppUser user) async {
    final numericId = int.tryParse(user.id) ?? 0;

    final raw = await _apiClient.putJson(
      '/users/$numericId',
      body: {
        'full_name': user.displayName,
        'email': user.email,
        'mobile_number': user.phone,
        if (user.avatarUrl != null) 'avatar_url': user.avatarUrl,
      },
    );

    if (raw is! Map<String, dynamic>) {
      throw const ApiException(
        statusCode: 500,
        message: 'Invalid user update response',
      );
    }

    return AppUser(
      id: raw['id']?.toString() ?? user.id,
      displayName:
          raw['full_name']?.toString() ?? raw['username']?.toString() ?? user.displayName,
      email: raw['email']?.toString() ?? user.email,
      phone: raw['mobile_number']?.toString() ?? user.phone,
      avatarUrl: raw['avatar_url']?.toString() ?? user.avatarUrl,
    );
  }

  @override
  Future<List<AppNotification>> notifications(String userId) async {
    final numericId = int.tryParse(userId);
    if (numericId == null) return const [];

    try {
      final raw = await _apiClient.getJson('/users/$numericId/notifications');
      if (raw is! Map<String, dynamic> || raw['items'] is! List) return const [];

      return (raw['items'] as List)
          .whereType<Map<String, dynamic>>()
          .map(_mapNotification)
          .toList();
    } on ApiException {
      rethrow;
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> markNotificationRead(String userId, String notificationId) async {
    final numericId = int.tryParse(userId) ?? 0;

    await _apiClient.putJson(
      '/users/$numericId/notifications/$notificationId/read',
    );
  }

  AppNotification _mapNotification(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      kind: _kindFromBackend(json['kind']?.toString() ?? ''),
      read: (json['read'] as bool?) ?? false,
      deeplink: json['deeplink']?.toString(),
    );
  }

  NotificationKind _kindFromBackend(String kind) {
    switch (kind.toLowerCase()) {
      case 'booking':
        return NotificationKind.booking;
      case 'ticket':
        return NotificationKind.ticket;
      case 'payment':
        return NotificationKind.payment;
      case 'promo':
        return NotificationKind.promo;
      default:
        return NotificationKind.system;
    }
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw is! String || raw.isEmpty) return null;
    final withZ = raw.endsWith('Z') ? raw : '${raw}Z';
    return DateTime.tryParse(withZ);
  }
}
