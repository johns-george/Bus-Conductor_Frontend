import '../../core/network/api_client.dart';
import '../../domain/entities/payment.dart';

class PaymentRequest {
  final String userId;
  final double amount;
  final String methodId;
  final String methodType;
  final String bookingId;
  final String? routeId;
  final String? fromStopId;
  final String? toStopId;
  final String? note;
  final String? methodLabel;

  PaymentRequest({
    required this.userId,
    required this.amount,
    required this.methodId,
    required this.methodType,
    required this.bookingId,
    this.routeId,
    this.fromStopId,
    this.toStopId,
    this.note,
    this.methodLabel,
    this.passengerName,
    this.passengerPhone,
    this.passengerCount,
  });

  final String? passengerName;
  final String? passengerPhone;
  final int? passengerCount;

  Map<String, dynamic> toJson() => {
        'user_id': int.tryParse(userId) ?? 0,
        'amount': amount,
        'method_id': methodId,
        'method_type': methodType,
        'booking_id': bookingId,
        if (routeId != null) 'trip_id': _backendId(routeId!),
        if (fromStopId != null) 'source_stop_id': _backendId(fromStopId!),
        if (toStopId != null) 'destination_stop_id': _backendId(toStopId!),
        'seat_id': 1,
        if (note != null) 'note': note,
        if (methodLabel != null) 'method_label': methodLabel,
        if (passengerName != null) 'passenger_name': passengerName,
        if (passengerPhone != null) 'passenger_phone': passengerPhone,
        if (passengerCount != null) 'passenger_count': passengerCount,
      };

  int _backendId(String value) {
    final parsed = int.tryParse(value);
    if (parsed != null) return parsed;
    final digits = RegExp(r'\d+').firstMatch(value)?.group(0);
    return int.tryParse(digits ?? '') ?? 1;
  }
}

class PaymentResponse {
  final String transactionId;
  final String paymentId;
  final bool success;
  final String message;
  final String? ticketId;
  final String? ticketStatus;
  final String? qrToken;
  final DateTime? expiresAt;

  PaymentResponse({
    required this.transactionId,
    required this.paymentId,
    required this.success,
    required this.message,
    this.ticketId,
    this.ticketStatus,
    this.qrToken,
    this.expiresAt,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    final ticket = json['ticket'];
    return PaymentResponse(
      transactionId: json['id']?.toString() ?? '',
      paymentId: json['payment_id']?.toString() ?? '',
      success: (json['success'] as bool?) ?? false,
      message: (json['message'] as String?) ?? '',
      ticketId: ticket is Map<String, dynamic>
          ? ticket['id']?.toString()
          : json['ticket_id']?.toString(),
      ticketStatus:
          ticket is Map<String, dynamic> ? ticket['status']?.toString() : null,
      qrToken: ticket is Map<String, dynamic>
          ? ticket['qr_token']?.toString()
          : null,
      expiresAt: _parseUtc(ticket is Map<String, dynamic>
          ? ticket['expires_at']?.toString() : null),
    );
  }
}

/// Parse a datetime string from the backend (naive UTC) and force to UTC.
DateTime? _parseUtc(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final withZ = raw.endsWith('Z') ? raw : '${raw}Z';
  return DateTime.tryParse(withZ);
}

class ApiPaymentRepository {
  ApiPaymentRepository({required ApiClient apiClient}) : _apiClient = apiClient;
  final ApiClient _apiClient;

  /// Process payment for a booking
  Future<PaymentResponse> processPayment(PaymentRequest request) async {
    try {
      final response = await _apiClient.postJson(
        '/payments/process',
        body: request.toJson(),
      );

      if (response is! Map<String, dynamic>) {
        throw const ApiException(
          statusCode: 500,
          message: 'Invalid payment response',
        );
      }

      return PaymentResponse.fromJson(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: 500,
        message: 'Payment processing failed: $e',
      );
    }
  }

  /// Validate a payment method
  Future<bool> validatePaymentMethod(String methodId) async {
    try {
      final response = await _apiClient.postJson(
        '/payments/validate',
        body: {'method_id': methodId},
      );

      if (response is Map<String, dynamic>) {
        return (response['valid'] as bool?) ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get available payment methods for a user
  Future<List<PaymentMethod>> getPaymentMethods(String userId) async {
    try {
      final response = await _apiClient.getJson('/payments/methods/$userId');

      if (response is! Map<String, dynamic> || response['items'] is! List) {
        return [];
      }

      final items = response['items'] as List;
      return items.map((item) {
        final methodData = item as Map<String, dynamic>;
        return PaymentMethod(
          id: methodData['id']?.toString() ?? '',
          type: _parsePaymentType(methodData['type']?.toString() ?? ''),
          label: methodData['label']?.toString() ?? '',
          subtitle: methodData['subtitle']?.toString(),
          isDefault: (methodData['is_default'] as bool?) ?? false,
          lastFour: methodData['last_four']?.toString(),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  PaymentMethodType _parsePaymentType(String type) {
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
}
