import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/core/amount_validator.dart';
import 'package:cake_wallet/core/template_validator.dart';
import 'package:cake_wallet/core/validator.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/bitcoin/bitcoin_wallet.dart';
import 'package:cake_wallet/monero/monero_wallet.dart';
import 'package:cake_wallet/src/domain/common/balance.dart';
import 'package:cake_wallet/src/domain/common/balance_display_mode.dart';
import 'package:cake_wallet/src/domain/common/calculate_estimated_fee.dart';
import 'package:cake_wallet/src/domain/common/crypto_currency.dart';
import 'package:cake_wallet/src/domain/common/fiat_currency.dart';
import 'package:cake_wallet/src/domain/common/sync_status.dart';
import 'package:cake_wallet/src/domain/common/transaction_priority.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/store/templates/send_template_store.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/monero/monero_wallet_service.dart';
import 'package:cake_wallet/bitcoin/bitcoin_wallet_creation_credentials.dart';
import 'package:cake_wallet/core/wallet_creation_service.dart';
import 'package:cake_wallet/core/wallet_credentials.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:cake_wallet/view_model/wallet_creation_vm.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/domain/common/openalias_record.dart';
import 'package:cake_wallet/store/dashboard/fiat_convertation_store.dart';
import 'package:cake_wallet/src/domain/common/template.dart';

part 'send_view_model.g.dart';

abstract class SendViewModelState {}

class InitialSendViewModelState extends SendViewModelState {}

class TransactionIsCreating extends SendViewModelState {}

class TransactionCreatedSuccessfully extends SendViewModelState {}

class TransactionCommitting extends SendViewModelState {}

class TransactionCommitted extends SendViewModelState {}

class SendingFailed extends SendViewModelState {
  SendingFailed({@required this.error});

  String error;
}

class SendViewModel = SendViewModelBase with _$SendViewModel;

abstract class SendViewModelBase with Store {
  SendViewModelBase(
      this._wallet,
      this._settingsStore,
      this._fiatConvertationStore,
      this.sendTemplateStore) {

    state = InitialSendViewModelState();

    _cryptoNumberFormat = NumberFormat()..maximumFractionDigits = 12;
    _fiatNumberFormat = NumberFormat()..maximumFractionDigits = 2;
  }

  NumberFormat _cryptoNumberFormat;
  NumberFormat _fiatNumberFormat;

  @observable
  SendViewModelState state;

  @observable
  String fiatAmount;

  @observable
  String cryptoAmount;

  @observable
  String address;

  String get cryptoCurrencyTitle {
    var _currencyTitle = '';

    if (_wallet is MoneroWallet) {
      _currencyTitle = 'Monero';
    }

    if (_wallet is BitcoinWallet) {
      _currencyTitle = 'Bitcoin';
    }

    return _currencyTitle;
  }

  String get pageTitle => S.current.send_title + ' ' + cryptoCurrencyTitle;

  FiatCurrency get fiat => _settingsStore.fiatCurrency;

  TransactionPriority get transactionPriority =>
      _settingsStore.transactionPriority;

  double get estimatedFee =>
      calculateEstimatedFee(priority: transactionPriority);

  String get name => _wallet.name;

  CryptoCurrency get currency => _wallet.currency;

  Validator get amountValidator => AmountValidator(type: _wallet.type);

  Validator get addressValidator => AddressValidator(type: _wallet.currency);

  Validator get templateValidator => TemplateValidator();

  @computed
  double get price => _fiatConvertationStore.price;

  @computed
  ObservableList<Template> get templates => ObservableList.of(
      sendTemplateStore.templates.where((item)
      => item.cryptoCurrency == _wallet.currency.title).toList());

  @computed
  String get balance {
    var _balance = '0.0';

    if (_wallet is MoneroWallet) {
      _balance = _wallet.balance.formattedUnlockedBalance.toString();
    }

    if (_wallet is BitcoinWallet) {
      _balance = _wallet.balance.confirmedFormatted.toString();
    }

    return _settingsStore.balanceDisplayMode == BalanceDisplayMode.hiddenBalance
        ? '---'
        : _balance;
  }

  @computed
  SyncStatus get status => _wallet.syncStatus;

  @action
  void changeCryptoAmount(String amount) {
    cryptoAmount = amount;

    if (cryptoAmount != null && cryptoAmount.isNotEmpty) {
      _calculateFiatAmount();
    } else {
      fiatAmount = '';
    }
  }

  @action
  void changeFiatAmount(String amount) {
    fiatAmount = amount;

    if (fiatAmount != null && fiatAmount.isNotEmpty) {
      _calculateCryptoAmount();
    } else {
      cryptoAmount = '';
    }
  }

  @action
  Future _calculateFiatAmount() async {
    try {
      final amount = double.parse(cryptoAmount) * price;
      fiatAmount = _fiatNumberFormat.format(amount);
    } catch (e) {
      fiatAmount = '0.00';
    }
  }

  @action
  Future _calculateCryptoAmount() async {
    try {
      final amount = double.parse(fiatAmount) / price;
      cryptoAmount = _cryptoNumberFormat.format(amount);
    } catch (e) {
      cryptoAmount = '0.00';
    }
  }

  @action
  void changeAddress(String address) {
    this.address = address;
  }

  @action
  void setSendAll() {
    cryptoAmount = 'ALL';
    fiatAmount = '';
  }

  final WalletBase _wallet;

  final SettingsStore _settingsStore;

  final FiatConvertationStore _fiatConvertationStore;

  final SendTemplateStore sendTemplateStore;

  String recordName;

  String recordAddress;

  Future<bool> isOpenaliasRecord(String name) async {
    final _openaliasRecord = await OpenaliasRecord
        .fetchAddressAndName(OpenaliasRecord.formatDomainName(name));

    recordAddress = _openaliasRecord.address;
    recordName = _openaliasRecord.name;

    return recordAddress != name;
  }

  Future<void> createTransaction() async {}

  Future<void> commitTransaction() async {}
}