import '../entities/payment.dart';
import '../entities/transaction.dart';

abstract class TransactionRepository {
  Future<List<AppTransaction>> byUser(String userId, {TransactionStatus? status});
  Future<AppTransaction?> byId(String id);
  Future<List<PaymentMethod>> savedMethods(String userId);
  Future<AppTransaction> retry(String transactionId);

  /// Appends a new transaction. Used by booking + wallet flows to reflect
  /// activity in the Wallet tab without waiting for a backend round trip.
  Future<AppTransaction> record(AppTransaction transaction);
}
