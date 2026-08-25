import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_events.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../data/repositories/api_auth_repository.dart';
import '../../data/repositories/api_booking_repository.dart';
import '../../data/repositories/api_bus_repository.dart';
import '../../data/repositories/api_payment_repository.dart';
import '../../data/repositories/api_qr_repository.dart';
import '../../data/repositories/api_route_repository.dart';
import '../../data/repositories/api_stop_repository.dart';
import '../../data/repositories/api_ticket_repository.dart';
import '../../data/repositories/api_transaction_repository.dart';
import '../../data/repositories/api_user_repository.dart';
import '../../data/repositories/api_wallet_repository.dart';
import '../../data/repositories/api_payment_method_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../domain/repositories/bus_repository.dart';
import '../../domain/repositories/qr_repository.dart';
import '../../domain/repositories/route_repository.dart';
import '../../domain/repositories/stop_repository.dart';
import '../../domain/repositories/ticket_repository.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../../domain/repositories/payment_method_repository.dart';

/// All repositories are now backed by the real backend API.
final ApiClient _apiClient = ApiClient(baseUrl: ApiConfig.baseUrl);

final apiClientProvider = Provider<ApiClient>((ref) {
  // When any API call fails with 401 after refresh, signal auth failure
  _apiClient.onAuthFailed = () => AuthEvents.signal();
  return _apiClient;
});
final ApiStopRepository _stopRepo = ApiStopRepository(_apiClient);
final ApiRouteRepository _routeRepo = ApiRouteRepository(apiClient: _apiClient);
final ApiBusRepository _busRepo = ApiBusRepository(apiClient: _apiClient);
final ApiAuthRepository _authRepo = ApiAuthRepository(_apiClient);
final ApiBookingRepository _bookingRepo = ApiBookingRepository();
final ApiTicketRepository _ticketRepo = ApiTicketRepository(
  apiClient: _apiClient,
  stopRepository: _stopRepo,
);
final ApiTransactionRepository _transactionRepo = ApiTransactionRepository(apiClient: _apiClient);
final ApiQrRepository _qrRepo = ApiQrRepository(apiClient: _apiClient);
final ApiUserRepository _userRepo = ApiUserRepository(apiClient: _apiClient);
final ApiWalletRepository _walletRepo = ApiWalletRepository(apiClient: _apiClient);

final stopRepositoryProvider = Provider<StopRepository>((ref) => _stopRepo);

final routeRepositoryProvider = Provider<RouteRepository>((ref) => _routeRepo);

final busRepositoryProvider = Provider<BusRepository>((ref) => _busRepo);

final authRepositoryProvider = Provider<AuthRepository>((ref) => _authRepo);

final bookingRepositoryProvider = Provider<BookingRepository>((ref) => _bookingRepo);

final ticketRepositoryProvider = Provider<TicketRepository>((ref) => _ticketRepo);

final ticketRefreshProvider = StateProvider<int>((ref) => 0);

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) => _transactionRepo);

final qrRepositoryProvider = Provider<QrRepository>((ref) => _qrRepo);

final userRepositoryProvider = Provider<UserRepository>((ref) => _userRepo);

final walletRepositoryProvider = Provider<WalletRepository>((ref) => _walletRepo);

final paymentRepositoryProvider = Provider<ApiPaymentRepository>((ref) {
  return ApiPaymentRepository(apiClient: _apiClient);
});

final paymentMethodRepositoryProvider = Provider<PaymentMethodRepository>((ref) {
  return ApiPaymentMethodRepository(apiClient: _apiClient);
});
