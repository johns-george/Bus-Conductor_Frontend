import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user.dart';
import '../../../domain/repositories/auth_exception.dart';
import '../../providers/repository_providers.dart';

/// Live session stream. Screens (and the router redirect) read this to know if
/// the user is signed in. Guest mode is represented by `null`.
final authSessionProvider = StreamProvider<AuthSession?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.watchSession();
});

@immutable
class AuthFormState {
  const AuthFormState({
    this.isSubmitting = false,
    this.errorMessage,
    this.pendingOtpRequestId,
    this.pendingPhone,
    this.pendingCountry,
    this.pendingName,
  });

  final bool isSubmitting;
  final String? errorMessage;

  /// When set, OTP screen can call [AuthController.verifyOtp].
  final String? pendingOtpRequestId;
  final String? pendingPhone;
  final String? pendingCountry;
  final String? pendingName;

  AuthFormState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    String? pendingOtpRequestId,
    String? pendingPhone,
    String? pendingCountry,
    String? pendingName,
    bool clearPending = false,
  }) =>
      AuthFormState(
        isSubmitting: isSubmitting ?? this.isSubmitting,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        pendingOtpRequestId: clearPending
            ? null
            : (pendingOtpRequestId ?? this.pendingOtpRequestId),
        pendingPhone: clearPending ? null : (pendingPhone ?? this.pendingPhone),
        pendingCountry:
            clearPending ? null : (pendingCountry ?? this.pendingCountry),
        pendingName: clearPending ? null : (pendingName ?? this.pendingName),
      );
}

class AuthController extends Notifier<AuthFormState> {
  @override
  AuthFormState build() => const AuthFormState();

  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    return _run(() async {
      await ref
          .read(authRepositoryProvider)
          .loginWithEmail(email: email, password: password);
    });
  }

  Future<bool> loginWithGoogle() async {
    return _run(() async {
      await ref.read(authRepositoryProvider).loginWithGoogle();
    });
  }

  Future<bool> signupWithEmail({
    required String name,
    required String email,
    required String password,
    String? mobileNumber,
    String role = 'USER',
  }) async {
    return _run(() async {
      await ref.read(authRepositoryProvider).signupWithEmail(
            name: name,
            email: email,
            password: password,
            mobileNumber: mobileNumber,
            role: role,
          );
    });
  }

  /// Starts phone-based signup flow. On success the caller should push the OTP
  /// screen which reads [AuthFormState.pendingOtpRequestId].
  Future<bool> requestOtp({
    required String name,
    required String phone,
    required String country,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final id = await ref
          .read(authRepositoryProvider)
          .requestOtp(phone: phone, country: country);
      state = state.copyWith(
        isSubmitting: false,
        pendingOtpRequestId: id,
        pendingPhone: phone,
        pendingCountry: country,
        pendingName: name,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _messageOf(e),
      );
      return false;
    }
  }

  Future<bool> verifyOtp(String code) async {
    final requestId = state.pendingOtpRequestId;
    if (requestId == null) {
      state = state.copyWith(errorMessage: 'Request a new code and try again.');
      return false;
    }
    return _run(() async {
      await ref
          .read(authRepositoryProvider)
          .verifyOtp(requestId: requestId, code: code);
      state = state.copyWith(clearPending: true);
    });
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    ref.invalidate(authSessionProvider);
    state = const AuthFormState();
  }

  void clearError() {
    if (state.errorMessage == null) return;
    state = state.copyWith(clearError: true);
  }

  Future<bool> _run(Future<void> Function() action) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await action();
      ref.invalidate(authSessionProvider);
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _messageOf(e),
      );
      return false;
    }
  }

  String _messageOf(Object e) {
    if (e is AuthException) return e.message;
    return 'Something went wrong. Please try again.';
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthFormState>(AuthController.new);
