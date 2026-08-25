import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/api_payment_repository.dart';
import '../../../domain/entities/bus.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/entities/route.dart';
import '../../../domain/entities/stop.dart';
import '../../../domain/entities/ticket.dart';
import '../../../domain/entities/wallet.dart';
import '../../providers/repository_providers.dart';
import '../auth/auth_controller.dart';

/// Stages of the booking flow — drives the UI for the current step indicator
/// in the booking shell.
enum BookingStage { passenger, payment, success }

@immutable
class BookingDraft {
  const BookingDraft({
    required this.route,
    required this.from,
    required this.to,
    this.bus,
    this.passengerName,
    this.passengerPhone,
    this.passengerEmail,
    this.passengerCount = 1,
    this.paymentMethodId,
    this.stage = BookingStage.passenger,
    this.isProcessing = false,
    this.errorMessage,
    this.issuedTicket,
  });

  final BusRoute route;
  final Stop from;
  final Stop to;
  final BusDetail? bus;
  final String? passengerName;
  final String? passengerPhone;
  final String? passengerEmail;
  final int passengerCount;
  final String? paymentMethodId;
  final BookingStage stage;
  final bool isProcessing;
  final String? errorMessage;

  /// Set once payment succeeds. The success screen renders the QR from this.
  final Ticket? issuedTicket;

  num get fare => route.fare;

  num get taxes => (fare * 0.05).ceilToDouble();

  num get totalPerTicket => fare + taxes;

  num get total => totalPerTicket * passengerCount;

  bool get passengerReady =>
      (passengerName ?? '').trim().isNotEmpty &&
      (passengerPhone ?? '').trim().length >= 7;

  BookingDraft copyWith({
    String? passengerName,
    String? passengerPhone,
    String? passengerEmail,
    int? passengerCount,
    String? paymentMethodId,
    BookingStage? stage,
    bool? isProcessing,
    String? errorMessage,
    Ticket? issuedTicket,
    bool clearError = false,
  }) =>
      BookingDraft(
        route: route,
        from: from,
        to: to,
        bus: bus,
        passengerName: passengerName ?? this.passengerName,
        passengerPhone: passengerPhone ?? this.passengerPhone,
        passengerEmail: passengerEmail ?? this.passengerEmail,
        passengerCount: passengerCount ?? this.passengerCount,
        paymentMethodId: paymentMethodId ?? this.paymentMethodId,
        stage: stage ?? this.stage,
        isProcessing: isProcessing ?? this.isProcessing,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        issuedTicket: issuedTicket ?? this.issuedTicket,
      );
}

class BookingController extends Notifier<BookingDraft?> {
  @override
  BookingDraft? build() => null;

  /// Initialises a new booking draft. Called from Bus Detail / Route Detail
  /// when the user taps "Reserve a seat".
  void start({
    required BusRoute route,
    required Stop from,
    required Stop to,
    BusDetail? bus,
  }) {
    state = BookingDraft(route: route, from: from, to: to, bus: bus);
  }

  void clear() => state = null;

  void setStage(BookingStage stage) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(stage: stage, clearError: true);
  }

  void setPassenger({
    required String name,
    required String phone,
    String? email,
    int passengerCount = 1,
  }) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(
      passengerName: name,
      passengerPhone: phone,
      passengerEmail: email,
      passengerCount: passengerCount,
      clearError: true,
    );
  }

  void setPaymentMethod(String id) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(paymentMethodId: id, clearError: true);
  }

  /// Commits the booking — creates a Booking, issues a Ticket, records a
  /// Transaction, optionally debits the wallet, and moves to the success
  /// stage. Any failure sets [errorMessage] and leaves the draft intact.
  Future<bool> pay() async {
    final current = state;
    if (current == null) return false;
    final methodType = _methodTypeFor(current.paymentMethodId);
    if (methodType == null) {
      state = current.copyWith(errorMessage: 'Pick a payment method.');
      return false;
    }

    state = current.copyWith(isProcessing: true, clearError: true);

    try {
      final session = ref.read(authSessionProvider).valueOrNull;
      final userId = session?.user.id ?? 'u_guest';

      // 1. Check wallet balance before proceeding (don't debit here —
      //    the backend payment endpoint handles debit atomically).
      if (methodType == PaymentMethodType.wallet) {
        final wallet = await ref.read(walletRepositoryProvider).byUser(userId);
        if (wallet.balance < current.total) {
          state = current.copyWith(
            isProcessing: false,
            errorMessage:
                'Wallet balance too low. Top up or use another method.',
          );
          return false;
        }
      }

      // 2. Create the booking.
      final booking =
          await ref.read(bookingRepositoryProvider).createRouteBooking(
                userId: userId,
                route: current.route,
                from: current.from,
                to: current.to,
                bus: current.bus,
                seatLabels: [], // No seat selection for route-based booking
                fareOverride: current.total,
                passengerName: current.passengerName,
                passengerPhone: current.passengerPhone,
              );

      // 3. Process payment via backend API
      final paymentRequest = PaymentRequest(
        userId: userId,
        amount: current.total.toDouble(),
        methodId: current.paymentMethodId!,
        methodType: _methodTypeFor(current.paymentMethodId)!.name.toUpperCase(),
        bookingId: booking.id,
        routeId: current.route.id,
        fromStopId: current.from.id,
        toStopId: current.to.id,
        note: current.route.name,
        methodLabel: _methodLabelFor(methodType),
        passengerName: current.passengerName,
        passengerPhone: current.passengerPhone,
        passengerCount: current.passengerCount,
      );

      final paymentResponse = await ref
          .read(paymentRepositoryProvider)
          .processPayment(paymentRequest);

      if (!paymentResponse.success) {
        state = current.copyWith(
          isProcessing: false,
          errorMessage: paymentResponse.message,
        );
        return false;
      }

      // 4. Use the ticket created by the backend payment transaction.
      // The backend generates a signed QR token — use it directly.
      final ticket = paymentResponse.ticketId == null
          ? await ref.read(ticketRepositoryProvider).issueFromBooking(booking)
          : Ticket(
              id: paymentResponse.ticketId!,
              bookingId: booking.id,
              userId: userId,
              route: current.route,
              from: current.from,
              to: current.to,
              fare: current.total,
              bookedAt: DateTime.now(),
              expiresAt: paymentResponse.expiresAt ??
                  DateTime.now().toUtc().add(const Duration(hours: 4)),
              status: _ticketStatusFor(paymentResponse.ticketStatus),
              bus: current.bus,
              // Use the real signed QR token from the backend
              qrToken: paymentResponse.qrToken ??
                  'bc:ticket:${paymentResponse.ticketId}',
              seatLabels: booking.seatLabels,
              passengerName: current.passengerName,
            );

      state = current.copyWith(
        isProcessing: false,
        issuedTicket: ticket,
        stage: BookingStage.success,
      );
      ref.read(ticketRefreshProvider.notifier).state++;
      // Refresh wallet balance after payment (if paid via wallet)
      if (methodType == PaymentMethodType.wallet) {
        ref.invalidate(walletProvider);
      }
      return true;
    } catch (e) {
      state = current.copyWith(
        isProcessing: false,
        errorMessage: 'Payment failed: $e',
      );
      return false;
    }
  }

  PaymentMethodType? _methodTypeFor(String? id) => switch (id) {
        'pm_upi' => PaymentMethodType.upi,
        'pm_card' => PaymentMethodType.card,
        'pm_netbanking' => PaymentMethodType.netbanking,
        'pm_wallet' => PaymentMethodType.wallet,
        _ => null,
      };

  String _methodLabelFor(PaymentMethodType t) => switch (t) {
        PaymentMethodType.upi => 'UPI \u00b7 alex@okhdfc',
        PaymentMethodType.card => 'HDFC Credit \u00b7 4421',
        PaymentMethodType.netbanking => 'Net banking',
        PaymentMethodType.wallet => 'Bus Conductor Wallet',
      };

  TicketStatus _ticketStatusFor(String? status) {
    switch (status?.toUpperCase()) {
      case 'CONFIRMED':
      case 'ACTIVE':
        return TicketStatus.active;
      case 'VALIDATED':
        return TicketStatus.validated;
      case 'CANCELLED':
        return TicketStatus.cancelled;
      case 'EXPIRED':
        return TicketStatus.expired;
      default:
        return TicketStatus.pendingValidation;
    }
  }
}

final bookingControllerProvider =
    NotifierProvider<BookingController, BookingDraft?>(
  BookingController.new,
);

/// Wallet for the active user — watched by the payment screen.
final walletProvider = FutureProvider.autoDispose<Wallet?>((ref) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return null;
  return ref.watch(walletRepositoryProvider).byUser(session.user.id);
});
