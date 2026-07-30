import "package:cake_wallet/bitcoin/bitcoin.dart";
import "package:cake_wallet/decred/decred.dart";
import "package:cake_wallet/entities/transaction_creation_credentials.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/exchange/provider/exchange_provider.dart";
import "package:cake_wallet/monero/monero.dart";
import "package:cake_wallet/nano/nano.dart";
import "package:cake_wallet/reactions/wallet_connect.dart";
import "package:cake_wallet/solana/solana.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/tron/tron.dart";
import "package:cake_wallet/view_model/send/output.dart";
import "package:cake_wallet/wownero/wownero.dart";
import "package:cake_wallet/zano/zano.dart";
import "package:cake_wallet/zcash/zcash.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/pending_transaction.dart";
import "package:cw_core/wallet_type.dart";

class TransactionService {
  TransactionService({required AppStore appStore}) : _appStore = appStore;

  final AppStore _appStore;

  Future<PendingTransaction> createTransaction(List<Output> outputs) async {


    final pendingTransaction = await _appStore.wallet!.createTransaction(_credentials(outputs));



    if (_appStore.wallet!.type == WalletType.bitcoin) {
      final updatedOutputs = bitcoin!.updateOutputs(pendingTransaction, outputs);

      if (outputs.length == updatedOutputs.length) {
        outputs.replaceRange(0, outputs.length, updatedOutputs);
      }
    }

    return pendingTransaction;
  }

  Object _credentials(List<Output> outputs) {
    final priority = _appStore.settingsStore.getPriority(_appStore.wallet!.type, chainId: _appStore.wallet!.chainId);


    if (priority == null &&
        ![
          WalletType.nano,
          WalletType.banano,
          WalletType.solana,
          WalletType.tron,
          WalletType.arbitrum,
          WalletType.zcash,
        ].contains(_appStore.wallet!.type)) {
      throw Exception('Priority is null for wallet type: ${_appStore.wallet!.type}');
    }

    switch (_appStore.wallet!.type) {
      case WalletType.bitcoin:
      case WalletType.bitcoinCash:
      case WalletType.dogecoin:
      final hasLightning = (outputs.first.cryptoAmountMoney.currency as CryptoCurrency) == CryptoCurrency.btcln;

      return bitcoin!.createBitcoinTransactionCredentials(
          outputs,
          priority: priority!,
          feeRate: _appStore.settingsStore.customBitcoinFeeRate,
          coinTypeToSpendFrom: hasLightning ? .lightning : .any,
        );
      case WalletType.litecoin:
        return bitcoin!.createBitcoinTransactionCredentials(
          outputs,
          priority: priority!,
          feeRate: _appStore.settingsStore.customBitcoinFeeRate,
          coinTypeToSpendFrom: .nonMweb,
        );

      case WalletType.monero:
        return monero!
            .createMoneroTransactionCreationCredentials(outputs: outputs, priority: priority!);

      case WalletType.wownero:
        return wownero!
            .createWowneroTransactionCreationCredentials(outputs: outputs, priority: priority!);

      case WalletType.ethereum:
      case WalletType.polygon:
      case WalletType.base:
      case WalletType.arbitrum:
      case WalletType.bsc:
        final selectedCryptoCurrency = outputs.first.cryptoAmountMoney.currency as CryptoCurrency;
        return evm!.createEVMTransactionCredentials(
          outputs,
          priority: priority,
          currency: selectedCryptoCurrency,
          useBlinkProtection: canSupportBlinkProtection(_appStore.wallet!.chainId)
              ? _appStore.settingsStore.useBlinkProtection
              : false,
        );
      case WalletType.nano:
        return nano!.createNanoTransactionCredentials(outputs);
      case WalletType.solana:
        final selectedCryptoCurrency = outputs.first.cryptoAmountMoney.currency as CryptoCurrency;
        return solana!
            .createSolanaTransactionCredentials(outputs, currency: selectedCryptoCurrency);
      case WalletType.tron:
        final selectedCryptoCurrency = outputs.first.cryptoAmountMoney.currency as CryptoCurrency;
        return tron!.createTronTransactionCredentials(outputs, currency: selectedCryptoCurrency);
      case WalletType.zano:
        final selectedCryptoCurrency = outputs.first.cryptoAmountMoney.currency as CryptoCurrency;

        return zano!.createZanoTransactionCredentials(
            outputs: outputs, priority: priority!, currency: selectedCryptoCurrency);
      case WalletType.decred:
        return decred!.createDecredTransactionCredentials(outputs, priority!);
      case WalletType.zcash:
        final selectedCryptoCurrency = outputs.first.cryptoAmountMoney.currency as CryptoCurrency;
        return zcash!.createZcashTransactionCredentials(
          outputs,
          currency: selectedCryptoCurrency,
        );
      default:
        throw Exception('Unexpected wallet type for send');
    }
  }

}