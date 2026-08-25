import '../../core/network/api_client.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_method_repository.dart';

class ApiPaymentMethodRepository implements PaymentMethodRepository {
  ApiPaymentMethodRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  PaymentMethod _parse(Map<String, dynamic> raw) {
    return PaymentMethod(
      id: raw['id'].toString(),
      type: PaymentMethodType.values.firstWhere(
        (t) => t.name.toUpperCase() == (raw['method_type'] ?? '').toUpperCase(),
        orElse: () => PaymentMethodType.upi,
      ),
      label: (raw['label'] ?? '').toString(),
      subtitle: raw['subtitle']?.toString(),
      lastFour: raw['last_four']?.toString(),
      upiId: raw['upi_id']?.toString(),
      isDefault: raw['is_default'] == true,
      isActive: raw['is_active'] != false,
      createdAt: _parseDate(raw['created_at']),
    );
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw is! String || raw.isEmpty) return null;
    final withZ = raw.endsWith('Z') ? raw : '${raw}Z';
    return DateTime.tryParse(withZ);
  }

  @override
  Future<List<PaymentMethod>> listByUser(String userId) async {
    final numericId = int.tryParse(userId);
    if (numericId == null) return [];

    try {
      final raw = await _apiClient.getJson('/payment-methods/$numericId');
      if (raw is! List) return [];
      return raw
          .map((e) => _parse(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<PaymentMethod> create({
    required String userId,
    required PaymentMethodType type,
    required String label,
    String? subtitle,
    String? provider,
    String? lastFour,
    String? upiId,
    bool isDefault = false,
  }) async {
    final numericId = int.tryParse(userId) ?? 0;

    final raw = await _apiClient.postJson(
      '/payment-methods/$numericId',
      body: {
        'method_type': type.name.toUpperCase(),
        'label': label,
        if (subtitle != null) 'subtitle': subtitle,
        if (provider != null) 'provider': provider,
        if (lastFour != null) 'last_four': lastFour,
        if (upiId != null) 'upi_id': upiId,
        'is_default': isDefault,
      },
    );

    if (raw is! Map<String, dynamic>) {
      throw const ApiException(statusCode: 500, message: 'Invalid response');
    }
    return _parse(raw);
  }

  @override
  Future<PaymentMethod> update({
    required String userId,
    required int methodId,
    String? label,
    String? subtitle,
    bool? isDefault,
  }) async {
    final numericUserId = int.tryParse(userId) ?? 0;

    final raw = await _apiClient.putJson(
      '/payment-methods/$numericUserId/$methodId',
      body: {
        if (label != null) 'label': label,
        if (subtitle != null) 'subtitle': subtitle,
        if (isDefault != null) 'is_default': isDefault,
      },
    );

    if (raw is! Map<String, dynamic>) {
      throw const ApiException(statusCode: 500, message: 'Invalid response');
    }
    return _parse(raw);
  }

  @override
  Future<void> delete({
    required String userId,
    required int methodId,
  }) async {
    final numericUserId = int.tryParse(userId) ?? 0;
    await _apiClient.deleteJson('/payment-methods/$numericUserId/$methodId');
  }

  @override
  Future<PaymentMethod> setDefault({
    required String userId,
    required int methodId,
  }) async {
    final numericUserId = int.tryParse(userId) ?? 0;

    final raw = await _apiClient.postJson(
      '/payment-methods/$numericUserId/$methodId/set-default',
      body: {},
    );

    if (raw is! Map<String, dynamic>) {
      throw const ApiException(statusCode: 500, message: 'Invalid response');
    }
    return _parse(raw);
  }
}
