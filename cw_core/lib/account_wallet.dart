import "package:cw_core/balance.dart";
import "package:cw_core/transaction_history.dart";
import "package:cw_core/transaction_info.dart";
import "package:cw_core/wallet_account.dart";
import "package:cw_core/wallet_base.dart";

mixin AccountWallet<B extends Balance, H extends TransactionHistoryBase, T extends TransactionInfo>
on WalletBase<B, H, T> {
  List<WalletAccount<B>> get walletAccounts;

  WalletAccount<B> get currentWalletAccount;

  List<T> get currentAccountTransactions;

  Future<void> setCurrentAccount(int accountIndex);

  Future<int> addAccount({required String label});

  Future<void> renameAccount({required int index, required String label});
}