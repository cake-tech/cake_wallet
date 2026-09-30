import "package:cw_core/address_entry.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/receive_page_option.dart";
import "package:cw_core/transaction_history.dart";
import "package:cw_core/transaction_info.dart";
import "package:cw_core/wallet_base.dart";

mixin AddressGenerationWallet<BalanceType extends Balance,
        HistoryType extends TransactionHistoryBase, TransactionType extends TransactionInfo>
    on WalletBase<BalanceType, HistoryType, TransactionType> {
  Future<String> generateNewAddress(
    ReceivePageOption type, {
    String label = "",
    bool setAsActive = false,
  });

  Future<void> setAddressLabel(AddressEntry entry, String label);
}
