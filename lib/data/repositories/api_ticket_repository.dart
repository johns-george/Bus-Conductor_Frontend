import '../../core/network/api_client.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/route.dart';
import '../../domain/entities/stop.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/repositories/stop_repository.dart';
import '../../domain/repositories/ticket_repository.dart';
// CancelTicketResult is re-exported from ticket_repository.dart

class ApiTicketRepository implements TicketRepository {
  ApiTicketRepository({
    required ApiClient apiClient,
    required StopRepository stopRepository,
  })  : _apiClient = apiClient,
        _stopRepository = stopRepository;

  final ApiClient _apiClient;
  final StopRepository _stopRepository;
  final Map<String, String> _routeNameCache = <String, String>{};

  @override
  Future<Ticket?> byId(String id) async {
    final ticketId = int.tryParse(id);
    if (ticketId == null) return null;
    try {
      final raw =
          await _apiClient.getJson('/tickets/get-ticket-details/$ticketId');
      if (raw is! Map<String, dynamic>) return null;
      return _mapTicket(raw, fallbackUserId: 'unknown');
    } on ApiException {
      rethrow;
    }
  }

  @override
  Future<List<Ticket>> byUser(String userId) async {
    final numericUserId = int.tryParse(userId);
    if (numericUserId == null) {
      return const <Ticket>[];
    }
    final raw =
        await _apiClient.getJson('/tickets/get-all-tickets/$numericUserId');
    if (raw is! List) return const <Ticket>[];
    final results = <Ticket>[];
    for (final item in raw.whereType<Map<String, dynamic>>()) {
      final mapped = await _mapTicket(item, fallbackUserId: userId);
      if (mapped != null) results.add(mapped);
    }
    return results;
  }

  @override
  Future<Ticket> issueFromBooking(Booking booking) async {
    final userId = int.tryParse(booking.userId);
    final fromId = int.tryParse(booking.from.id);
    final toId = int.tryParse(booking.to.id);
    final tripId = int.tryParse(booking.route.id) ?? 1;
    if (userId == null || fromId == null || toId == null) {
      throw const ApiException(
        statusCode: 400,
        message: 'Booking identifiers are not backend-compatible integers',
      );
    }

    final raw = await _apiClient.postJson(
      '/tickets/book-ticket',
      query: {
        'user_id': '$userId',
        'trip_id': '$tripId',
        'seat_id': '1',
        'source_stop_id': '$fromId',
        'destination_stop_id': '$toId',
        'price': '${booking.fare}',
      },
    );
    if (raw is! Map<String, dynamic>) {
      throw const ApiException(
        statusCode: 500,
        message: 'Invalid ticket payload',
      );
    }
    final mapped = await _mapTicket(raw, fallbackUserId: booking.userId);
    if (mapped == null) {
      throw const ApiException(
        statusCode: 500,
        message: 'Could not map booked ticket',
      );
    }
    return mapped;
  }

  @override
  Future<Ticket> markValidated(String ticketId) async {
    final id = int.tryParse(ticketId);
    if (id == null) {
      throw const ApiException(statusCode: 400, message: 'Invalid ticket id');
    }
    final raw = await _apiClient.putJson(
      '/tickets/update-ticket/$id',
      body: {'status': 'VALIDATED'},
    );
    if (raw is! Map<String, dynamic>) {
      throw const ApiException(
        statusCode: 500,
        message: 'Invalid ticket payload',
      );
    }
    final mapped = await _mapTicket(raw, fallbackUserId: 'unknown');
    if (mapped == null) {
      throw const ApiException(
        statusCode: 500,
        message: 'Could not map ticket',
      );
    }
    return mapped.copyWith(
      status: TicketStatus.validated,
      validatedAt: DateTime.now(),
    );
  }

  @override
  Future<CancelTicketResult> cancelTicket(String ticketId) async {
    final id = int.tryParse(ticketId);
    if (id == null) {
      return const CancelTicketResult(
        success: false,
        errorMessage: 'Invalid ticket id',
      );
    }

    try {
      final raw = await _apiClient.postJson('/tickets/cancel-ticket/$id');
      if (raw is! Map<String, dynamic>) {
        return const CancelTicketResult(
          success: false,
          errorMessage: 'Invalid cancel response',
        );
      }

      final refund = raw['refund'];
      return CancelTicketResult(
        success: true,
        refundAmount: refund is Map<String, dynamic>
            ? (refund['amount'] as num?)
            : null,
        walletBalance: refund is Map<String, dynamic>
            ? (refund['wallet_balance'] as num?)
            : null,
      );
    } on ApiException catch (e) {
      return CancelTicketResult(
        success: false,
        errorMessage: e.message,
      );
    } catch (e) {
      return CancelTicketResult(
        success: false,
        errorMessage: 'Cancel failed: $e',
      );
    }
  }

  Future<Ticket?> _mapTicket(
    Map<String, dynamic> json, {
    required String fallbackUserId,
  }) async {
    final idValue = json['id'];
    if (idValue == null) return null;
    final sourceId = json['source_stop_id']?.toString() ?? '';
    final destinationId = json['destination_stop_id']?.toString() ?? '';
    final source =
        await _stopRepository.byId(sourceId) ?? _unknownStop(sourceId);
    final destination = await _stopRepository.byId(destinationId) ??
        _unknownStop(destinationId);

    final routeId = json['trip_id']?.toString() ?? 'route_unknown';
    final routeName = await _routeName(routeId);
    final route = BusRoute(
      id: routeId,
      name: routeName,
      origin: source,
      destination: destination,
      distanceKm: 1,
      fare: (json['price'] as num?) ?? 0,
      stops: [source, destination],
      tags: const ['Live'],
    );

    final bookedAt = _parseDate(json['booking_time']) ?? DateTime.now();
    final expiresAt = _parseDate(json['expires_at']) ??
        bookedAt.add(const Duration(hours: 4));
    final statusRaw = (json['status'] ?? '').toString().toUpperCase();

    return Ticket(
      id: idValue.toString(),
      bookingId: idValue.toString(),
      userId: json['user_id']?.toString() ?? fallbackUserId,
      route: route,
      from: source,
      to: destination,
      fare: (json['price'] as num?) ?? 0,
      bookedAt: bookedAt,
      expiresAt: expiresAt,
      status: _statusFromBackend(statusRaw),
      qrToken: json['qr_token']?.toString() ?? 'bc:ticket:${idValue.toString()}',
      passengerName: json['passenger_name']?.toString(),
      passengerPhone: json['passenger_phone']?.toString(),
      passengerCount: (json['passenger_count'] as num?)?.toInt() ?? 1,
    );
  }

  TicketStatus _statusFromBackend(String status) {
    switch (status) {
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

  /// Backend uses Python's datetime.utcnow() which produces naive UTC
  /// datetimes without timezone suffix. Dart interprets these as local time,
  /// causing expiry comparisons to be off by the UTC offset.
  /// Force all parsed datetimes to UTC.
  DateTime? _parseDate(dynamic raw) {
    if (raw is! String || raw.isEmpty) return null;
    // Backend sends naive UTC without Z suffix.
    // Append Z so Dart parses it as UTC directly (not local time).
    final withZ = raw.endsWith('Z') ? raw : '${raw}Z';
    return DateTime.tryParse(withZ);
  }

  Future<String> _routeName(String routeId) async {
    if (routeId.isEmpty || routeId == 'route_unknown') return 'Route';
    final cached = _routeNameCache[routeId];
    if (cached != null) return cached;

    try {
      final raw = await _apiClient.getJson('/routes/$routeId');
      if (raw is Map<String, dynamic>) {
        final name = raw['name']?.toString().trim();
        if (name != null && name.isNotEmpty) {
          _routeNameCache[routeId] = name;
          return name;
        }
      }
    } catch (_) {
      // Keep tickets visible even if route detail lookup fails.
    }

    final fallback = 'Route $routeId';
    _routeNameCache[routeId] = fallback;
    return fallback;
  }

  @override
  Future<Ticket> editTicket({
    required String ticketId,
    String? passengerName,
    String? passengerPhone,
    int? passengerCount,
  }) async {
    final id = int.tryParse(ticketId);
    if (id == null) {
      throw const ApiException(statusCode: 400, message: 'Invalid ticket id');
    }
    final body = <String, dynamic>{};
    if (passengerName != null) body['passenger_name'] = passengerName;
    if (passengerPhone != null) body['passenger_phone'] = passengerPhone;
    if (passengerCount != null) body['passenger_count'] = passengerCount;
    if (body.isEmpty) {
      throw const ApiException(statusCode: 400, message: 'Nothing to update');
    }
    final raw = await _apiClient.putJson('/tickets/update-ticket/$id', body: body);
    if (raw is! Map<String, dynamic>) {
      throw const ApiException(statusCode: 500, message: 'Invalid ticket response');
    }
    final mapped = await _mapTicket(raw, fallbackUserId: 'unknown');
    if (mapped == null) {
      throw const ApiException(statusCode: 500, message: 'Could not map updated ticket');
    }
    return mapped;
  }

  Stop _unknownStop(String id) {
    return Stop(
      id: id.isEmpty ? 'unknown' : id,
      name: 'Stop $id',
      city: 'Unknown',
    );
  }
}
