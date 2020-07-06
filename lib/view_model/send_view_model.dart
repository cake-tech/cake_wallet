import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/core/amount_validator.dart';
import 'package:cake_wallet/core/validator.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/bitcoin/bitcoin_wallet.dart';
import 'package:cake_wallet/monero/monero_wallet.dart';
import 'package:cake_wallet/src/domain/common/balance.dart';
import 'package:cake_wallet/src/domain/common/calculate_estimated_fee.dart';
import 'package:cake_wallet/src/domain/common/crypto_currency.dart';
import 'package:cake_wallet/src/domain/common/fiat_currency.dart';
import 'package:cake_wallet/src/domain/common/transaction_priority.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/monero/monero_wallet_service.dart';
import 'package:cake_wallet/bitcoin/bitcoin_wallet_creation_credentials.dart';
import 'package:cake_wallet/core/wallet_creation_service.dart';
import 'package:cake_wallet/core/wallet_credentials.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:cake_wallet/view_model/wallet_creation_vm.dart';

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
  SendViewModelBase(this._wallet, this._settingsStore)
      : state = InitialSendViewModelState();

  @observable
  SendViewModelState state;

  @observable
  String fiatAmount;

  @observable
  String cryptoAmount;

  @observable
  String address;

  FiatCurrency get fiat => _settingsStore.fiatCurrency;

  TransactionPriority get transactionPriority =>
      _settingsStore.transactionPriority;

  double get estimatedFee =>
      calculateEstimatedFee(priority: transactionPriority);

  CryptoCurrency get currency => _wallet.currency;

  Validator get amountValidator => AmountValidator(type: _wallet.type);

  Validator get addressValidator => AddressValidator(type: _wallet.currency);

  @computed
  String get balance {
    if (_wallet is MoneroWallet) {
      _wallet.balance.formattedUnlockedBalance;
    }

    if (_wallet is BitcoinWallet) {
      _wallet.balance.confirmedFormatted;
    }

    return '0.0';
  }

  WalletBase _wallet;

  SettingsStore _settingsStore;

  Future<void> createTransaction() async {}

  Future<void> commitTransaction() async {}
}
