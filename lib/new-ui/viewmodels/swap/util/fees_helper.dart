import "package:cake_wallet/bitcoin/bitcoin.dart";
import "package:cake_wallet/bitcoin_cash/bitcoin_cash.dart";
import "package:cake_wallet/decred/decred.dart";
import "package:cake_wallet/dogecoin/dogecoin.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/monero/monero.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/zcash/zcash.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";

class FeesHelper {
  FeesHelper({required AppStore appStore}) : _appStore = appStore;

  final AppStore _appStore;

  WalletBase get wallet => _appStore.wallet!;

  bool get isLowFee {
    final priority = _appStore.settingsStore.getPriority(wallet.type, chainId: wallet.chainId);
    if (priority == null) {
      return false;
    }

    if (wallet.chainId == 42161) {
      return false;
    }

    switch (wallet.type) {
      case WalletType.monero:
      case WalletType.wownero:
      case WalletType.haven:
      case WalletType.zano:
        return priority == monero!.getMoneroTransactionPrioritySlow();
      case WalletType.bitcoin:
        return priority == bitcoin!.getBitcoinTransactionPrioritySlow();
      case WalletType.litecoin:
        return priority == bitcoin!.getLitecoinTransactionPrioritySlow();
      case WalletType.ethereum:
      case WalletType.polygon:
      case WalletType.base:
      case WalletType.bsc:
        return priority == evm!.getEVMTransactionPrioritySlow();
      case WalletType.bitcoinCash:
        return priority == bitcoinCash!.getBitcoinCashTransactionPrioritySlow();
      case WalletType.decred:
        return priority == decred!.getDecredTransactionPrioritySlow();
      case WalletType.dogecoin:
        return priority == dogecoin!.getDogeCoinTransactionPrioritySlow();
      case WalletType.none:
      case WalletType.nano:
      case WalletType.banano:
      case WalletType.solana:
      case WalletType.tron:
      case WalletType.arbitrum:
      case WalletType.zcash:
        return false;
    }
  }

  void setDefaultTransactionPriority() {
    switch (wallet.type) {
      case WalletType.monero:
      case WalletType.haven:
      case WalletType.wownero:
      case WalletType.zano:
        _appStore.settingsStore.setPriority(
          wallet.type,
          monero!.getMoneroTransactionPriorityAutomatic(),
        );
        break;
      case WalletType.zcash:
        _appStore.settingsStore.setPriority(
          wallet.type,
          zcash!.getZcashTransactionPriorityAutomatic(),
        );
        break;
      case WalletType.bitcoin:
        _appStore.settingsStore.setPriority(
          wallet.type,
          bitcoin!.getBitcoinTransactionPriorityMedium(),
        );
        break;
      case WalletType.litecoin:
        _appStore.settingsStore.setPriority(
          wallet.type,
          bitcoin!.getLitecoinTransactionPriorityMedium(),
        );
        break;
      case WalletType.ethereum:
      case WalletType.polygon:
      case WalletType.base:
      case WalletType.bsc:
        _appStore.settingsStore.setPriority(
          wallet.type,
          evm!.getDefaultTransactionPriority(),
          chainId: wallet.chainId,
        );
        break;
      case WalletType.bitcoinCash:
        _appStore.settingsStore.setPriority(
          wallet.type,
          bitcoinCash!.getDefaultTransactionPriority(),
        );
        break;
      case WalletType.dogecoin:
        _appStore.settingsStore.setPriority(wallet.type, dogecoin!.getDefaultTransactionPriority());
        break;
      default:
        break;
    }
  }
}
