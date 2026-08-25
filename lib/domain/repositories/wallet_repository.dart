import '../entities/wallet.dart';

/// Wallet balance + pre-paid passes. In the real backend this maps to
/// user-linked balance ledgers; here it's a per-user in-memory cache.
abstract class WalletRepository {
  Future<Wallet> byUser(String userId);
  Future<Wallet> topUp({required String userId, required num amount});
  Future<Wallet> topUpViaPayment({
    required String userId,
    required num amount,
    required String methodType,
    String? methodId,
    String? methodLabel,
  });
  Future<Wallet> debit({required String userId, required num amount, String? note});
}
