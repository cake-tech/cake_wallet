import 'package:cake_wallet/bitcoin/bitcoin_amount_format.dart';
import 'package:cake_wallet/bitcoin/bitcoin_transaction_priority.dart';
import 'package:cake_wallet/bitcoin/electrum_wallet.dart';
import 'package:cake_wallet/entities/balance_display_mode.dart';
import 'package:cake_wallet/entities/calculate_fiat_amount_raw.dart';
import 'package:cake_wallet/entities/transaction_description.dart';
import 'package:cake_wallet/entities/transaction_priority.dart';
import 'package:cake_wallet/entities/unstoppable_domain_address.dart';
import 'package:cake_wallet/monero/monero_amount_format.dart';
import 'package:cake_wallet/view_model/settings/settings_view_model.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/entities/openalias_record.dart';
import 'package:cake_wallet/entities/template.dart';
import 'package:cake_wallet/store/templates/send_template_store.dart';
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
import 'package:cake_wallet/entities/monero_transaction_priority.dart';
import 'package:cake_wallet/entities/calculate_fiat_amount.dart';
import 'package:cake_wallet/entities/wallet_type.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import 'package:cake_wallet/generated/i18n.dart';

part 'send_view_model.g.dart';

const String cryptoNumberPattern = '0.0';

class SendViewModel = SendViewModelBase with _$SendViewModel;

abstract class SendViewModelBase with Store {
  SendViewModelBase(this._wallet, this._settingsStore, this._sendTemplateStore,
      this._fiatConversationStore, this.transactionDescriptionBox)
      : state = InitialExecutionState(),
        _cryptoNumberFormat = NumberFormat(cryptoNumberPattern),
        note = '',
        sendAll = false {
    final priority = _settingsStore.priority[_wallet.type];
    final priorities = priorityForWalletType(_wallet.type);

    if (!priorityForWalletType(_wallet.type).contains(priority)) {
      _settingsStore.priority[_wallet.type] = priorities.first;
    }

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
  String note;

  @observable
  bool sendAll;

  @computed
  double get estimatedFee {
    int amount;

    try {
      if (cryptoAmount?.isNotEmpty ?? false) {
        final _cryptoAmount = cryptoAmount.replaceAll(',', '.');
        int _amount = 0;
        switch (walletType) {
          case WalletType.monero:
            _amount = moneroParseAmount(amount: _cryptoAmount);
            break;
          case WalletType.bitcoin:
            _amount = stringDoubleToBitcoinAmount(_cryptoAmount);
            break;
          case WalletType.litecoin:
            _amount = stringDoubleToBitcoinAmount(_cryptoAmount);
            break;
          default:
            break;
        }

        if (_amount > 0) {
          amount = _amount;
        }
      }

      final fee = _wallet.calculateEstimatedFee(
          _settingsStore.priority[_wallet.type], amount);

      if (_wallet is ElectrumWallet) {
        return bitcoinAmountToDouble(amount: fee);
      }

      if (_wallet is MoneroWallet) {
        return moneroAmountToDouble(amount: fee);
      }
    } catch (e) {
      print(e.toString());
    }

    return 0;
  }

  @computed
  String get estimatedFeeFiatAmount {
    try {
      final fiat = calculateFiatAmountRaw(
          price: _fiatConversationStore.prices[_wallet.currency],
          cryptoAmount: estimatedFee);
      return fiat;
    } catch (_) {
      return '0.00';
    }
  }

  @computed
  String get pendingTransactionFiatAmount {
    try {
      if (pendingTransaction != null) {
        final fiat = calculateFiatAmount(
            price: _fiatConversationStore.prices[_wallet.currency],
            cryptoAmount: pendingTransaction.amountFormatted);
        return fiat;
      } else {
        return '0.00';
      }
    } catch (_) {
      return '0.00';
    }
  }

  @computed
  String get pendingTransactionFeeFiatAmount {
    try {
      if (pendingTransaction != null) {
        final fiat = calculateFiatAmount(
            price: _fiatConversationStore.prices[_wallet.currency],
            cryptoAmount: pendingTransaction.feeFormatted);
        return fiat;
      } else {
        return '0.00';
      }
    } catch (_) {
      return '0.00';
    }
  }

  FiatCurrency get fiat => _settingsStore.fiatCurrency;

  TransactionPriority get transactionPriority =>
      _settingsStore.priority[_wallet.type];

  CryptoCurrency get currency => _wallet.currency;

  Validator get amountValidator => AmountValidator(type: _wallet.type);

  Validator get allAmountValidator => AllAmountValidator();

  Validator get addressValidator => AddressValidator(type: _wallet.currency);

  Validator get templateValidator => TemplateValidator();

  @observable
  PendingTransaction pendingTransaction;

  @computed
  String get balance => _wallet.balance.formattedAvailableBalance ?? '0.0';

  @computed
  bool get isReadyForSend => _wallet.syncStatus is SyncedSyncStatus;

  @computed
  ObservableList<Template> get templates => _sendTemplateStore.templates;

  WalletType get walletType => _wallet.type;
  final WalletBase _wallet;
  final SettingsStore _settingsStore;
  final SendTemplateStore _sendTemplateStore;
  final FiatConversionStore _fiatConversationStore;
  final NumberFormat _cryptoNumberFormat;
  final Box<TransactionDescription> transactionDescriptionBox;

  @action
  void setSendAll() => sendAll = true;

  @action
  void reset() {
    sendAll = false;
    cryptoAmount = '';
    fiatAmount = '';
    address = '';
    note = '';
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

      if (pendingTransaction.id?.isNotEmpty ?? false) {
        _settingsStore.shouldSaveRecipientAddress
            ? await transactionDescriptionBox.add(TransactionDescription(
                id: pendingTransaction.id,
                recipientAddress: address,
                transactionNote: note))
            : await transactionDescriptionBox.add(TransactionDescription(
                id: pendingTransaction.id, transactionNote: note));
      }

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
      _settingsStore.priority[_wallet.type] = priority;

  Future<OpenaliasRecord> decodeOpenaliasRecord(String name) async {
    final record = await OpenaliasRecord.fetchAddressAndName(
        OpenaliasRecord.formatDomainName(name));

    return record.name != name ? record : null;
  }

  Future<String> getUnstoppableDomainAddress(String domain) async {
    return await fetchUnstoppableDomainAddress(domain, currency.title.toLowerCase());
  }

  @action
  void _updateFiatAmount() {
    try {
      final fiat = calculateFiatAmount(
          price: _fiatConversationStore.prices[_wallet.currency],
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
          _fiatConversationStore.prices[_wallet.currency];
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
        final amount = !sendAll ? _amount : null;
        final priority = _settingsStore.priority[_wallet.type];

        return BitcoinTransactionCredentials(
            address, amount, priority as BitcoinTransactionPriority);
      case WalletType.litecoin:
        final amount = !sendAll ? _amount : null;
        final priority = _settingsStore.priority[_wallet.type];

        return BitcoinTransactionCredentials(
            address, amount, priority as BitcoinTransactionPriority);
      case WalletType.monero:
        final amount = !sendAll ? _amount : null;
        final priority = _settingsStore.priority[_wallet.type];

        return MoneroTransactionCreationCredentials(
            address: address,
            paymentId: '',
            priority: priority as MoneroTransactionPriority,
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
      case WalletType.litecoin:
        maximumFractionDigits = 8;
        break;
      default:
        break;
    }

    _cryptoNumberFormat.maximumFractionDigits = maximumFractionDigits;
  }

  void updateTemplate() => _sendTemplateStore.update();

  void addTemplate(
          {String name,
          String address,
          String cryptoCurrency,
          String amount}) =>
      _sendTemplateStore.addTemplate(
          name: name,
          address: address,
          cryptoCurrency: cryptoCurrency,
          amount: amount);

  void removeTemplate({Template template}) =>
      _sendTemplateStore.remove(template: template);

  String displayFeeRate(dynamic priority) {
    final _priority = priority as TransactionPriority;
    final wallet = _wallet;

    if (wallet is ElectrumWallet) {
      final rate = wallet.feeRate(_priority);
      return '${priority.labelWithRate(rate)}';
    }

    return priority.toString();
  }
}
