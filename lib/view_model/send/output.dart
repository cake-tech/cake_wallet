import 'dart:math' show min;

import 'package:cake_wallet/arbitrum/arbitrum.dart';
import 'package:cake_wallet/base/base.dart';
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/decred/decred.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/calculate_fiat_amount.dart';
import 'package:cake_wallet/entities/calculate_fiat_amount_raw.dart';
import 'package:cake_wallet/entities/contact_base.dart';
import 'package:cake_wallet/entities/parse_address_from_domain.dart';
import 'package:cake_wallet/entities/parsed_address.dart';
import 'package:cake_wallet/ethereum/ethereum.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/polygon/polygon.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/solana/solana.dart';
import 'package:cake_wallet/src/screens/send/widgets/extract_address_from_parsed.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/tron/tron.dart';
import 'package:cake_wallet/wownero/wownero.dart';
import 'package:cake_wallet/zano/zano.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:cw_core/format_fixed.dart';
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
        extractedAddress = '',
        estimatedFee = '0.0',
        parsedAddress = ParsedAddress(addresses: []) {
    autorun((_) {
      final status = _wallet.syncStatus;
      printV("Sync status changed to $status. Recalculating fees");

      calculateEstimatedFee();
    });
  }

  Key key;

  bool get useSatoshi => _appStore.amountParsingProxy.useSatoshi(cryptoCurrencyHandler());

  @observable
  String fiatAmount;

  @observable
  String cryptoAmount;

  @observable
  String cryptoFullBalance;

  @observable
  String address;

  @observable
  String note;

  @observable
  bool sendAll;

  @observable
  ParsedAddress parsedAddress;

  @observable
  String extractedAddress;

  String? memo;

  @computed
  bool get isParsedAddress =>
      parsedAddress.parseFrom != ParseFrom.notParsed && parsedAddress.name.isNotEmpty;

  @observable
  String? stealthAddress;

  @computed
  int get formattedCryptoAmount {
    int amount = 0;

    try {
      if (cryptoAmount.isNotEmpty) {
        final _cryptoAmount = cryptoAmount.replaceAll(',', '.');
        int _amount = 0;
        switch (walletType) {
          case WalletType.monero:
            _amount = monero!.formatterMoneroParseAmount(amount: _cryptoAmount);
            break;
          case WalletType.bitcoin:
          case WalletType.litecoin:
          case WalletType.bitcoinCash:
          case WalletType.dogecoin:
            _amount = _appStore.amountParsingProxy
                .parseCryptoString(_cryptoAmount, cryptoCurrencyHandler())
                .toInt();
            break;
          case WalletType.decred:
            _amount = decred!.formatterStringDoubleToDecredAmount(_cryptoAmount);
            break;
          case WalletType.ethereum:
            _amount = ethereum!.formatterEthereumParseAmount(_cryptoAmount);
            break;
          case WalletType.polygon:
            _amount = polygon!.formatterPolygonParseAmount(_cryptoAmount);
            break;
          case WalletType.base:
            _amount = base!.formatterBaseParseAmount(_cryptoAmount);
            break;
          case WalletType.arbitrum:
            _amount = arbitrum!.formatterArbitrumParseAmount(_cryptoAmount);
            break;
          case WalletType.wownero:
            _amount = wownero!.formatterWowneroParseAmount(amount: _cryptoAmount);
            break;
          case WalletType.zano:
            _amount = zano!
                .formatterParseAmount(amount: _cryptoAmount, currency: cryptoCurrencyHandler());
            break;
          case WalletType.none:
          case WalletType.haven:
          case WalletType.nano:
          case WalletType.banano:
          case WalletType.solana:
          case WalletType.tron:
            break;
        }

        if (_amount > 0) {
          amount = _amount;
        }
      }
    } catch (e) {
      amount = 0;
    }

    return amount;
  }

  @observable
  String estimatedFee;

  @action
  Future<void> calculateEstimatedFee() async {
    try {
      if (isEVMCompatibleChain(_wallet.type)) {
        await _wallet.updateEstimatedFeesParams(_settingsStore.priority[_wallet.type]!);
      }

      int fee = 0;
      if (_settingsStore.priority[_wallet.type] != null) {
        fee = _wallet.calculateEstimatedFee(
          _settingsStore.priority[_wallet.type]!,
          formattedCryptoAmount,
        );
      }

      switch (_wallet.type) {
        case WalletType.monero:
        case WalletType.wownero:
        case WalletType.litecoin:
        case WalletType.bitcoinCash:
        case WalletType.dogecoin:
        case WalletType.decred:
          estimatedFee = walletTypeToCryptoCurrency(_wallet.type).formatAmount(BigInt.from(fee));
          break;
        case WalletType.bitcoin:
          if (_settingsStore.priority[_wallet.type] ==
              bitcoin!.getBitcoinTransactionPriorityCustom()) {
            fee = bitcoin!.getEstimatedFeeWithFeeRate(
                _wallet, _settingsStore.customBitcoinFeeRate, formattedCryptoAmount);
          }

          estimatedFee = _appStore.amountParsingProxy.getCryptoString(fee, cryptoCurrencyHandler());
          break;
        case WalletType.solana:
          estimatedFee = solana!.getEstimateFees(_wallet).toString();
          break;
        case WalletType.zano:
          estimatedFee = zano!
              .formatterIntAmountToDouble(
                  amount: fee, currency: cryptoCurrencyHandler(), forFee: true)
              .toString();
          break;
        case WalletType.tron:
          if (cryptoCurrencyHandler() == CryptoCurrency.trx) {
            estimatedFee = tron!.getTronNativeEstimatedFee(_wallet).toString();
          } else {
            estimatedFee = tron!.getTronTRC20EstimatedFee(_wallet).toString();
          }
          break;

        /// EVMs
        case WalletType.ethereum:
          String? fee = cryptoCurrencyHandler() == CryptoCurrency.eth
              ? ethereum!.getEthereumNativeEstimatedFee(_wallet)
              : ethereum!.getEthereumERC20EstimatedFee(_wallet);

          estimatedFee = formatFixed(BigInt.parse(fee ?? '0.0'), 18, fractionalDigits: 12);
          break;

        case WalletType.polygon:
          String? fee = cryptoCurrencyHandler() == CryptoCurrency.maticpoly
              ? polygon!.getPolygonNativeEstimatedFee(_wallet)
              : polygon!.getPolygonERC20EstimatedFee(_wallet);

          estimatedFee = formatFixed(BigInt.parse(fee ?? '0.0'), 18, fractionalDigits: 12);
          break;

        case WalletType.base:
          String? fee = cryptoCurrencyHandler() == CryptoCurrency.baseEth
              ? base!.getBaseNativeEstimatedFee(_wallet)
              : base!.getBaseERC20EstimatedFee(_wallet);

          estimatedFee = formatFixed(BigInt.parse(fee ?? '0.0'), 18, fractionalDigits: 12);
          break;

        case WalletType.arbitrum:
          String? fee = cryptoCurrencyHandler() == CryptoCurrency.arbEth
              ? arbitrum!.getArbitrumNativeEstimatedFee(_wallet)
              : arbitrum!.getArbitrumERC20EstimatedFee(_wallet);

          estimatedFee = formatFixed(BigInt.parse(fee ?? '0.0'), 18, fractionalDigits: 12);
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
              [WalletType.solana, WalletType.tron].contains(_wallet.type))
          ? _wallet.currency
          : cryptoCurrencyHandler();

      final cryptoAmount =
          double.parse(_appStore.amountParsingProxy.getCryptoInputAmount(estimatedFee, currency));

      return calculateFiatAmountRaw(
          price: _fiatConversationStore.prices[currency]!, cryptoAmount: cryptoAmount);
    } catch (_) {
      return '0.00';
    }
  }

  @observable
  WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> _wallet;

  WalletType get walletType => _wallet.type;

  final CryptoCurrency Function() cryptoCurrencyHandler;
  final FiatConversionStore _fiatConversationStore;
  final AppStore _appStore;

  SettingsStore get _settingsStore => _appStore.settingsStore;

  @action
  void setSendAll(String fullBalance) {
    cryptoFullBalance = fullBalance;
    sendAll = true;
    _updateFiatAmount();
  }

  @action
  void updateWallet(
      WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> newWallet) {
    _wallet = newWallet;
  }

  @action
  void reset() {
    sendAll = false;
    cryptoAmount = '';
    fiatAmount = '';
    address = '';
    note = '';
    memo = null;
    resetParsedAddress();
  }

  void resetParsedAddress() {
    extractedAddress = '';
    parsedAddress = ParsedAddress(addresses: []);
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

      final fiat = calculateFiatAmount(
          price: _fiatConversationStore.prices[cryptoCurrencyHandler()]!,
          cryptoAmount: cryptoAmount_);
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
      final decimals = min(20, cryptoCurrencyHandler().decimals);
      final crypto = (double.parse(fiatAmount.replaceAll(',', '.')) /
              _fiatConversationStore.prices[cryptoCurrencyHandler()]!)
          .toStringAsFixed(decimals);

      if (cryptoAmount != crypto) cryptoAmount = crypto;
    } catch (e) {
      cryptoAmount = '';
    }
  }

  Map<String, dynamic> get extra {
    final fields = <String, dynamic>{};
    if (parsedAddress.parseFrom == ParseFrom.bip353) {
      fields['bip353_name'] = parsedAddress.name;
      fields['bip353_proof'] = parsedAddress.bip353DnsProof;
    }
    return fields;
  }

  Future<void> fetchParsedAddress(BuildContext context) async {
    final domain = address;
    final currency = cryptoCurrencyHandler();
    parsedAddress = await getIt.get<AddressResolver>().resolve(context, domain, currency);
    extractedAddress = await extractAddressFromParsed(context, parsedAddress);
    note = parsedAddress.description;
  }

  void loadContact(ContactBase contact) {
    address = contact.name;
    parsedAddress = ParsedAddress.fetchContactAddress(address: contact.address, name: contact.name);
    extractedAddress = parsedAddress.addresses.first;
    note = parsedAddress.description;
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
