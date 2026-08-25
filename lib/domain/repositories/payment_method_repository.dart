import '../entities/payment.dart';

abstract class PaymentMethodRepository {
  Future<List<PaymentMethod>> listByUser(String userId);
  Future<PaymentMethod> create({
    required String userId,
    required PaymentMethodType type,
    required String label,
    String? subtitle,
    String? provider,
    String? lastFour,
    String? upiId,
    bool isDefault = false,
  });
  Future<PaymentMethod> update({
    required String userId,
    required int methodId,
    String? label,
    String? subtitle,
    bool? isDefault,
  });
  Future<void> delete({required String userId, required int methodId});
  Future<PaymentMethod> setDefault({required String userId, required int methodId});
}
