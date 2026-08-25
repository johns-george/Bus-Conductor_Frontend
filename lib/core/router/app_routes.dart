/// Centralised named routes so navigation calls stay type-safe and grep-able.
class AppRoutes {
  const AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';

  static const String search = '/search';
  static const String routeResults = '/routes';
  static const String routeDetail = '/routes/:routeId';

  // Reserved for later phases — wiring stubs already defined in the router so
  // deeplinks and CTA handlers can reference the names today.
  static const String home = '/home';
  static const String tickets = '/tickets';
  static const String transactions = '/transactions';
  static const String profile = '/profile';
  static const String scan = '/scan';

  static const String authWelcome = '/auth';
  static const String login = '/auth/login';
  static const String signup = '/auth/signup';
  static const String otp = '/auth/otp';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String walletTopup = '/wallet/topup';
  static const String paymentMethods = '/wallet/payment-methods';
  static const String allTransactions = '/wallet/transactions';
  static const String conductor = '/conductor';
  static const String conductorScan = '/conductor/scan';
  static const String conductorTickets = '/conductor/tickets';
  static const String admin = '/admin';
  static const String notifications = '/notifications';
  static const String help = '/help';
}
