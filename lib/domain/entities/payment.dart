import 'package:flutter/foundation.dart';

enum PaymentMethodType { upi, card, netbanking, wallet }

extension PaymentMethodTypeLabel on PaymentMethodType {
  String get label => switch (this) {
        PaymentMethodType.upi => 'UPI',
        PaymentMethodType.card => 'Card',
        PaymentMethodType.netbanking => 'Net banking',
        PaymentMethodType.wallet => 'Wallet',
      };
}

@immutable
class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.type,
    required this.label,
    this.subtitle,
    this.lastFour,
    this.upiId,
    this.isDefault = false,
    this.isActive = true,
    this.createdAt,
  });

  final String id;
  final PaymentMethodType type;
  final String label;
  final String? subtitle;
  final String? lastFour;
  final String? upiId;
  final bool isDefault;
  final bool isActive;
  final DateTime? createdAt;
}
