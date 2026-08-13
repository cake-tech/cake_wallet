import "package:cake_wallet/bitcoin/bitcoin.dart";
import "package:cake_wallet/core/utilities.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/monero/monero.dart";
import "package:cake_wallet/reactions/wallet_connect.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/store/dashboard/fiat_conversion_store.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/unspent_coin_type.dart";
import "package:cw_core/wallet_type.dart";

class SwapAmount {
  SwapAmount({required this.cryptoAmount, required this.fiatAmount, this.isSwapAll = false}) {
    if (cryptoAmount.currency is! CryptoCurrency) {
      throw ArgumentError("cryptoAmount must be Money with CryptoCurrency");
    }
    if (fiatAmount.currency is! FiatCurrency) {
      throw ArgumentError("fiatAmount must be Money with FiatCurrency");
    }
  }

  final Money cryptoAmount;
  final Money fiatAmount;
  final bool isSwapAll;

  String get serialized => "${cryptoAmount.serialized}/${fiatAmount.serialized}";

  CryptoCurrency get currency => cryptoAmount.currency as CryptoCurrency;
}

class SwapAmountFactory {
  SwapAmountFactory({required FiatConversionStore fcs, required AppStore appStore})
    : _fcs = fcs,
      _appStore = appStore;

  final FiatConversionStore _fcs;
  final AppStore _appStore;

  bool get hasSwapAll =>
      isEVMCompatibleChain(_appStore.wallet!.type) ||
          <WalletType>[.bitcoin, .monero, .litecoin, .bitcoinCash, .dogecoin].contains(
              _appStore.wallet!.type);

  Future<Money> _getMaximumTransactionAmount(CryptoCurrency curr) async {
    if (<WalletType>[
      .litecoin,
      .bitcoin,
      .bitcoinCash,
      .dogecoin,
    ].contains(_appStore.wallet!.type)) {
      final priority = _appStore.settingsStore.getPriority(_appStore.wallet!.type)!;

      return curr == CryptoCurrency.btcln
          ? _appStore.wallet!.balance[CryptoCurrency.btcln]!.available -
          Money.fromInt(10, curr)
          : await bitcoin!.estimateFakeSendAllTxAmount(
        _appStore.wallet!,
        priority,
        coinTypeToSpendFrom: _appStore.wallet!.type == WalletType.litecoin
            ? UnspentCoinType.nonMweb
            : curr == CryptoCurrency.btcln
            ? UnspentCoinType.lightning
            : UnspentCoinType.any,
      );

    } else if (_appStore.wallet!.type == WalletType.monero) {
      return monero!.getSendingBalance(_appStore.wallet!);
    } else if (isEVMCompatibleChain(_appStore.wallet!.type)) {
      final balanceCurrency = _appStore.wallet!.balance.keys.firstWhereOrNull(
            (currency) =>
        currency.title == curr.title &&
            (currency.tag == curr.tag || currency.tag == curr.title),
      );

      final balanceForCurrency = balanceCurrency != null ? _appStore.wallet!.balance[balanceCurrency] : null;


      final isNative = curr == _appStore.wallet!.currency;

      if (!isNative) {
        return balanceForCurrency!.available;
      }

        final priority = _appStore.settingsStore.getPriority(_appStore.wallet!.type, chainId: _appStore.wallet!.chainId);
        await _appStore.wallet!.updateEstimatedFeesParams(priority);

        final  feeString = evm!.getEVMNativeEstimatedFee(_appStore.wallet!)!;


        return balanceForCurrency!.available - Money.parse(feeString, curr, isBaseUnit: true);
    } else {
      throw Exception("unsupported wallet. guard this call with hasSwapAll");
    }
  }

  Future<SwapAmount> getSwapAllAmount(CryptoCurrency curr) async {
    final amount = await _getMaximumTransactionAmount(curr);
    final fiat = _appStore.settingsStore.fiatCurrency;


    return SwapAmount(
        cryptoAmount: amount, fiatAmount: await _fcs.convert(amount, fiat), isSwapAll: true);
  }

  Future<SwapAmount> getSwapAmount(Money amount, CryptoCurrency crypto) async {
    final fiat = _appStore.settingsStore.fiatCurrency;

    if (amount.currency is FiatCurrency) {
      return SwapAmount(cryptoAmount: await _fcs.convert(amount, crypto), fiatAmount: amount);
    } else {
      return SwapAmount(cryptoAmount: amount, fiatAmount: await _fcs.convert(amount, fiat));
    }
  }
}
