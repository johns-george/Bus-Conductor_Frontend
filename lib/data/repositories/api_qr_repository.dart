import '../../core/network/api_client.dart';
import '../../domain/entities/qr_payload.dart';
import '../../domain/repositories/qr_repository.dart';

/// API-backed QR repository. Handles validation via the backend.
class ApiQrRepository implements QrRepository {
  ApiQrRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Parse a scanned QR string into a structured payload.
  /// Returns null if the payload is not one of ours.
  @override
  QrPayload? parse(String raw) {
    if (raw.isEmpty) return null;

    // Handle new dot-separated format: bc.ticket.<id>.<expiry>.<signature>
    if (raw.startsWith('bc.ticket.')) {
      final parts = raw.split('.');
      if (parts.length < 3) return null;
      return QrPayload(
        kind: QrKind.ticket,
        referenceId: parts[2],
        issuedAt: DateTime.now(),
        metadata: {
          if (parts.length > 3) 'expiry': parts[3],
          if (parts.length > 4) 'signature': parts[4],
        },
      );
    }

    // Handle legacy colon-separated format: bc:ticket:<id>:<expiry>:<signature>
    final parts = raw.split(':');
    if (parts.length < 3 || parts.first != 'bc') return null;

    final kind = switch (parts[1]) {
      'bus' => QrKind.busBoarding,
      'book' => QrKind.bookingToken,
      'ticket' => QrKind.ticket,
      _ => null,
    };
    if (kind == null) return null;

    final id = parts[2];
    return QrPayload(
      kind: kind,
      referenceId: id,
      issuedAt: DateTime.now(),
      busId: kind == QrKind.busBoarding ? id : null,
      metadata: {
        if (parts.length > 3) 'expiry': parts[3],
        if (parts.length > 4) 'signature': parts[4],
      },
    );
  }

  /// Serialise an outgoing payload. Used by the Show-QR screens.
  @override
  String encode(QrPayload payload) {
    final prefix = switch (payload.kind) {
      QrKind.busBoarding => 'bc:bus',
      QrKind.bookingToken => 'bc:book',
      QrKind.ticket => 'bc:ticket',
    };

    // If metadata contains expiry/signature, use the signed format
    if (payload.metadata.containsKey('expiry') &&
        payload.metadata.containsKey('signature')) {
      return '$prefix:${payload.referenceId}:${payload.metadata['expiry']}:${payload.metadata['signature']}';
    }

    if (payload.metadata.isEmpty) return '$prefix:${payload.referenceId}';
    final query =
        payload.metadata.entries.map((e) => '${e.key}=${e.value}').join('&');
    return '$prefix:${payload.referenceId}?$query';
  }

  /// Validate a QR token via the backend.
  Future<QrValidationResult> validate(String token) async {
    try {
      final raw = await _apiClient.postJson(
        '/qr/validate',
        body: {'token': token},
      );

      if (raw is! Map<String, dynamic>) {
        return QrValidationResult(
          valid: false,
          expired: false,
          message: 'Invalid response',
        );
      }

      return QrValidationResult(
        valid: (raw['valid'] as bool?) ?? false,
        expired: (raw['expired'] as bool?) ?? false,
        message: raw['message']?.toString() ?? '',
        ticketId: raw['ticket'] is Map<String, dynamic>
            ? raw['ticket']['id']?.toString()
            : null,
        ticketStatus: raw['ticket'] is Map<String, dynamic>
            ? raw['ticket']['status']?.toString()
            : null,
      );
    } on ApiException catch (e) {
      return QrValidationResult(
        valid: false,
        expired: false,
        message: e.message,
      );
    } catch (e) {
      return QrValidationResult(
        valid: false,
        expired: false,
        message: 'Validation failed: $e',
      );
    }
  }
}

class QrValidationResult {
  const QrValidationResult({
    required this.valid,
    required this.expired,
    required this.message,
    this.ticketId,
    this.ticketStatus,
  });

  final bool valid;
  final bool expired;
  final String message;
  final String? ticketId;
  final String? ticketStatus;
}
