import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/bus.dart';
import '../../domain/entities/route.dart';
import '../../domain/entities/stop.dart';
import '../../presentation/features/auth/auth_welcome_screen.dart';
import '../../presentation/features/auth/forgot_email_screen.dart';
import '../../presentation/features/auth/forgot_password_screen.dart';
import '../../presentation/features/auth/login_screen.dart';
import '../../presentation/features/auth/otp_screen.dart';
import '../../presentation/features/auth/reset_password_screen.dart';
import '../../presentation/features/auth/signup_screen.dart';
import '../../presentation/features/booking/booking_controller.dart';
import '../../presentation/features/booking/passenger_details_screen.dart';
import '../../presentation/features/booking/payment_screen.dart';
import '../../presentation/features/booking/route_booking_screen.dart';
import '../../presentation/features/bus_detail/bus_detail_screen.dart';
import '../../presentation/features/home/home_screen.dart';
import '../../presentation/features/onboarding/onboarding_screen.dart';
import '../../presentation/features/profile/profile_screen.dart';
import '../../presentation/features/results/route_results_screen.dart';
import '../../presentation/features/route_detail/route_detail_screen.dart';
import '../../presentation/features/scan/scan_screen.dart';
import '../../presentation/features/search/route_search_screen.dart';
import '../../presentation/features/shell/main_shell.dart';
import '../../presentation/features/splash/splash_screen.dart';
import '../../presentation/features/tickets/ticket_detail_screen.dart';
import '../../presentation/features/tickets/tickets_screen.dart';
import '../../presentation/features/wallet/wallet_screen.dart';
import '../../presentation/features/wallet/wallet_topup_payment_screen.dart';
import '../../presentation/features/wallet/payment_methods_screen.dart';
import '../../presentation/features/wallet/transactions_screen.dart';
import '../../presentation/features/conductor/conductor_screen.dart';
import '../../presentation/features/conductor/conductor_scan_screen.dart';
import '../../presentation/features/conductor/conductor_tickets_screen.dart';
import '../../presentation/features/notifications/notifications_screen.dart';
import '../../presentation/features/help/help_screen.dart';
import '../../presentation/features/admin/admin_screen.dart';
import '../theme/app_spacing.dart';
import '../../presentation/providers/repository_providers.dart';
import 'app_routes.dart';

/// Convenience: pass a typed arg in `extra` and grab it back type-safely.
class RouteResultsArgs {
  RouteResultsArgs({required this.from, required this.to, this.date});
  final Stop from;
  final Stop to;
  final DateTime? date;
}

/// Typed args for the Bus Detail screen so the booking flow has full route
/// context when the user taps "Reserve a seat".
class BusDetailArgs {
  BusDetailArgs({
    required this.detail,
    this.route,
    this.from,
    this.to,
  });

  final BusDetail detail;
  final BusRoute? route;
  final Stop? from;
  final Stop? to;
}

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final repo = ref.read(authRepositoryProvider);
      final session = repo.currentSession;
      final isLoggedIn = session != null;

      // Public paths that don't require auth
      final publicPaths = {
        '/', // splash
        AppRoutes.onboarding,
        AppRoutes.authWelcome,
        '${AppRoutes.authWelcome}/login',
        '${AppRoutes.authWelcome}/signup',
        '${AppRoutes.authWelcome}/otp',
        '${AppRoutes.authWelcome}/forgot-password',
        '${AppRoutes.authWelcome}/forgot-email',
        '${AppRoutes.authWelcome}/reset-password',
      };

      final isPublic = publicPaths.contains(location);

      // Logged-in user trying to access auth pages → send to home
      if (isLoggedIn && isPublic && location != '/') {
        return '/home';
      }

      // Not logged in trying to access protected pages → send to auth
      if (!isLoggedIn && !isPublic) {
        return '/auth';
      }

      return null; // no redirect
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        pageBuilder: (context, state) => _fade(state, const SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        pageBuilder: (context, state) =>
            _fade(state, const OnboardingScreen()),
      ),

      // Auth stack — kept outside the shell so it can't be accidentally tabbed
      // onto, and so the bottom nav doesn't show during sign-in.
      GoRoute(
        path: AppRoutes.authWelcome,
        name: 'authWelcome',
        pageBuilder: (context, state) =>
            _fade(state, const AuthWelcomeScreen()),
        routes: [
          GoRoute(
            path: 'login',
            name: 'login',
            pageBuilder: (context, state) => _slide(state, const LoginScreen()),
          ),
          GoRoute(
            path: 'signup',
            name: 'signup',
            pageBuilder: (context, state) =>
                _slide(state, const SignupScreen()),
          ),
          GoRoute(
            path: 'otp',
            name: 'otp',
            pageBuilder: (context, state) => _slide(state, const OtpScreen()),
          ),
          GoRoute(
            path: 'forgot-password',
            name: 'forgotPassword',
            pageBuilder: (context, state) => _slide(state, const ForgotPasswordScreen()),
          ),
          GoRoute(
            path: 'forgot-email',
            name: 'forgotEmail',
            pageBuilder: (context, state) => _slide(state, const ForgotEmailScreen()),
          ),
          GoRoute(
            path: 'reset-password',
            name: 'resetPassword',
            pageBuilder: (context, state) => _slide(state, const ResetPasswordScreen()),
          ),
        ],
      ),

      // Top-level flows outside the shell (search, results, details).
      GoRoute(
        path: AppRoutes.search,
        name: 'search',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) =>
            _slide(state, const RouteSearchScreen()),
      ),
      GoRoute(
        path: AppRoutes.routeResults,
        name: 'routeResults',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) {
          final args = state.extra as RouteResultsArgs?;
          if (args == null) {
            return _fade(
              state,
              const _RouterFallback(message: 'Missing search parameters.'),
            );
          }
          return _slide(
            state,
            RouteResultsScreen(
              from: args.from,
              to: args.to,
              date: args.date,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.routeDetail,
        name: 'routeDetail',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) {
          final id = state.pathParameters['routeId'] ?? '';
          final initial = state.extra is RouteSearchResult
              ? state.extra as RouteSearchResult
              : null;
          return _slide(
            state,
            RouteDetailScreen(routeId: id, initialResult: initial),
          );
        },
      ),
      GoRoute(
        path: '/bus/:busId',
        name: 'busDetail',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) {
          final id = state.pathParameters['busId'] ?? '';
          BusDetail? initial;
          BusRoute? route;
          Stop? from;
          Stop? to;
          final extra = state.extra;
          if (extra is BusDetailArgs) {
            initial = extra.detail;
            route = extra.route;
            from = extra.from;
            to = extra.to;
          } else if (extra is BusDetail) {
            initial = extra;
          }
          return _slide(
            state,
            BusDetailScreen(
              busId: id,
              initialDetail: initial,
              route: route,
              from: from,
              to: to,
            ),
          );
        },
      ),

      // Booking flow (route booking → passenger → payment → success). The
      // draft state lives in `bookingControllerProvider`; these screens just
      // render the current stage.
      GoRoute(
        path: '/booking/route',
        name: 'bookingRoute',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) =>
            _slide(state, const RouteBookingScreen()),
      ),
      GoRoute(
        path: '/booking/passenger',
        name: 'bookingPassenger',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) =>
            _slide(state, const PassengerDetailsScreen()),
      ),
      GoRoute(
        path: '/booking/payment',
        name: 'bookingPayment',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) =>
            _slide(state, const PaymentScreen()),
      ),
      GoRoute(
        path: AppRoutes.admin,
        name: 'admin',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) =>
            _fade(state, const AdminScreen()),
      ),
      GoRoute(
        path: AppRoutes.conductor,
        name: 'conductor',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) =>
            _fade(state, const ConductorScreen()),
      ),
      GoRoute(
        path: AppRoutes.conductorScan,
        name: 'conductorScan',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) =>
            _fade(state, const ConductorScanScreen()),
      ),
      GoRoute(
        path: AppRoutes.conductorTickets,
        name: 'conductorTickets',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) =>
            _fade(state, const ConductorTicketsScreen()),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) =>
            _slide(state, const NotificationsScreen()),
      ),
      GoRoute(
        path: AppRoutes.help,
        name: 'help',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) =>
            _slide(state, const HelpScreen()),
      ),
      GoRoute(
        path: AppRoutes.paymentMethods,
        name: 'paymentMethods',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) =>
            _slide(state, const PaymentMethodsScreen()),
      ),
      GoRoute(
        path: AppRoutes.allTransactions,
        name: 'allTransactions',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) =>
            _slide(state, const TransactionsScreen()),
      ),
      GoRoute(
        path: AppRoutes.walletTopup,
        name: 'walletTopup',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) {
          final amount = state.extra as num? ?? 0;
          return _slide(state, WalletTopupPaymentScreen(amount: amount));
        },
      ),
      GoRoute(
        path: '/booking/success',
        name: 'bookingSuccess',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) {
          // Pulls the freshly-issued ticket id from the booking draft on
          // landing so the success screen can hit the ticket detail view.
          return _fade(state, const _BookingSuccessRedirect());
        },
      ),
      GoRoute(
        path: '/ticket/:ticketId',
        name: 'ticketDetail',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) {
          final id = state.pathParameters['ticketId'] ?? '';
          return _slide(state, TicketDetailScreen(ticketId: id));
        },
      ),

      // Main app shell with bottom navigation. Each branch keeps its own
      // navigation stack so tab switches preserve state.
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootKey,
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellKey,
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: 'home',
                pageBuilder: (context, state) =>
                    _fade(state, const HomeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.tickets,
                name: 'tickets',
                pageBuilder: (context, state) =>
                    _fade(state, const TicketsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.transactions,
                name: 'transactions',
                pageBuilder: (context, state) =>
                    _fade(state, const WalletScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                name: 'profile',
                pageBuilder: (context, state) =>
                    _fade(state, const ProfileScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
    errorPageBuilder: (context, state) => _fade(
      state,
      _RouterFallback(message: 'We can\u2019t find that screen.\n${state.uri}'),
    ),
  );
});

CustomTransitionPage<T> _fade<T>(GoRouterState state, Widget child) =>
    CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: AppDurations.fast,
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    );

CustomTransitionPage<T> _slide<T>(GoRouterState state, Widget child) =>
    CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: AppDurations.base,
      transitionsBuilder: (_, animation, __, child) {
        final tween = Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: animation.drive(tween), child: child),
        );
      },
    );

class _RouterFallback extends StatelessWidget {
  const _RouterFallback({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: AppSpacing.pageAll,
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }
}

/// Reads the freshly issued ticket id from the booking draft and renders the
/// [TicketDetailScreen] in success mode. The draft is cleared once the user
/// has seen their ticket, so navigating back doesn't replay the flow.
class _BookingSuccessRedirect extends ConsumerWidget {
  const _BookingSuccessRedirect();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticket = ref.watch(bookingControllerProvider)?.issuedTicket;
    if (ticket == null) {
      return const _RouterFallback(
        message: 'Booking has no issued ticket. Please retry payment.',
      );
    }
    return TicketDetailScreen(ticketId: ticket.id, showSuccess: true);
  }
}

