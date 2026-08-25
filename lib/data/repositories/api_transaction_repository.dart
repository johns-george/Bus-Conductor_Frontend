import '../../core/network/api_client.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
// TransactionType is re-exported from transaction.dart

/// API-backed transaction repository.
class ApiTransactionRepository implements TransactionRepository {
  ApiTransactionRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<AppTransaction>> byUser(
    String userId, {
    TransactionStatus? status,
  }) async {
    final numericId = int.tryParse(userId);
    if (numericId == null) return const [];

    try {
      final raw = await _apiClient.getJson('/transactions/user/$numericId');
      if (raw is! Map<String, dynamic> || raw['items'] is! List) return const [];

      final items = (raw['items'] as List)
          .whereType<Map<String, dynamic>>()
          .map(_mapTransaction)
          .where((t) => status == null || t.status == status)
          .toList();
      return items;
    } on ApiException {
      rethrow;
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<AppTransaction?> byId(String id) async {
    try {
      final raw = await _apiClient.getJson('/transactions/$id');
      if (raw is! Map<String, dynamic>) return null;
      return _mapTransaction(raw);
    } on ApiException {
      rethrow;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<PaymentMethod>> savedMethods(String userId) async {
    final numericId = int.tryParse(userId);
    if (numericId == null) return const [];

    try {
      final raw =
          await _apiClient.getJson('/transactions/user/$numericId/payment-methods');
      if (raw is! Map<String, dynamic> || raw['items'] is! List) return const [];

      return (raw['items'] as List)
          .whereType<Map<String, dynamic>>()
          .map(_mapPaymentMethod)
          .toList();
    } on ApiException {
      rethrow;
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<AppTransaction> retry(String transactionId) async {
    final raw = await _apiClient.postJson('/transactions/$transactionId/retry');
    if (raw is! Map<String, dynamic>) {
      throw const ApiException(statusCode: 500, message: 'Invalid retry response');
    }
    return _mapTransaction(raw);
  }

  @override
  Future<AppTransaction> record(AppTransaction transaction) async {
    final raw = await _apiClient.postJson(
      '/transactions',
      body: {
        'user_id': int.tryParse(transaction.userId) ?? 0,
        'amount': transaction.amount,
        'status': transaction.status.name.toUpperCase(),
        'method_type': transaction.methodType.name.toUpperCase(),
        if (transaction.bookingId != null) 'booking_id': transaction.bookingId,
        if (transaction.ticketId != null) 'ticket_id': transaction.ticketId,
        if (transaction.note != null) 'note': transaction.note,
        if (transaction.methodLabel != null)
          'method_label': transaction.methodLabel,
      },
    );
    if (raw is! Map<String, dynamic>) {
      throw const ApiException(
          statusCode: 500, message: 'Invalid transaction response');
    }
    return _mapTransaction(raw);
  }

  AppTransaction _mapTransaction(Map<String, dynamic> json) {
    return AppTransaction(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      amount: (json['amount'] as num?) ?? 0,
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      status: _statusFromBackend(json['status']?.toString() ?? ''),
      methodType: _methodTypeFromBackend(
        json['method_type']?.toString() ?? json['payment_method']?.toString() ?? '',
      ),
      type: _typeFromBackend(json['type']?.toString()),
      bookingId: json['booking_id']?.toString(),
      ticketId: json['ticket_id']?.toString(),
      note: json['note']?.toString(),
      methodLabel: json['method_label']?.toString(),
    );
  }

  PaymentMethod _mapPaymentMethod(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id']?.toString() ?? '',
      type: _paymentTypeFromBackend(json['type']?.toString() ?? ''),
      label: json['label']?.toString() ?? '',
      subtitle: json['subtitle']?.toString(),
      isDefault: (json['is_default'] as bool?) ?? false,
      lastFour: json['last_four']?.toString(),
    );
  }

  TransactionStatus _statusFromBackend(String status) {
    switch (status.toUpperCase()) {
      case 'SUCCESSFUL':
        return TransactionStatus.successful;
      case 'PENDING':
        return TransactionStatus.pending;
      case 'FAILED':
        return TransactionStatus.failed;
      case 'REFUNDED':
        return TransactionStatus.refunded;
      default:
        return TransactionStatus.pending;
    }
  }

  PaymentMethodType _methodTypeFromBackend(String type) {
    switch (type.toUpperCase()) {
      case 'UPI':
        return PaymentMethodType.upi;
      case 'CARD':
        return PaymentMethodType.card;
      case 'NETBANKING':
        return PaymentMethodType.netbanking;
      case 'WALLET':
        return PaymentMethodType.wallet;
      default:
        return PaymentMethodType.upi;
    }
  }

  PaymentMethodType _paymentTypeFromBackend(String type) =>
      _methodTypeFromBackend(type);

  TransactionType? _typeFromBackend(String? type) {
    if (type == null) return null;
    switch (type.toUpperCase()) {
      case 'TOPUP':
        return TransactionType.topup;
      case 'DEBIT':
        return TransactionType.debit;
      case 'BOOKING':
        return TransactionType.booking;
      case 'REFUND':
        return TransactionType.refund;
      default:
        return null;
    }
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw is! String || raw.isEmpty) return null;
    final withZ = raw.endsWith('Z') ? raw : '${raw}Z';
    return DateTime.tryParse(withZ);
  }
}
