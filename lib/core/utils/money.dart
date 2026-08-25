import 'package:intl/intl.dart';

class Money {
  const Money._();

  static final NumberFormat _inr = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '\u20B9',
    decimalDigits: 0,
  );

  /// Formats fares. All seeded data is in INR; swap in locale-aware logic when
  /// multi-currency support lands.
  static String format(num amount) => _inr.format(amount);
}
