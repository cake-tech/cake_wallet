import 'package:cake_wallet/entities/openalias_record.dart';
import 'package:intl/intl.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/core/template_validator.dart';
import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/core/amount_validator.dart';
import 'package:cake_wallet/core/pending_transaction.dart';
import 'package:cake_wallet/core/validator.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/bitcoin/bitcoin_wallet.dart';
import 'package:cake_wallet/bitcoin/bitcoin_transaction_credentials.dart';
import 'package:cake_wallet/monero/monero_wallet.dart';
import 'package:cake_wallet/monero/monero_transaction_creation_credentials.dart';
import 'package:cake_wallet/entities/sync_status.dart';
import 'package:cake_wallet/entities/crypto_currency.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/entities/transaction_priority.dart';
import 'package:cake_wallet/entities/calculate_fiat_amount.dart';
import 'package:cake_wallet/entities/wallet_type.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import 'package:cake_wallet/generated/i18n.dart';

part 'send_view_model.g.dart';

class SendViewModel = SendViewModelBase with _$SendViewModel;

abstract class SendViewModelBase with Store {
  SendViewModelBase(
      this._wallet, this._settingsStore, this._fiatConversationStore)
      : state = InitialExecutionState(),
        _cryptoNumberFormat = NumberFormat(),
        sendAll = false {
    _setCryptoNumMaximumFractionDigits();
  }

  @observable
  ExecutionState state;

  @observable
  String fiatAmount;

  @observable
  String cryptoAmount;

  @observable
  String address;

  @observable
  bool sendAll;

  @computed
  double get estimatedFee =>
      _wallet.calculateEstimatedFee(_settingsStore.transactionPriority);

  FiatCurrency get fiat => _settingsStore.fiatCurrency;

  TransactionPriority get transactionPriority =>
      _settingsStore.transactionPriority;

  CryptoCurrency get currency => _wallet.currency;

  Validator get amountValidator => AmountValidator(type: _wallet.type);

  Validator get allAmountValidator => AllAmountValidator();

  Validator get addressValidator => AddressValidator(type: _wallet.currency);

  Validator get templateValidator => TemplateValidator();

  PendingTransaction pendingTransaction;

  @computed
  String get balance {
    String balance = '0.0';

    if (_wallet is MoneroWallet) {
      balance = _wallet.balance.formattedUnlockedBalance as String ?? '';
    }

    if (_wallet is BitcoinWallet) {
      balance = _wallet.balance.confirmedFormatted as String ?? '';
    }

    return balance;
  }

  @computed
  bool get isReadyForSend => _wallet.syncStatus is SyncedSyncStatus;

  final WalletBase _wallet;
  final SettingsStore _settingsStore;
  final FiatConversionStore _fiatConversationStore;
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
      state = IsExecutingState();
      pendingTransaction = await _wallet.createTransaction(_credentials());
      state = ExecutedSuccessfullyState();
    } catch (e) {
      state = FailureState(e.toString());
    }
  }

  @action
  Future<void> commitTransaction() async {
    try {
      state = TransactionCommitting();
      await pendingTransaction.commit();
      state = TransactionCommitted();
    } catch (e) {
      state = FailureState(e.toString());
    }
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
  void setTransactionPriority(TransactionPriority priority) =>
      _settingsStore.transactionPriority = priority;

  Future<OpenaliasRecord> decodeOpenaliasRecord(String name) async {
    final record = await OpenaliasRecord
        .fetchAddressAndName(OpenaliasRecord.formatDomainName(name));

    return record.name != name ? record : null;
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
    final _amount = cryptoAmount.replaceAll(',', '.');

    switch (_wallet.type) {
      case WalletType.bitcoin:
        final amount = !sendAll ? double.parse(_amount) : null;

        return BitcoinTransactionCredentials(
            address, amount, _settingsStore.transactionPriority);
      case WalletType.monero:
        final amount = !sendAll ? _amount : null;

        return MoneroTransactionCreationCredentials(
            address: address,
            paymentId: '',
            priority: _settingsStore.transactionPriority,
            amount: amount);
      default:
        return null;
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
      default:
        break;
    }

    _cryptoNumberFormat.maximumFractionDigits = maximumFractionDigits;
  }
}
