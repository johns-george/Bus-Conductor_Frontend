import '../../core/network/api_client.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/repositories/wallet_repository.dart';

/// API-backed wallet repository.
class ApiWalletRepository implements WalletRepository {
  ApiWalletRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<Wallet> byUser(String userId) async {
    final numericId = int.tryParse(userId);
    if (numericId == null) {
      return Wallet(
        userId: userId,
        balance: 0,
        lastUpdated: DateTime.now(),
      );
    }

    try {
      final raw = await _apiClient.getJson('/wallet/$numericId');
      if (raw is! Map<String, dynamic>) {
        return Wallet(
          userId: userId,
          balance: 0,
          lastUpdated: DateTime.now(),
        );
      }

      return Wallet(
        userId: userId,
        balance: (raw['balance'] as num?) ?? 0,
        lastUpdated:
            _parseDate(raw['last_updated']) ?? DateTime.now(),
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      return Wallet(
        userId: userId,
        balance: 0,
        lastUpdated: DateTime.now(),
      );
    }
  }

  @override
  Future<Wallet> topUp({
    required String userId,
    required num amount,
  }) async {
    final numericId = int.tryParse(userId) ?? 0;

    final raw = await _apiClient.postJson(
      '/wallet/$numericId/topup',
      body: {'amount': amount.toDouble()},
    );

    if (raw is! Map<String, dynamic>) {
      throw const ApiException(
        statusCode: 500,
        message: 'Invalid wallet top-up response',
      );
    }

    return Wallet(
      userId: userId,
      balance: (raw['balance'] as num?) ?? 0,
      lastUpdated: _parseDate(raw['last_updated']) ?? DateTime.now(),
    );
  }

  @override
  Future<Wallet> topUpViaPayment({
    required String userId,
    required num amount,
    required String methodType,
    String? methodId,
    String? methodLabel,
  }) async {
    final numericId = int.tryParse(userId) ?? 0;

    final raw = await _apiClient.postJson(
      '/wallet/$numericId/topup-via-payment',
      body: {
        'amount': amount.toDouble(),
        'method_type': methodType,
        if (methodId != null) 'method_id': methodId,
        if (methodLabel != null) 'method_label': methodLabel,
      },
    );

    if (raw is! Map<String, dynamic>) {
      throw const ApiException(
        statusCode: 500,
        message: 'Invalid wallet top-up response',
      );
    }

    return Wallet(
      userId: userId,
      balance: (raw['balance'] as num?) ?? 0,
      lastUpdated: _parseDate(raw['last_updated']) ?? DateTime.now(),
    );
  }

  @override
  Future<Wallet> debit({
    required String userId,
    required num amount,
    String? note,
  }) async {
    final numericId = int.tryParse(userId) ?? 0;

    final raw = await _apiClient.postJson(
      '/wallet/$numericId/debit',
      body: {
        'amount': amount.toDouble(),
        if (note != null) 'note': note,
      },
    );

    if (raw is! Map<String, dynamic>) {
      throw const ApiException(
        statusCode: 500,
        message: 'Invalid wallet debit response',
      );
    }

    final message = raw['message']?.toString() ?? '';
    if (message.toLowerCase().contains('insufficient')) {
      throw StateError('Insufficient wallet balance');
    }

    return Wallet(
      userId: userId,
      balance: (raw['balance'] as num?) ?? 0,
      lastUpdated: _parseDate(raw['last_updated']) ?? DateTime.now(),
    );
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw is! String || raw.isEmpty) return null;
    final withZ = raw.endsWith('Z') ? raw : '${raw}Z';
    return DateTime.tryParse(withZ);
  }
}
