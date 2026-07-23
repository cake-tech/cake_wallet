import "package:cake_wallet/entities/transaction_creation_credentials.dart";
import "package:cw_core/pending_transaction.dart";
import "package:cw_core/wallet_base.dart";

class TransactionService {
  TransactionService({required this.wallet});

  final WalletBase wallet;

  Future<PendingTransaction> createTransaction(TransactionCreationCredentials credentials) async {

  }
}