import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/entities/balance_display_mode.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/evm/evm.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/solana/solana.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/tron/tron.dart';
import 'package:cake_wallet/zano/zano.dart';
import 'package:collection/collection.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_amount_format.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cake_wallet/view_model/dashboard/action_list_item.dart';
import 'package:cake_wallet/entities/calculate_fiat_amount_raw.dart';
import 'package:cake_wallet/view_model/dashboard/balance_view_model.dart';
import 'package:cw_core/keyable.dart';
import 'package:cw_core/wallet_type.dart';

class TransactionListItem extends ActionListItem with Keyable {
  TransactionListItem({
    required this.transaction,
    required this.balanceViewModel,
    required AppStore appStore,
    required super.key,
  }) : _appStore = appStore;

  final TransactionInfo transaction;
  final BalanceViewModel balanceViewModel;
  final AppStore _appStore;

  double get price => balanceViewModel.price;

  FiatCurrency get fiatCurrency => _appStore.settingsStore.fiatCurrency;

  BalanceDisplayMode get displayMode => balanceViewModel.displayMode;

  @override
  dynamic get keyIndex => transaction.id;

  bool get hasTokens =>
      isEVMCompatibleChain(balanceViewModel.wallet.type) ||
      balanceViewModel.wallet.type == WalletType.solana ||
      balanceViewModel.wallet.type == WalletType.tron;

  String get formattedCryptoAmount {
    if (displayMode == BalanceDisplayMode.hiddenBalance) return '---';
    if (balanceViewModel.wallet.type == WalletType.bitcoin) {
      final sparkToken = sparkTokenOfTransaction;
      final amount =
          sparkToken != null ? Money(transaction.amount.amount, sparkToken) : transaction.amount;
      return _appStore.amountParsingProxy
          .asDisplayStringWithSymbol(amount)
          .withLocalSeperator(_appStore.settingsStore.languageCode);
    }

    return transaction.amount.toStringWithSymbol(fractionalDigits: 8);
  }

  String get formattedTitle {
    if (balanceViewModel.wallet.type == WalletType.bitcoin &&
        transaction.additionalInfo['hasMissingInputTx'] == true) {
      return 'Transaction has missing data';
    }

    if (transaction.additionalInfo['isIronwoodMigration'] == true) {
      return 'Migration';
    }
    if (transaction.additionalInfo['isAutoShield'] == true) {
      if (transaction.isPending) {
        final status = formattedStatus;
        final baseString = S.current.shielding;
        return status.isNotEmpty ? "$baseString $status" : "$baseString...";
      }
      return S.current.shielding;
    }
    if (transaction.isPending) {
      final status = formattedStatus;
      final baseString = transaction.direction == TransactionDirection.incoming
          ? S.current.receiving
          : S.current.sending;
      return status.isNotEmpty ? "$baseString $status" : "$baseString...";
    }

    if (transaction.direction == TransactionDirection.incoming) {
      return S.current.received;
    }

    return S.current.sent;
  }

  int get neededConfirmations {
    switch (balanceViewModel.wallet.type) {
      case WalletType.monero:
      case WalletType.haven:
      case WalletType.zano:
        return 10;
      case WalletType.wownero:
        return 3;
      case WalletType.litecoin:
        bool isPegOut = (transaction.additionalInfo["isPegOut"] as bool?) ?? false;
        bool fromPegOut = (transaction.additionalInfo["fromPegOut"] as bool?) ?? false;
        if (isPegOut || fromPegOut) return 6;
      default:
        return 0;
    }
    return 0;
  }

  String get formattedPendingStatus {
    switch (balanceViewModel.wallet.type) {
      case WalletType.monero:
      case WalletType.haven:
      case WalletType.zano:
        if (transaction.confirmations >= 0 && transaction.confirmations < 10) {
          return ' (${transaction.confirmations}/10)';
        }
        break;
      case WalletType.wownero:
        if (transaction.confirmations >= 0 && transaction.confirmations < 3) {
          return ' (${transaction.confirmations}/3)';
        }
        break;
      case WalletType.litecoin:
        bool isPegIn = (transaction.additionalInfo["isPegIn"] as bool?) ?? false;
        bool isPegOut = (transaction.additionalInfo["isPegOut"] as bool?) ?? false;
        bool fromPegOut = (transaction.additionalInfo["fromPegOut"] as bool?) ?? false;
        String str = '';
        if (transaction.confirmations <= 0) {
          str = S.current.pending;
        }
        if ((isPegOut || fromPegOut) &&
            transaction.confirmations >= 0 &&
            transaction.confirmations < 6) {
          str = " (${transaction.confirmations}/6)";
        }
        if (isPegIn) {
          str += " (Mask)";
        }
        if (isPegOut) {
          str += " (Unmask)";
        }
        return str;
      default:
        return '';
    }

    return '';
  }

  String get formattedStatus {
    if ([
      WalletType.monero,
      WalletType.haven,
      WalletType.wownero,
      WalletType.litecoin,
      WalletType.zano,
    ].contains(balanceViewModel.wallet.type)) {
      return formattedPendingStatus;
    }

    return "";
  }

  String get formattedType {
    if (transaction.evmSignatureName == 'approval') {
      return ' (${transaction.evmSignatureName})';
    }
    return '';
  }

  CryptoCurrency? get assetOfTransaction {
    try {
      if (isEVMCompatibleChain(balanceViewModel.wallet.type)) {
        final asset = evm!.assetOfTransaction(balanceViewModel.wallet, transaction);
        return asset;
      }

      if (balanceViewModel.wallet.type == WalletType.solana) {
        final asset = solana!.assetOfTransaction(balanceViewModel.wallet, transaction);
        return asset;
      }

      if (balanceViewModel.wallet.type == WalletType.tron) {
        final asset = tron!.assetOfTransaction(balanceViewModel.wallet, transaction);
        return asset;
      }
    } catch (e) {
      return null;
    }

    return null;
  }

  /// The Spark token this transaction actually moved, resolved via its tagged tokenIdentifier -
  /// not via `transaction.amount.currency`'s own type, which a transaction stored before
  /// `LightningWallet.tokenCurrencyResolver` existed can still carry the wrong value for until
  /// it's re-fetched (same reasoning as `TransactionDetailsViewModelBase.transactionAsset`'s
  /// icon-resolution fix). Null for anything that isn't a Spark token payment.
  CryptoCurrency? get sparkTokenOfTransaction {
    if (balanceViewModel.wallet.type != WalletType.bitcoin) return null;
    final tokenIdentifier = transaction.additionalInfo["tokenIdentifier"] as String?;
    if (tokenIdentifier == null) return null;
    return (bitcoin?.getSparkTokenCurrencies(balanceViewModel.wallet) ?? const <CryptoCurrency>[])
        .firstWhereOrNull((token) => bitcoin?.getSparkTokenIdentifier(token) == tokenIdentifier);
  }

  String get formattedFiatAmount {
    var amount = '';

    switch (balanceViewModel.wallet.type) {
      case WalletType.bitcoin:
        // A Spark token payment (e.g. USDB) is denominated in its own currency, not the wallet's
        // native BTC - pricing it with the wallet's BTC price reads as if 1 USDB were worth 1
        // BTC. Resolved via tokenIdentifier rather than trusting transaction.amount.currency's
        // own type: a transaction stored before that currency was tagged correctly (see
        // LightningWallet.tokenCurrencyResolver) can still carry the wrong one until it's
        // re-fetched, same as assetOfTransaction's icon-resolution fix.
        final sparkToken = sparkTokenOfTransaction;
        final txPrice =
            sparkToken != null ? balanceViewModel.fiatConversionStore.prices[sparkToken] : price;
        final txAmount =
            sparkToken != null ? Money(transaction.amount.amount, sparkToken) : transaction.amount;
        // Temporary diagnostic for the $425k-instead-of-$5.05 investigation - remove once the
        // fiat mispricing is confirmed fixed on a real device.
        printV("TransactionListItem: fiat for tx=${transaction.id} "
            "amountCurrency=${transaction.amount.currency} tokenIdentifier="
            "${transaction.additionalInfo["tokenIdentifier"]} sparkToken=$sparkToken "
            "resolvedPrice=$txPrice fallbackPrice=$price");
        amount = calculateFiatAmountRaw(
          cryptoAmount: double.parse(txAmount.toString()),
          price: txPrice,
        ).withLocalSeperator(_appStore.settingsStore.languageCode);
      case WalletType.monero:
      case WalletType.wownero:
      case WalletType.litecoin:
      case WalletType.bitcoinCash:
      case WalletType.dogecoin:
      case WalletType.nano:
      case WalletType.decred:
      case WalletType.zcash:
        amount = calculateFiatAmountRaw(
          cryptoAmount: double.parse(transaction.amount.toString()),
          price: price,
        ).withLocalSeperator(_appStore.settingsStore.languageCode);
      case WalletType.ethereum:
      case WalletType.polygon:
      case WalletType.base:
      case WalletType.arbitrum:
      case WalletType.bsc:
        final asset = assetOfTransaction;
        final price = balanceViewModel.fiatConversionStore.prices[asset];
        amount = calculateFiatAmountRaw(
          cryptoAmount: double.parse(transaction.amount.toString()),
          price: price,
        ).withLocalSeperator(_appStore.settingsStore.languageCode);
        break;
      case WalletType.solana:
        final asset = solana!.assetOfTransaction(balanceViewModel.wallet, transaction);
        final price = balanceViewModel.fiatConversionStore.prices[asset];
        amount = calculateFiatAmountRaw(
          cryptoAmount: double.parse(transaction.amount.toString()),
          price: price,
        ).withLocalSeperator(_appStore.settingsStore.languageCode);
        break;
      case WalletType.tron:
        final asset = tron!.assetOfTransaction(balanceViewModel.wallet, transaction);
        final price = balanceViewModel.fiatConversionStore.prices[asset];
        amount = calculateFiatAmountRaw(
          cryptoAmount: double.parse(transaction.amount.toString()),
          price: price,
        ).withLocalSeperator(_appStore.settingsStore.languageCode);
        break;
      case WalletType.zano:
        final asset = zano!.assetOfTransaction(balanceViewModel.wallet, transaction);
        if (asset == null) {
          amount = "0.00";
          break;
        }
        final price = balanceViewModel.fiatConversionStore.prices[asset];
        amount = calculateFiatAmountRaw(
          cryptoAmount: double.parse(transaction.amount.toString()),
          price: price,
        ).withLocalSeperator(_appStore.settingsStore.languageCode);
        break;
      case WalletType.none:
      case WalletType.banano:
      case WalletType.haven:
        break;
    }

    transaction.changeFiatAmount(amount);
    return displayMode == BalanceDisplayMode.hiddenBalance
        ? '---'
        : fiatCurrency.title + ' ' + transaction.fiatAmount();
  }

  @override
  DateTime get date => transaction.date;

  @override
  bool operator ==(Object other) {
    if (other is TransactionListItem) {
      return other.transaction.txHash == transaction.txHash &&
          other.transaction.confirmations == transaction.confirmations &&
          other.transaction.isPending == transaction.isPending &&
          other.transaction.direction == transaction.direction;
    }
    return false;
  }
}
