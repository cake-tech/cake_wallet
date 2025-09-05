import 'package:cake_wallet/decred/decred.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/calculate_fiat_amount_raw.dart';
import 'package:cake_wallet/entities/contact.dart';
import 'package:cake_wallet/entities/contact_record.dart';
import 'package:cake_wallet/address_resolver/address_resolver_service.dart';
import 'package:cake_wallet/address_resolver/parsed_address.dart';
import 'package:cake_wallet/ethereum/ethereum.dart';
import 'package:cake_wallet/polygon/polygon.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/solana/solana.dart';
import 'package:cake_wallet/src/screens/send/widgets/extract_address_from_parsed.dart';
import 'package:cake_wallet/tron/tron.dart';
import 'package:cake_wallet/wownero/wownero.dart';
import 'package:cake_wallet/zano/zano.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/entities/calculate_fiat_amount.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/bitcoin/bitcoin.dart';

import 'package:cake_wallet/entities/contact_base.dart';

part 'output.g.dart';

const String cryptoNumberPattern = '0.0';

class Output = OutputBase with _$Output;

abstract class OutputBase with Store {
  OutputBase(
      this._wallet, this._settingsStore, this._fiatConversationStore, this.cryptoCurrencyHandler)
      : _cryptoNumberFormat = NumberFormat(cryptoNumberPattern),
      _resolver = getIt<AddressResolverService>(),
  key = UniqueKey(),
        sendAll = false,
        cryptoAmount = '',
        cryptoFullBalance = '',
        fiatAmount = '',
        address = '',
        note = '',
        extractedAddress = '',
        parsedAddress = ParsedAddress(parsedAddressByCurrencyMap: {}) {

    _setCryptoNumMaximumFractionDigits();
  }

  final AddressResolverService _resolver;

  Key key;

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
      parsedAddress.addressSource != AddressSource.notParsed && parsedAddress.handle != null;

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
            _amount = bitcoin!.formatterStringDoubleToBitcoinAmount(_cryptoAmount);
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

  @computed
  double get estimatedFee {
    try {
      if (_wallet.type == WalletType.tron) {
        if (cryptoCurrencyHandler() == CryptoCurrency.trx) {
          final nativeEstimatedFee = tron!.getTronNativeEstimatedFee(_wallet) ?? 0;
          return double.parse(nativeEstimatedFee.toString());
        } else {
          final trc20EstimatedFee = tron!.getTronTRC20EstimatedFee(_wallet) ?? 0;
          return double.parse(trc20EstimatedFee.toString());
        }
      }

      if (_wallet.type == WalletType.solana) {
        return solana!.getEstimateFees(_wallet) ?? 0.0;
      }

      int? fee = _wallet.calculateEstimatedFee(
          _settingsStore.priority[_wallet.type]!, formattedCryptoAmount);

      if (_wallet.type == WalletType.bitcoin) {
        if (_settingsStore.priority[_wallet.type] ==
            bitcoin!.getBitcoinTransactionPriorityCustom()) {
          fee = bitcoin!.getEstimatedFeeWithFeeRate(
              _wallet, _settingsStore.customBitcoinFeeRate, formattedCryptoAmount);
        }

        return bitcoin!.formatterBitcoinAmountToDouble(amount: fee);
      }

      if (_wallet.type == WalletType.litecoin || _wallet.type == WalletType.bitcoinCash ||
          _wallet.type == WalletType.dogecoin) {
        return bitcoin!.formatterBitcoinAmountToDouble(amount: fee);
      }

      if (_wallet.type == WalletType.monero) {
        return monero!.formatterMoneroAmountToDouble(amount: fee);
      }

      if (_wallet.type == WalletType.wownero) {
        return wownero!.formatterWowneroAmountToDouble(amount: fee);
      }

      if (_wallet.type == WalletType.ethereum) {
        return ethereum!.formatterEthereumAmountToDouble(amount: BigInt.from(fee));
      }

      if (_wallet.type == WalletType.polygon) {
        return polygon!.formatterPolygonAmountToDouble(amount: BigInt.from(fee));
      }

      if (_wallet.type == WalletType.zano) {
        return zano!.formatterIntAmountToDouble(
            amount: fee, currency: cryptoCurrencyHandler(), forFee: true);
      }

      if (_wallet.type == WalletType.decred) {
        return decred!.formatterDecredAmountToDouble(amount: fee);
      }
    } catch (e) {
      printV(e.toString());
    }

    return 0;
  }

  @computed
  String get estimatedFeeFiatAmount {
    try {
      final currency = (isEVMCompatibleChain(_wallet.type) ||
              _wallet.type == WalletType.solana ||
              _wallet.type == WalletType.tron)
          ? _wallet.currency
          : cryptoCurrencyHandler();
      final fiat = calculateFiatAmountRaw(
          price: _fiatConversationStore.prices[currency]!, cryptoAmount: estimatedFee);
      return fiat;
    } catch (_) {
      return '0.00';
    }
  }

  WalletType get walletType => _wallet.type;
  final CryptoCurrency Function() cryptoCurrencyHandler;
  final WalletBase _wallet;
  final SettingsStore _settingsStore;
  final FiatConversionStore _fiatConversationStore;
  final NumberFormat _cryptoNumberFormat;

  @action
  void setSendAll(String fullBalance) {
    cryptoFullBalance = fullBalance;
    sendAll = true;
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
    parsedAddress = ParsedAddress(parsedAddressByCurrencyMap: {});
  }

  @action
  void setCryptoAmount(String amount) {
    if (amount.toUpperCase() != S.current.all) {
      sendAll = false;
    }

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
      final fiat = calculateFiatAmount(
          price: _fiatConversationStore.prices[cryptoCurrencyHandler()]!,
          cryptoAmount:
              sendAll ? cryptoFullBalance.replaceAll(",", ".") : cryptoAmount.replaceAll(',', '.'));
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
      final crypto = double.parse(fiatAmount.replaceAll(',', '.')) /
          _fiatConversationStore.prices[cryptoCurrencyHandler()]!;
      final cryptoAmountTmp = _cryptoNumberFormat.format(crypto);
      if (cryptoAmount != cryptoAmountTmp) {
        cryptoAmount = cryptoAmountTmp;
      }
    } catch (e) {
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

  void _setCryptoNumMaximumFractionDigits() {
    var maximumFractionDigits = 0;

    switch (_wallet.type) {
      case WalletType.monero:
      case WalletType.ethereum:
      case WalletType.polygon:
      case WalletType.solana:
      case WalletType.tron:
      case WalletType.haven:
      case WalletType.zano:
      case WalletType.nano:
      case WalletType.decred:
        maximumFractionDigits = 12;
        break;
      case WalletType.bitcoin:
      case WalletType.litecoin:
      case WalletType.bitcoinCash:
      case WalletType.dogecoin:
        maximumFractionDigits = 8;
        break;
      case WalletType.wownero:
        maximumFractionDigits = 11;
        break;
      case WalletType.none:
      case WalletType.banano:
        break;
    }

    _cryptoNumberFormat.maximumFractionDigits = maximumFractionDigits;
  }

  Future<void> fetchParsedAddress(BuildContext context) async {
    final domain = address;
    final currency = cryptoCurrencyHandler();
    final parsedAddresses = await _resolver.resolve(
      query: domain,
      wallet: _wallet,
      currency: currency,);
    if (parsedAddresses.isNotEmpty) {
      parsedAddress = parsedAddresses.first;
      extractedAddress = parsedAddress.parsedAddressByCurrencyMap[currency] ?? '';
      note = parsedAddress.description ?? '';
    }
  }

  void loadContact((String, String) selectedContact) {
    address = selectedContact.$1;
    parsedAddress =
        ParsedAddress(parsedAddressByCurrencyMap: {}, addressSource: AddressSource.contact);
    extractedAddress = selectedContact.$2;
    note = parsedAddress.description ?? '';
  }
}

extension OutputCopyWith on Output {
  Output OutputCopyWithParsedAddress({
    ParsedAddress? parsedAddress,
    String? fiatAmount,
  }) {
    final clone = Output(
      _wallet,
      _settingsStore,
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