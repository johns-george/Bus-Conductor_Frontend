import '../entities/notification.dart';
import '../entities/user.dart';

abstract class UserRepository {
  Future<AppUser?> byId(String id);
  Future<AppUser> updateProfile(AppUser user);
  Future<List<AppNotification>> notifications(String userId);
  Future<void> markNotificationRead(String userId, String notificationId);
}
