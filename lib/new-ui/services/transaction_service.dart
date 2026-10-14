import "package:cake_wallet/bitcoin/bitcoin.dart";
import "package:cake_wallet/core/utilities.dart";
import "package:cake_wallet/decred/decred.dart";
import "package:cake_wallet/entities/preferences_key.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/main.dart";
import "package:cake_wallet/monero/monero.dart";
import "package:cake_wallet/nano/nano.dart";
import "package:cake_wallet/reactions/wallet_connect.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/solana/solana.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/tron/tron.dart";
import "package:cake_wallet/view_model/send/output.dart";
import "package:cake_wallet/wownero/wownero.dart";
import "package:cake_wallet/zano/zano.dart";
import "package:cake_wallet/zcash/zcash.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/pending_transaction.dart";
import "package:cw_core/transaction_direction.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";

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

  // TODO(malik): i think it would be nice to have a createCredentials virtual method on WalletBase. all the wallets use it anyway
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
      throw Exception("Priority is null for wallet type: ${_appStore.wallet!.type}");
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
        throw Exception("Unexpected wallet type for send");
    }
  }

  Future<void> commitTransaction(PendingTransaction transaction) async {

      if (transaction.shouldCommitUR()) {
        await _commitUR(navigatorKey.currentContext!, transaction);
      } else {
        await transaction.commit();
      }



      if (_appStore.wallet!.type == WalletType.solana) {
        Future.delayed(const Duration(seconds: 1), () async {
          try {
            await solana!.pollForTransaction(
              _appStore.wallet!,
              transaction.id,
              initialDelay: const Duration(seconds: 1),
              maxRetries: 5,
            );
          } catch (e) {
            printV("Failed to poll for transaction: $e");
          }
        });

      }

      // Immediate transaction update for EVM chains, Tron, and Nano
      if (isEVMCompatibleChain(_appStore.wallet!.type) ||
          [WalletType.bitcoin, WalletType.solana, WalletType.tron, WalletType.nano]
              .contains(_appStore.wallet!.type)) {
        Future.delayed(const Duration(seconds: 4), () async {
          try {
            await Future.wait([
              _appStore.wallet!.updateTransactionsHistory(),
              _appStore.wallet!.updateBalance() as Future<void>,
            ]);
          } catch (e) {
            printV("Failed to update transactions after send: $e");
          }
        });
      }

      // FIXME(malik) ideally, this should be done wallet-side.
      // it is required because evm, solana and tron don't actually save the transaction info when you send something.
      // instead, they rely on the tx to eventually get fetched at sync time, which can take a while
      if (isEVMCompatibleChain(_appStore.wallet!.type)) {
        final selectedToken = evm!.getERC20Currencies(_appStore.wallet!).firstWhereOrNull(
              (token) => token.title.toUpperCase() == (transaction.amount.currency as CryptoCurrency).title.toUpperCase(),
        );

        _appStore.wallet!.transactionHistory.addOne(evm!.getTransactionInfo(
          id: transaction.evmTxHashFromRawHex!,
          height: 0,
          amount: transaction.amount,
          fee: transaction.fee,
          tokenSymbol: (transaction.amount.currency as CryptoCurrency).title,
          direction: TransactionDirection.outgoing,
          isPending: true,
          date: DateTime.now(),
          confirmations: 0,
          chainId: _appStore.wallet!.chainId ?? 0,
          contractAddress: selectedToken?.contractAddress,
        ));
      }

      if (_appStore.wallet!.type == WalletType.solana) {
        _appStore.wallet!.transactionHistory.addOne(solana!.getTransactionInfo(
          id: transaction.id,
          blockTime: DateTime.now(),
          to: "",
          from: "",
          direction: TransactionDirection.outgoing,
          amount: transaction.amount,
          isPending: true,
          fee: transaction.fee,
        ));
      }

      if (_appStore.wallet!.type == WalletType.tron) {
        _appStore.wallet!.transactionHistory.addOne(tron!.getTransactionInfo(
          id: transaction.id,
          blockTime: DateTime.now(),
          direction: TransactionDirection.outgoing,
          amount: transaction.amount,
          isPending: true,
          fee: transaction.fee,
        ));
      }

      final sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences.setString(PreferencesKey.backgroundSyncLastTrigger(_appStore.wallet!.name),
          DateTime.now().add(const Duration(minutes: 1)).toIso8601String());
  }

  Future<void> _commitUR(BuildContext context, PendingTransaction transaction) async {
    final urstr = await transaction.commitUR();
    if (context.mounted) {
      final result = await Navigator.of(context).pushNamed(
          Routes.urqrAnimatedPage, arguments: urstr);
      if (result == null) {
        throw Exception("Canceled by user");
      }
    }
  }
}
