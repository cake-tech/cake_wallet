import 'dart:math' show min;
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/core/address_resolver/address_sources.dart';
import 'package:cake_wallet/core/address_resolver/parsed_address.dart';
import 'package:cake_wallet/decred/decred.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/calculate_fiat_amount.dart';
import 'package:cake_wallet/entities/calculate_fiat_amount_raw.dart';
import 'package:cake_wallet/entities/contact_base.dart';
import 'package:cake_wallet/evm/evm.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/solana/solana.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/tron/tron.dart';
import 'package:cw_core/amount/amount_sanitizer.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/crypto_amount_format.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

part 'output.g.dart';

const String cryptoNumberPattern = '0.0';

class Output = OutputBase with _$Output;

abstract class OutputBase with Store {
  OutputBase(this._wallet, this._appStore, this._fiatConversationStore, this.cryptoCurrencyHandler)
      : key = UniqueKey(),
        sendAll = false,
        cryptoAmount = '',
        cryptoFullBalance = '',
        fiatAmount = '',
        address = '',
        note = '',
        memo = "",
        extractedAddress = '',
        estimatedFee = Money.zero(cryptoCurrencyHandler()),
        parsedAddress = ParsedAddress(parsedAddressByCurrencyMap: {}) {
    autorun((_) {
      final status = _wallet.syncStatus;
      if (status is! SyncedSyncStatus) {
        return;
      }
      calculateEstimatedFee();
    });
  }

  Key key;

  bool get useSatoshi => _appStore.amountParsingProxy.useSatoshi(cryptoCurrencyHandler());

  @observable
  bool isFiatEntry = false;

  @observable
  String fiatAmount;

  @observable
  String cryptoAmount;

  @observable
  String? displayName;

  @computed
  String get displayCryptoAmount => _appStore.amountParsingProxy.asDisplayString(cryptoAmountMoney);

  @observable
  String cryptoFullBalance;

  @observable
  String address;

  @observable
  String note;

  @observable
  String memo;

  @observable
  bool sendAll;

  @observable
  ParsedAddress parsedAddress;

  @observable
  String extractedAddress;

  @computed
  bool get isParsedAddress =>
      parsedAddress.addressSource != AddressSource.notParsed && parsedAddress.handle.isNotEmpty;

  String roundedCryptoAmount(int digits) => displayCryptoAmount.withMaxDecimals(digits);

  String roundedFiatAmount(int digits) {
    if (fiatAmount.split(".").last.length <= digits) return fiatAmount;

    return double.tryParse(fiatAmount.replaceAll(",", ""))?.toStringAsPrecision(digits) ?? '0.0';
  }

  @observable
  String? stealthAddress;

  @computed
  Money get cryptoAmountMoney {
    if (cryptoAmount.isEmpty) return Money.zero(cryptoCurrencyHandler());

    try {
      return cryptoCurrencyHandler().parseAmount(cryptoAmount.sanitized());
    } catch (e) {
      return Money.zero(cryptoCurrencyHandler());
    }
  }

  @observable
  Money estimatedFee;

  @action
  Future<void> calculateEstimatedFee() async {
    try {
      final priority = _settingsStore.getPriority(_wallet.type, chainId: _wallet.chainId);
      if (isEVMCompatibleChain(_wallet.type)) {
        await _wallet.updateEstimatedFeesParams(priority);
      }

      int fee = 0;
      if (_settingsStore.getPriority(_wallet.type, chainId: _wallet.chainId) != null) {
        fee = _wallet.calculateEstimatedFee(
          _settingsStore.getPriority(_wallet.type, chainId: _wallet.chainId)!,
          cryptoAmountMoney.amount.toInt(),
        );
      }

      switch (_wallet.type) {
        case WalletType.monero:
        case WalletType.wownero:
        case WalletType.litecoin:
        case WalletType.bitcoinCash:
        case WalletType.dogecoin:
        case WalletType.decred:
        case WalletType.zano:
          estimatedFee = Money.fromInt(fee, walletTypeToCryptoCurrency(_wallet.type));
          break;
        case WalletType.bitcoin:
          if (cryptoCurrencyHandler() == CryptoCurrency.btcln) {
            estimatedFee = Money.fromInt(10, cryptoCurrencyHandler());
            break;
          }
          if (_settingsStore.getPriority(_wallet.type) ==
              bitcoin!.getBitcoinTransactionPriorityCustom()) {
            fee = bitcoin!.getEstimatedFeeWithFeeRate(
                _wallet, _settingsStore.customBitcoinFeeRate, cryptoAmountMoney.amount.toInt());
          }

          estimatedFee = Money.fromInt(fee, cryptoCurrencyHandler());
          break;
        case WalletType.solana:
          estimatedFee = solana!.getEstimateFees(_wallet) ?? Money.zero(CryptoCurrency.sol);
          break;
        case WalletType.tron:
          if (cryptoCurrencyHandler() == CryptoCurrency.trx) {
            estimatedFee =
                tron!.getTronNativeEstimatedFee(_wallet) ?? Money.zero(CryptoCurrency.trx);
          } else {
            estimatedFee =
                tron!.getTronTRC20EstimatedFee(_wallet) ?? Money.zero(CryptoCurrency.trx);
          }
          break;

        case WalletType.zcash:
          estimatedFee = Money.fromInt(fee, cryptoCurrencyHandler());
          break;

        /// EVMs
        case WalletType.ethereum:
        case WalletType.polygon:
        case WalletType.base:
        case WalletType.arbitrum:
        case WalletType.bsc:
          final isNative = [
            CryptoCurrency.eth,
            CryptoCurrency.maticpoly,
            CryptoCurrency.baseEth,
            CryptoCurrency.arbEth,
            CryptoCurrency.bnb
          ].contains(cryptoCurrencyHandler());

          final fee = isNative
              ? evm!.getEVMNativeEstimatedFee(_wallet)
              : evm!.getEVMERC20EstimatedFee(_wallet);

          estimatedFee =
              Money(BigInt.parse(fee ?? '0.0'), walletTypeToCryptoCurrency(_wallet.type));
          break;

        /// end EVMs

        case WalletType.haven:
        case WalletType.nano:
        case WalletType.banano:
        case WalletType.none:
          // will not reach here as it doesn't have priority and this function is triggered only when priority changes
          break;
      }
    } catch (e) {
      printV(e.toString());
    }
  }

  @computed
  String get estimatedFeeFiatAmount {
    // forces mobx to rebuild the computed value
    final _ = _wallet.syncStatus;

    try {
      final currency = (isEVMCompatibleChain(_wallet.type) ||
                  [WalletType.solana, WalletType.tron].contains(_wallet.type)) ||
              cryptoCurrencyHandler() == CryptoCurrency.btcln
          ? _wallet.currency
          : cryptoCurrencyHandler();

      final cryptoAmount = double.parse(estimatedFee.toString());

      return calculateFiatAmountRaw(
          price: _fiatConversationStore.prices[currency]!, cryptoAmount: cryptoAmount);
    } catch (_) {
      return '0.00';
    }
  }

  @observable
  WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> _wallet;

  WalletType get walletType => _wallet.type;

  final CryptoCurrency Function([CryptoCurrency?]) cryptoCurrencyHandler;
  final FiatConversionStore _fiatConversationStore;
  final AppStore _appStore;

  SettingsStore get _settingsStore => _appStore.settingsStore;

  @action
  void setSendAll(String fullBalance) {
    cryptoFullBalance =
        _appStore.amountParsingProxy.getCanonicalCryptoAmount(fullBalance, cryptoCurrencyHandler());
    sendAll = true;
    _updateFiatAmount();
  }

  @action
  void updateWallet(
      WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> newWallet) {
    _wallet = newWallet;
    estimatedFee = Money.zero(cryptoCurrencyHandler());
  }

  @action
  void reset() {
    sendAll = false;
    cryptoAmount = '';
    fiatAmount = '';
    address = '';
    note = '';
    memo = "";
    resetParsedAddress();
  }

  @action
  void resetParsedAddress() {
    displayName = null;
    extractedAddress = '';
    note = '';
    parsedAddress = ParsedAddress(parsedAddressByCurrencyMap: {});
  }

  @action
  void applyAddressLookupResult(ParsedAddress result) {
    final currency = cryptoCurrencyHandler();

    parsedAddress = result;
    extractedAddress = result.parsedAddressByCurrencyMap[currency] ?? '';
    note = result.description;
    displayName = result.profileName.isNotEmpty ? result.profileName : result.handle;
  }

  @action

  /// [setCryptoAmount] always takes in the canonical representation eg. Bitcoin and not Sats
  void setCryptoAmount(String amount) {
    if (amount.toUpperCase() != S.current.all) sendAll = false;

    cryptoAmount = amount;
    _updateFiatAmount();
  }

  @action
  void setFiatAmount(String amount) {
    fiatAmount = amount;
    _updateCryptoAmount();
  }

  @action
  void _updateFiatAmount() {
    try {
      var cryptoAmount_ =
          sendAll ? cryptoFullBalance.replaceAll(",", ".") : cryptoAmount.replaceAll(',', '.');

      var cryptoCurrency = cryptoCurrencyHandler() == CryptoCurrency.btcln
          ? CryptoCurrency.btc
          : cryptoCurrencyHandler();

      final fiat = calculateFiatAmount(
          price: _fiatConversationStore.prices[cryptoCurrency]!, cryptoAmount: cryptoAmount_);
      if (fiatAmount != fiat) {
        fiatAmount = fiat;
      }
    } catch (_) {
      fiatAmount = '';
    }
  }

  @action
  void _updateCryptoAmount() {
    try {
      var cryptoCurrency = cryptoCurrencyHandler() == CryptoCurrency.btcln
          ? CryptoCurrency.btc
          : cryptoCurrencyHandler();

      final decimals = min(20, cryptoCurrencyHandler().decimals);
      final crypto = (double.parse(fiatAmount.replaceAll(',', '.')) /
              _fiatConversationStore.prices[cryptoCurrency]!)
          .toStringAsFixed(decimals);

      if (cryptoAmount != crypto) cryptoAmount = crypto;
    } catch (e) {
      printV(e);
      cryptoAmount = '';
    }
  }

  Map<String, dynamic> get extra {
    final fields = <String, dynamic>{};
    if (parsedAddress.addressSource == AddressSource.bip353) {
      fields['bip353_name'] = parsedAddress.handle;
      fields['bip353_proof'] = parsedAddress.bip353DnsProof;
    }
    return fields;
  }

  @action
  void loadContact(ContactBase contact) {
    final currency = cryptoCurrencyHandler();

    address = contact.address;
    applyAddressLookupResult(
      ParsedAddress(
        parsedAddressByCurrencyMap: {currency: contact.address},
        addressSource: AddressSource.contact,
        handle: contact.name,
        profileName: contact.name,
      ),
    );
  }
}

extension OutputCopyWith on Output {
  Output OutputCopyWithParsedAddress({
    ParsedAddress? parsedAddress,
    String? fiatAmount,
  }) {
    final clone = Output(
      _wallet,
      _appStore,
      _fiatConversationStore,
      cryptoCurrencyHandler,
    );

    clone
      ..cryptoAmount = cryptoAmount
      ..cryptoFullBalance = cryptoFullBalance
      ..note = note
      ..sendAll = sendAll
      ..memo = memo
      ..stealthAddress = stealthAddress
      ..parsedAddress = parsedAddress ?? this.parsedAddress
      ..fiatAmount = fiatAmount ?? this.fiatAmount;

    return clone;
  }
}
