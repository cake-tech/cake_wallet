import 'package:intl/intl.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/core/template_validator.dart';
import 'package:cake_wallet/src/domain/common/calculate_fiat_amount.dart';
import 'package:cake_wallet/store/dashboard/fiat_convertation_store.dart';
import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/core/amount_validator.dart';
import 'package:cake_wallet/core/pending_transaction.dart';
import 'package:cake_wallet/core/validator.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/bitcoin/bitcoin_wallet.dart';
import 'package:cake_wallet/monero/monero_wallet.dart';
import 'package:cake_wallet/src/domain/common/sync_status.dart';
import 'package:cake_wallet/src/domain/common/crypto_currency.dart';
import 'package:cake_wallet/src/domain/common/fiat_currency.dart';
import 'package:cake_wallet/src/domain/common/transaction_priority.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:cake_wallet/bitcoin/bitcoin_transaction_credentials.dart';

part 'send_view_model.g.dart';

class SendViewModel = SendViewModelBase with _$SendViewModel;

abstract class SendViewModelBase with Store {
  SendViewModelBase(
      this._wallet, this._settingsStore, this._fiatConversationStore)
      : state = InitialSendViewModelState(),
        _cryptoNumberFormat = NumberFormat()..maximumFractionDigits = 12,
        // FIXME: need to be based on wallet type.
        sendAll = false;

  @observable
  SendViewModelState state;

  @observable
  String fiatAmount;

  @observable
  String cryptoAmount;

  @observable
  String address;

  @observable
  bool sendAll;

  FiatCurrency get fiat => _settingsStore.fiatCurrency;

  TransactionPriority get transactionPriority =>
      _settingsStore.transactionPriority;

  double get estimatedFee =>
      _wallet.calculateEstimatedFee(_settingsStore.transactionPriority);

  CryptoCurrency get currency => _wallet.currency;

  Validator get amountValidator => AmountValidator(type: _wallet.type);

  Validator get addressValidator => AddressValidator(type: _wallet.currency);

  Validator get templateValidator => TemplateValidator();

  PendingTransaction pendingTransaction;

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

  @computed
  bool get isReadyForSend => _wallet.syncStatus is SyncedSyncStatus;

  final WalletBase _wallet;
  final SettingsStore _settingsStore;
  final FiatConvertationStore _fiatConversationStore;
  final NumberFormat _cryptoNumberFormat;

  @action
  void setSendAll() => sendAll = true;

  @action
  void reset() {
    cryptoAmount = '';
    fiatAmount = '';
    address = '';
  }

  @action
  Future<void> createTransaction() async {
    try {
      state = TransactionIsCreating();
      pendingTransaction = await _wallet.createTransaction(_credentials());
      state = TransactionCreatedSuccessfully();
    } catch (e) {
      state = SendingFailed(error: e.toString());
    }
  }

  @action
  Future<void> commitTransaction() async {
    try {
      state = TransactionCommitting();
      await pendingTransaction.commit();
      state = TransactionCommitted();
    } catch (e) {
      state = SendingFailed(error: e.toString());
    }
  }

  @action
  void setCryptoAmount(String amount) {
    // FIXME: hardcoded value.
    if (amount.toUpperCase() != 'ALL') {
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
          price: _fiatConversationStore.price,
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
          _fiatConversationStore.price;
      final cryptoAmountTmp = _cryptoNumberFormat.format(crypto);

      if (cryptoAmount != cryptoAmountTmp) {
        cryptoAmount = cryptoAmountTmp;
      }
    } catch (e) {
      cryptoAmount = '';
    }
  }

  Object _credentials() {
    final amount =
        !sendAll ? double.parse(cryptoAmount.replaceAll(',', '.')) : null;

    switch (_wallet.type) {
      case WalletType.bitcoin:
        return BitcoinTransactionCredentials(
            address, amount, _settingsStore.transactionPriority);
      case WalletType.monero:
        // FIXME: Wrong credentials
        return BitcoinTransactionCredentials(
            address, amount, _settingsStore.transactionPriority);
      default:
        return null;
    }
  }
}
