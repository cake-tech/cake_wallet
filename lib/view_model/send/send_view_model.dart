import 'package:cake_wallet/entities/balance_display_mode.dart';
import 'package:cake_wallet/entities/transaction_description.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cake_wallet/view_model/send/send_template_view_model.dart';
import 'package:cake_wallet/view_model/settings/settings_view_model.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/entities/template.dart';
import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/core/amount_validator.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cake_wallet/core/validator.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/entities/calculate_fiat_amount.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import 'package:cake_wallet/entities/parsed_address.dart';
import 'package:cake_wallet/bitcoin/bitcoin.dart';

part 'send_view_model.g.dart';

class SendViewModel = SendViewModelBase with _$SendViewModel;

abstract class SendViewModelBase with Store {
  SendViewModelBase(
      this._wallet,
      this._settingsStore,
      this.sendTemplateViewModel,
      this._fiatConversationStore,
      this.transactionDescriptionBox)
      : state = InitialExecutionState() {
    final priority = _settingsStore.priority[_wallet.type];
    final priorities = priorityForWalletType(_wallet.type);

    if (!priorityForWalletType(_wallet.type).contains(priority)) {
      _settingsStore.priority[_wallet.type] = priorities.first;
    }

    outputs = ObservableList<Output>()
      ..add(Output(_wallet, _settingsStore, _fiatConversationStore));
  }

  @observable
  ExecutionState state;

  ObservableList<Output> outputs;

  @action
  void addOutput() {
    outputs.add(Output(_wallet, _settingsStore, _fiatConversationStore));
  }

  @action
  void removeOutput(Output output) {
    if (isBatchSending) {
      outputs.remove(output);
    }
  }

  @action
  void clearOutputs() {
    outputs.clear();
    addOutput();
  }

  @computed
  bool get isBatchSending => outputs.length > 1;

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

  Validator get textValidator => TextValidator();

  @observable
  PendingTransaction pendingTransaction;

  @computed
  String get balance {
    if(_settingsStore.balanceDisplayMode == BalanceDisplayMode.hiddenBalance){
      return '---';
    }
    return _wallet.balance.formattedAvailableBalance ?? '0.0' ;
  } 

  @computed
  bool get isReadyForSend => _wallet.syncStatus is SyncedSyncStatus;

  @computed
  List<Template> get templates => sendTemplateViewModel.templates
      .where((template) => _isEqualCurrency(template.cryptoCurrency))
      .toList();

  @computed
  bool get isElectrumWallet =>
      _wallet.type == WalletType.bitcoin || _wallet.type == WalletType.litecoin;

  bool get hasYat => outputs.any((out) =>
      out.isParsedAddress &&
      out.parsedAddress.parseFrom == ParseFrom.yatRecord);

  WalletType get walletType => _wallet.type;
  final WalletBase _wallet;
  final SettingsStore _settingsStore;
  final SendTemplateViewModel sendTemplateViewModel;
  final FiatConversionStore _fiatConversationStore;
  final Box<TransactionDescription> transactionDescriptionBox;

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
    String address = outputs.fold('', (acc, value) {
      return value.isParsedAddress
          ? acc + value.address + '\n' + value.extractedAddress + '\n\n'
          : acc + value.address + '\n\n';
    });

    address = address.trim();

    String note = outputs.fold('', (acc, value) {
      return acc + value.note + '\n';
    });

    note = note.trim();

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
  void setTransactionPriority(TransactionPriority priority) =>
      _settingsStore.priority[_wallet.type] = priority;

  Object _credentials() {
    switch (_wallet.type) {
      case WalletType.bitcoin:
        final priority = _settingsStore.priority[_wallet.type];

        return bitcoin.createBitcoinTransactionCredentials(outputs, priority);
      case WalletType.litecoin:
        final priority = _settingsStore.priority[_wallet.type];

        return bitcoin.createBitcoinTransactionCredentials(outputs, priority);
      case WalletType.monero:
        final priority = _settingsStore.priority[_wallet.type];

        return monero.createMoneroTransactionCreationCredentials(
            outputs: outputs, priority: priority);
      default:
        return null;
    }
  }

  String displayFeeRate(dynamic priority) {
    final _priority = priority as TransactionPriority;
    final wallet = _wallet;

    if (isElectrumWallet) {
      final rate = bitcoin.getFeeRate(wallet, _priority);
      return '${priority.labelWithRate(rate)}';
    }

    return priority.toString();
  }

  bool _isEqualCurrency(String currency) => 
      currency.toLowerCase() == _wallet.currency.title.toLowerCase();
}
