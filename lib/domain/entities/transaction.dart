import 'package:flutter/foundation.dart';

import 'payment.dart';

enum TransactionStatus { successful, pending, failed, refunded }

extension TransactionStatusLabel on TransactionStatus {
  String get label => switch (this) {
        TransactionStatus.successful => 'Successful',
        TransactionStatus.pending => 'Pending',
        TransactionStatus.failed => 'Failed',
        TransactionStatus.refunded => 'Refunded',
      };
}

/// Transaction type — maps to the backend `type` column.
enum TransactionType { topup, debit, booking, refund }

extension TransactionTypeLabel on TransactionType {
  String get label => switch (this) {
        TransactionType.topup => 'Top-up',
        TransactionType.debit => 'Debit',
        TransactionType.booking => 'Booking',
        TransactionType.refund => 'Refund',
      };
}

@immutable
class AppTransaction {
  const AppTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.createdAt,
    required this.status,
    required this.methodType,
    this.type,
    this.bookingId,
    this.ticketId,
    this.note,
    this.methodLabel,
  });

  final String id;
  final String userId;
  final num amount;
  final DateTime createdAt;
  final TransactionStatus status;
  final PaymentMethodType methodType;
  final TransactionType? type;
  final String? bookingId;
  final String? ticketId;
  final String? note;
  final String? methodLabel;
}
