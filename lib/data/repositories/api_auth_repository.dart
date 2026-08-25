import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_exception.dart';
import '../../domain/repositories/auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._apiClient);

  final ApiClient _apiClient;

  final Uuid _uuid = const Uuid();

  final StreamController<AuthSession?> _controller =
      StreamController<AuthSession?>.broadcast();

  /// SINGLETON Google Sign-In instance
  /// Prevents repeated GSI client initialization on Flutter Web
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: ApiConfig.googleClientId,
    scopes: ['email'],
  );

  AuthSession? _session;
  bool _restoreAttempted = false;

  @override
  AuthSession? get currentSession => _session;

  @override
  Stream<AuthSession?> watchSession() async* {
    // On first access, try to restore session from cookie
    if (!_restoreAttempted && _session == null) {
      _restoreAttempted = true;
      await _tryRestoreSession();
    }
    yield _session;
    yield* _controller.stream;
  }

  /// Try to restore the session from the httponly cookie.
  Future<void> _tryRestoreSession() async {
    try {
      final response = await _apiClient.getJson('/auth/me');
      if (response is Map<String, dynamic> && response['user'] != null) {
        final user = response['user'] as Map<String, dynamic>;
        final now = DateTime.now();
        final session = AuthSession(
          user: AppUser(
            id: user['id']?.toString() ?? '',
            displayName: user['full_name']?.toString() ?? user['username']?.toString() ?? 'User',
            email: user['email']?.toString() ?? '',
            phone: user['mobile_number']?.toString(),
            role: user['role']?.toString(),
            createdAt: now,
          ),
          token: 'restored',
          issuedAt: now,
          expiresAt: now.add(const Duration(days: 7)),
        );
        _session = session;
        _controller.add(session);
      }
    } catch (_) {
      // Not logged in or cookie expired — that's fine
    }
  }

  // =========================================================
  // EMAIL LOGIN
  // =========================================================

  @override
  Future<AuthSession> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.postForm(
        '/auth/sign-in',
        body: {
          'username': email,
          'password': password,
        },
      );

      return _issueSessionFromResponse(
        response,
        email: email,
        displayName: _nameFromEmail(email),
      );
    } on ApiException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      print('❌ Email login error: $e');
      throw const AuthException('Login failed');
    }
  }

  // =========================================================
  // GOOGLE LOGIN
  // =========================================================

  @override
  Future<AuthSession> loginWithGoogle() async {
    try {
      if (ApiConfig.googleClientId.isEmpty) {
        throw const AuthException(
          'Google Sign-In is not configured yet. '
          'Run with --dart-define=GOOGLE_CLIENT_ID=YOUR_ID',
        );
      }

      print('🔍 Starting Google Sign-In process');

      // Prevent stale web sessions
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      // Trigger Google login popup
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // User closed popup
      if (googleUser == null) {
        throw const AuthException('Google sign in was cancelled');
      }

      // Fetch auth tokens
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw const AuthException(
          'Google authentication failed — no ID token received',
        );
      }

      // Send ID token to backend for verification and session creation
      final response = await _apiClient.postJson(
        '/auth/google',
        body: {'idToken': idToken},
      );

      return _issueSessionFromResponse(
        response,
        email: googleUser.email,
        displayName: googleUser.displayName ?? 'Google User',
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      if (e.toString().contains('popup_closed') ||
          e.toString().contains('cancelled')) {
        throw const AuthException('Google sign in was cancelled');
      }
      throw AuthException('Google sign in failed: $e');
    }
  }

  // =========================================================
  // LOGOUT
  // =========================================================

  @override
  Future<void> logout() async {
    try {
      await _apiClient.postJson('/auth/logout');
    } catch (_) {}

    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    _session = null;
    _restoreAttempted = false;

    _controller.add(null);
  }

  // =========================================================
  // UPDATE USER
  // =========================================================

  @override
  Future<void> updateUser(AppUser user) async {
    final current = _session;
    if (current == null) return;
    final updated = AuthSession(
      user: user,
      token: current.token,
      issuedAt: current.issuedAt,
      expiresAt: current.expiresAt,
    );
    _session = updated;
    _controller.add(updated);
  }

  // =========================================================
  // OTP / PASSWORD PLACEHOLDERS
  // =========================================================

  @override
  Future<String> requestOtp({
    required String phone,
    required String country,
  }) async {
    try {
      final response = await _apiClient.postJson(
        '/auth/request-otp',
        body: {'phone': phone, 'country': country},
      );
      if (response is Map<String, dynamic>) {
        return response['request_id']?.toString() ?? '';
      }
      return '';
    } on ApiException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw const AuthException('Failed to send OTP');
    }
  }

  @override
  Future<String> requestPasswordReset({
    required String email,
  }) async {
    try {
      final response = await _apiClient.postJson(
        '/auth/password-reset/request',
        body: {'email': email},
      );
      if (response is Map<String, dynamic>) {
        return response['reset_token']?.toString() ?? '';
      }
      return '';
    } on ApiException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw const AuthException('Failed to send reset instructions');
    }
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    try {
      await _apiClient.postJson(
        '/auth/password-reset/confirm',
        body: {'token': token, 'password': password},
      );
    } on ApiException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw const AuthException('Password reset failed');
    }
  }

  // =========================================================
  // SIGNUP
  // =========================================================

  @override
  Future<AuthSession> signupWithEmail({
    required String name,
    required String email,
    required String password,
    String? mobileNumber,
    String role = 'USER',
  }) async {
    final username = email.split('@').first;

    try {
      final response = await _apiClient.postJson(
        '/auth/sign-up',
        body: {
          'username': username,
          'password': password,
          'email': email,
          'full_name': name,
          'mobile_number': mobileNumber,
          'role': role,
        },
      );

      return _issueSessionFromResponse(
        response,
        email: email,
        displayName: name,
      );
    } on ApiException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      print('❌ Signup error: $e');
      throw const AuthException('Signup failed');
    }
  }

  @override
  Future<AuthSession> signupWithPhone({
    required String name,
    required String phone,
    required String country,
  }) async {
    throw const AuthException(
      'Phone signup API is not available yet',
    );
  }

  @override
  Future<AuthSession> verifyOtp({
    required String requestId,
    required String code,
  }) async {
    try {
      final response = await _apiClient.postJson(
        '/auth/verify-otp',
        body: {'request_id': requestId, 'code': code},
      );
      return _issueSessionFromResponse(
        response,
        email: response is Map<String, dynamic>
            ? (response['user'] is Map<String, dynamic>
                ? response['user']['email']?.toString() ?? ''
                : '')
            : '',
        displayName: response is Map<String, dynamic>
            ? (response['user'] is Map<String, dynamic>
                ? response['user']['full_name']?.toString() ?? 'Phone User'
                : 'Phone User')
            : 'Phone User',
      );
    } on ApiException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw const AuthException('OTP verification failed');
    }
  }

  // =========================================================
  // LOCAL SESSION CREATOR
  // =========================================================

  AuthSession _issueSession({
    required String email,
    required String displayName,
  }) {
    final now = DateTime.now();

    final session = AuthSession(
      user: AppUser(
        id: _fallbackUserId(email),
        displayName: displayName,
        email: email,
        createdAt: now,
      ),
      token: _uuid.v4(),
      issuedAt: now,
      expiresAt: now.add(
        const Duration(days: 7),
      ),
    );

    _session = session;

    _controller.add(session);

    return session;
  }

  AuthSession _issueSessionFromResponse(
    dynamic response, {
    required String email,
    required String displayName,
  }) {
    if (response is! Map<String, dynamic>) {
      return _issueSession(email: email, displayName: displayName);
    }

    final user = response['user'];
    final now = DateTime.now();
    final session = AuthSession(
      user: AppUser(
        id: user is Map<String, dynamic>
            ? user['id']?.toString() ?? _fallbackUserId(email)
            : _fallbackUserId(email),
        displayName: user is Map<String, dynamic>
            ? user['full_name']?.toString() ?? displayName
            : displayName,
        email: user is Map<String, dynamic>
            ? user['email']?.toString() ?? email
            : email,
        phone: user is Map<String, dynamic>
            ? user['mobile_number']?.toString()
            : null,
        role: user is Map<String, dynamic>
            ? user['role']?.toString()
            : null,
        createdAt: now,
      ),
      token: response['access_token']?.toString() ?? _uuid.v4(),
      issuedAt: now,
      expiresAt: now.add(const Duration(days: 7)),
    );

    _session = session;
    _controller.add(session);
    return session;
  }

  String _fallbackUserId(String email) =>
      'u_${email.hashCode.toUnsigned(32).toRadixString(16)}';

  // =========================================================
  // HELPERS
  // =========================================================

  String _nameFromEmail(String email) {
    final local = email.split('@').first.replaceAll(RegExp(r'[._-]+'), ' ');

    if (local.isEmpty) {
      return 'Traveller';
    }

    return local.split(' ').map((part) {
      if (part.isEmpty) return part;

      return part[0].toUpperCase() + part.substring(1);
    }).join(' ');
  }
}
