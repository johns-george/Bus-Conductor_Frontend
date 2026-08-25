import 'dart:async';

/// Broadcasts when the user's session is invalid (401 after refresh fail).
/// The router listens and redirects to login.
class AuthEvents {
  AuthEvents._();
  static final _controller = StreamController<void>.broadcast();
  static Stream<void> get onAuthFailed => _controller.stream;
  static void signal() => _controller.add(null);
}
