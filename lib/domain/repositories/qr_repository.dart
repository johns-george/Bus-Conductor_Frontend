import '../entities/qr_payload.dart';

abstract class QrRepository {
  /// Parses a scanned QR string into a structured payload. Returns null if
  /// the payload is not recognised as one of ours.
  QrPayload? parse(String raw);

  /// Serialises an outgoing payload. Used by the Show-QR screens.
  String encode(QrPayload payload);
}
