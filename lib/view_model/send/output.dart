import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/calculate_fiat_amount_raw.dart';
import 'package:cake_wallet/entities/parse_address_from_domain.dart';
import 'package:cake_wallet/entities/parsed_address.dart';
import 'package:cake_wallet/ethereum/ethereum.dart';
import 'package:cake_wallet/haven/haven.dart';
import 'package:cake_wallet/polygon/polygon.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/src/screens/send/widgets/extract_address_from_parsed.dart';
import 'package:cw_core/crypto_currency.dart';
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
        key = UniqueKey(),
        sendAll = false,
        cryptoAmount = '',
        fiatAmount = '',
        address = '',
        note = '',
        extractedAddress = '',
        parsedAddress = ParsedAddress(addresses: []) {
    _setCryptoNumMaximumFractionDigits();
  }

  Key key;

  @observable
  String fiatAmount;

  @observable
  String cryptoAmount;

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

  @computed
  bool get isParsedAddress =>
      parsedAddress.parseFrom != ParseFrom.notParsed && parsedAddress.name.isNotEmpty;

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
            _amount = bitcoin!.formatterStringDoubleToBitcoinAmount(_cryptoAmount);
            break;
          case WalletType.haven:
            _amount = haven!.formatterMoneroParseAmount(amount: _cryptoAmount);
            break;
          case WalletType.ethereum:
            _amount = ethereum!.formatterEthereumParseAmount(_cryptoAmount);
            break;
          case WalletType.polygon:
            _amount = polygon!.formatterPolygonParseAmount(_cryptoAmount);
            break;
          default:
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
      final fee = _wallet.calculateEstimatedFee(
          _settingsStore.priority[_wallet.type]!, formattedCryptoAmount);

      if (_wallet.type == WalletType.bitcoin ||
          _wallet.type == WalletType.litecoin ||
          _wallet.type == WalletType.bitcoinCash) {
        return bitcoin!.formatterBitcoinAmountToDouble(amount: fee);
      }

      if (_wallet.type == WalletType.monero) {
        return monero!.formatterMoneroAmountToDouble(amount: fee);
      }

      if (_wallet.type == WalletType.haven) {
        return haven!.formatterMoneroAmountToDouble(amount: fee);
      }

      if (_wallet.type == WalletType.ethereum) {
        return ethereum!.formatterEthereumAmountToDouble(amount: BigInt.from(fee));
      }

      if (_wallet.type == WalletType.polygon) {
        return polygon!.formatterPolygonAmountToDouble(amount: BigInt.from(fee));
      }
    } catch (e) {
      print(e.toString());
    }

    return 0;
  }

  @computed
  String get estimatedFeeFiatAmount {
    try {
      final currency =
          isEVMCompatibleChain(_wallet.type) ? _wallet.currency : cryptoCurrencyHandler();
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
  void setSendAll() => sendAll = true;

  @action
  void reset() {
    sendAll = false;
    cryptoAmount = '';
    fiatAmount = '';
    address = '';
    note = '';
    resetParsedAddress();
  }

  void resetParsedAddress() {
    extractedAddress = '';
    parsedAddress = ParsedAddress(addresses: []);
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
          cryptoAmount: cryptoAmount.replaceAll(',', '.'));
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

  void _setCryptoNumMaximumFractionDigits() {
    var maximumFractionDigits = 0;

    switch (_wallet.type) {
      case WalletType.monero:
        maximumFractionDigits = 12;
        break;
      case WalletType.bitcoin:
        maximumFractionDigits = 8;
        break;
      case WalletType.litecoin:
        maximumFractionDigits = 8;
        break;
      case WalletType.bitcoinCash:
        maximumFractionDigits = 8;
        break;
      case WalletType.haven:
        maximumFractionDigits = 12;
        break;
      case WalletType.ethereum:
      case WalletType.polygon:
        maximumFractionDigits = 12;
        break;
      case WalletType.solana:
        maximumFractionDigits = 12;
        break;
      default:
        break;
    }

    _cryptoNumberFormat.maximumFractionDigits = maximumFractionDigits;
  }

  Future<void> fetchParsedAddress(BuildContext context) async {
    final domain = address;
    final ticker = cryptoCurrencyHandler().title.toLowerCase();
    parsedAddress = await getIt.get<AddressResolver>().resolve(context, domain, ticker);
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
