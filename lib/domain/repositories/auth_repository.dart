import '../entities/user.dart';

/// Contract for authentication. Mock and real implementations must honour
/// the same semantics so screens can swap backends freely.
abstract class AuthRepository {
  Stream<AuthSession?> watchSession();
  AuthSession? get currentSession;

  Future<AuthSession> loginWithEmail({
    required String email,
    required String password,
  });

  Future<AuthSession> loginWithGoogle();

  Future<String> requestOtp({required String phone, required String country});
  Future<AuthSession> verifyOtp({required String requestId, required String code});

  Future<AuthSession> signupWithEmail({
    required String name,
    required String email,
    required String password,
    String? mobileNumber,
    String role = 'USER',
  });

  Future<AuthSession> signupWithPhone({
    required String name,
    required String phone,
    required String country,
  });

  Future<String> requestPasswordReset({required String email});
  Future<void> resetPassword({required String token, required String password});

  Future<void> logout();

  /// Update the current session's user (e.g. after profile edit).
  Future<void> updateUser(AppUser user);
}
