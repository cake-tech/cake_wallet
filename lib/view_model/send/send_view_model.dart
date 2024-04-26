import 'package:cake_wallet/entities/contact.dart';
import 'package:cake_wallet/entities/priority_for_wallet_type.dart';
import 'package:cake_wallet/entities/transaction_description.dart';
import 'package:cake_wallet/ethereum/ethereum.dart';
import 'package:cake_wallet/exchange/provider/exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/thorchain_exchange.provider.dart';
import 'package:cake_wallet/nano/nano.dart';
import 'package:cake_wallet/core/wallet_change_listener_view_model.dart';
import 'package:cake_wallet/entities/contact_record.dart';
import 'package:cake_wallet/entities/wallet_contact.dart';
import 'package:cake_wallet/polygon/polygon.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/solana/solana.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/view_model/contact_list/contact_list_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/balance_view_model.dart';
import 'package:cw_core/exceptions.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cake_wallet/view_model/send/send_template_view_model.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/entities/template.dart';
import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/core/amount_validator.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cake_wallet/core/validator.dart';
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
import 'package:cake_wallet/haven/haven.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:collection/collection.dart';

part 'send_view_model.g.dart';

class SendViewModel = SendViewModelBase with _$SendViewModel;

abstract class SendViewModelBase extends WalletChangeListenerViewModel with Store {
  @override
  void onWalletChange(wallet) {
    currencies = wallet.balance.keys.toList();
    selectedCryptoCurrency = wallet.currency;
    hasMultipleTokens = isEVMCompatibleChain(wallet.type) || wallet.type == WalletType.solana;
  }

  SendViewModelBase(
    AppStore appStore,
    this.sendTemplateViewModel,
    this._fiatConversationStore,
    this.balanceViewModel,
    this.contactListViewModel,
    this.transactionDescriptionBox,
  )   : state = InitialExecutionState(),
        currencies = appStore.wallet!.balance.keys.toList(),
        selectedCryptoCurrency = appStore.wallet!.currency,
        hasMultipleTokens = isEVMCompatibleChain(appStore.wallet!.type) ||
            appStore.wallet!.type == WalletType.solana,
        outputs = ObservableList<Output>(),
        _settingsStore = appStore.settingsStore,
        fiatFromSettings = appStore.settingsStore.fiatCurrency,
        super(appStore: appStore) {
    if (wallet.type == WalletType.bitcoin &&
        _settingsStore.priority[wallet.type] == bitcoinTransactionPriorityCustom) {
      setTransactionPriority(bitcoinTransactionPriorityMedium);
    }
    final priority = _settingsStore.priority[wallet.type];
    final priorities = priorityForWalletType(wallet.type);
    if (!priorityForWalletType(wallet.type).contains(priority) && priorities.isNotEmpty) {
      _settingsStore.priority[wallet.type] = priorities.first;
    }

    outputs
        .add(Output(wallet, _settingsStore, _fiatConversationStore, () => selectedCryptoCurrency));
  }

  @observable
  ExecutionState state;

  ObservableList<Output> outputs;

  @action
  void addOutput() {
    outputs
        .add(Output(wallet, _settingsStore, _fiatConversationStore, () => selectedCryptoCurrency));
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
    if (pendingTransaction == null) {
      return '0.00';
    }

    try {
      final fiat = calculateFiatAmount(
          price: _fiatConversationStore.prices[selectedCryptoCurrency]!,
          cryptoAmount: pendingTransaction!.amountFormatted);
      return fiat;
    } catch (_) {
      return '0.00';
    }
  }

  @computed
  String get pendingTransactionFeeFiatAmount {
    try {
      if (pendingTransaction != null) {
        final currency =
            isEVMCompatibleChain(walletType) ? wallet.currency : selectedCryptoCurrency;
        final fiat = calculateFiatAmount(
            price: _fiatConversationStore.prices[currency]!,
            cryptoAmount: pendingTransaction!.feeFormatted);
        return fiat;
      } else {
        return '0.00';
      }
    } catch (_) {
      return '0.00';
    }
  }

  FiatCurrency get fiat => _settingsStore.fiatCurrency;

  TransactionPriority get transactionPriority {
    final priority = _settingsStore.priority[wallet.type];

    if (priority == null) {
      throw Exception('Unexpected type ${wallet.type}');
    }

    return priority;
  }

  int? getCustomPriorityIndex(List<TransactionPriority> priorities) {
    if (wallet.type == WalletType.bitcoin) {
      final customItem = priorities
          .firstWhereOrNull((element) => element == bitcoin!.getBitcoinTransactionPriorityCustom());

      return customItem != null ? priorities.indexOf(customItem) : null;
    }
    return null;
  }

  int? get maxCustomFeeRate {
    if (wallet.type == WalletType.bitcoin) {
      return bitcoin!.getMaxCustomFeeRate(wallet);
    }
    return null;
  }

  @computed
  int get customBitcoinFeeRate => _settingsStore.customBitcoinFeeRate;

  void set customBitcoinFeeRate(int value) => _settingsStore.customBitcoinFeeRate = value;

  CryptoCurrency get currency => wallet.currency;

  Validator<String> get amountValidator =>
      AmountValidator(currency: walletTypeToCryptoCurrency(wallet.type));

  Validator<String> get allAmountValidator => AllAmountValidator();

  Validator<String> get addressValidator => AddressValidator(type: selectedCryptoCurrency);

  Validator<String> get textValidator => TextValidator();

  final FiatCurrency fiatFromSettings;

  @observable
  PendingTransaction? pendingTransaction;

  @computed
  String get balance => wallet.balance[selectedCryptoCurrency]!.formattedAvailableBalance;

  @computed
  bool get isFiatDisabled => balanceViewModel.isFiatDisabled;

  @computed
  String get pendingTransactionFiatAmountFormatted =>
      isFiatDisabled ? '' : pendingTransactionFiatAmount + ' ' + fiat.title;

  @computed
  String get pendingTransactionFeeFiatAmountFormatted =>
      isFiatDisabled ? '' : pendingTransactionFeeFiatAmount + ' ' + fiat.title;

  @computed
  bool get isReadyForSend => wallet.syncStatus is SyncedSyncStatus;

  @computed
  List<Template> get templates => sendTemplateViewModel.templates
      .where((template) => _isEqualCurrency(template.cryptoCurrency))
      .toList();

  @computed
  bool get hasCoinControl =>
      wallet.type == WalletType.bitcoin ||
      wallet.type == WalletType.litecoin ||
      wallet.type == WalletType.monero ||
      wallet.type == WalletType.bitcoinCash;

  @computed
  bool get isElectrumWallet =>
      wallet.type == WalletType.bitcoin ||
      wallet.type == WalletType.litecoin ||
      wallet.type == WalletType.bitcoinCash;

  @computed
  bool get hasFees => wallet.type != WalletType.nano && wallet.type != WalletType.banano;

  @computed
  bool get hasFeesPriority =>
      wallet.type != WalletType.nano &&
      wallet.type != WalletType.banano &&
      wallet.type != WalletType.solana;
  @observable
  CryptoCurrency selectedCryptoCurrency;

  List<CryptoCurrency> currencies;

  bool get hasYat => outputs
      .any((out) => out.isParsedAddress && out.parsedAddress.parseFrom == ParseFrom.yatRecord);

  WalletType get walletType => wallet.type;

  String? get walletCurrencyName => wallet.currency.fullName?.toLowerCase() ?? wallet.currency.name;

  bool get hasCurrecyChanger => walletType == WalletType.haven;

  @computed
  FiatCurrency get fiatCurrency => _settingsStore.fiatCurrency;

  final SettingsStore _settingsStore;
  final SendTemplateViewModel sendTemplateViewModel;
  final BalanceViewModel balanceViewModel;
  final ContactListViewModel contactListViewModel;
  final FiatConversionStore _fiatConversationStore;
  final Box<TransactionDescription> transactionDescriptionBox;

  @observable
  bool hasMultipleTokens;

  @computed
  List<ContactRecord> get contactsToShow => contactListViewModel.contacts
      .where((element) => element.type == selectedCryptoCurrency)
      .toList();

  @computed
  List<WalletContact> get walletContactsToShow => contactListViewModel.walletContacts
      .where((element) => element.type == selectedCryptoCurrency)
      .toList();

  @action
  bool checkIfAddressIsAContact(String address) {
    final contactList = contactsToShow.where((element) => element.address == address).toList();

    return contactList.isNotEmpty;
  }

  @action
  bool checkIfWalletIsAnInternalWallet(String address) {
    final walletContactList =
        walletContactsToShow.where((element) => element.address == address).toList();

    return walletContactList.isNotEmpty;
  }

  @computed
  bool get shouldDisplayTOTP2FAForContact => _settingsStore.shouldRequireTOTP2FAForSendsToContact;

  @computed
  bool get shouldDisplayTOTP2FAForNonContact =>
      _settingsStore.shouldRequireTOTP2FAForSendsToNonContact;

  @computed
  bool get shouldDisplayTOTP2FAForSendsToInternalWallet =>
      _settingsStore.shouldRequireTOTP2FAForSendsToInternalWallets;

  //* Still open to further optimize these checks
  //* It works but can be made better
  @action
  bool checkThroughChecksToDisplayTOTP(String address) {
    final isContact = checkIfAddressIsAContact(address);
    final isInternalWallet = checkIfWalletIsAnInternalWallet(address);

    if (isContact) {
      return shouldDisplayTOTP2FAForContact;
    } else if (isInternalWallet) {
      return shouldDisplayTOTP2FAForSendsToInternalWallet;
    } else {
      return shouldDisplayTOTP2FAForNonContact;
    }
  }

  bool shouldDisplayTotp() {
    List<bool> conditionsList = [];

    for (var output in outputs) {
      final show = checkThroughChecksToDisplayTOTP(output.extractedAddress);
      conditionsList.add(show);
    }

    return conditionsList.contains(true);
  }

  @action
  Future<PendingTransaction?> createTransaction({ExchangeProvider? provider}) async {
    try {
      state = IsExecutingState();

      pendingTransaction = await wallet.createTransaction(_credentials());
      if (provider is ThorChainExchangeProvider) {
        final outputCount = pendingTransaction?.outputCount ?? 0;
        if (outputCount > 10) {
          throw Exception("THORChain does not support more than 10 outputs");
        }

        if (_hasTaprootInput(pendingTransaction)) {
          throw Exception("THORChain does not support Taproot addresses");
        }
      }
      state = ExecutedSuccessfullyState();
      return pendingTransaction;
    } catch (e) {
      state = FailureState(translateErrorMessage(e, wallet.type, wallet.currency));
    }
    return null;
  }

  @action
  Future<void> replaceByFee(String txId, String newFee) async {
    state = IsExecutingState();

    final isSufficient = await bitcoin!.isChangeSufficientForFee(wallet, txId, newFee);

    if (!isSufficient) {
      state = AwaitingConfirmationState(
          title: S.current.confirm_fee_deduction,
          message: S.current.confirm_fee_deduction_content,
          onConfirm: () async {
            pendingTransaction = await bitcoin!.replaceByFee(wallet, txId, newFee);
            state = ExecutedSuccessfullyState();
          },
          onCancel: () {
            state = FailureState('Insufficient change for fee');
          });
    } else {
      pendingTransaction = await bitcoin!.replaceByFee(wallet, txId, newFee);
      state = ExecutedSuccessfullyState();
    }
  }

  @action
  Future<void> commitTransaction() async {
    if (pendingTransaction == null) {
      throw Exception("Pending transaction doesn't exist. It should not be happened.");
    }

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
      await pendingTransaction!.commit();

      if (walletType == WalletType.nano) {
        nano!.updateTransactions(wallet);
      }

      if (pendingTransaction!.id.isNotEmpty) {
        _settingsStore.shouldSaveRecipientAddress
            ? await transactionDescriptionBox.add(TransactionDescription(
                id: pendingTransaction!.id, recipientAddress: address, transactionNote: note))
            : await transactionDescriptionBox
                .add(TransactionDescription(id: pendingTransaction!.id, transactionNote: note));
      }

      state = TransactionCommitted();
    } catch (e) {
      state = FailureState(translateErrorMessage(e, wallet.type, wallet.currency));
    }
  }

  @action
  void setTransactionPriority(TransactionPriority priority) =>
      _settingsStore.priority[wallet.type] = priority;

  Object _credentials() {
    final priority = _settingsStore.priority[wallet.type];

    if (priority == null && wallet.type != WalletType.nano && wallet.type != WalletType.banano && wallet.type != WalletType.solana) {
      throw Exception('Priority is null for wallet type: ${wallet.type}');
    }

    switch (wallet.type) {
      case WalletType.bitcoin:
      case WalletType.litecoin:
      case WalletType.bitcoinCash:
        return bitcoin!.createBitcoinTransactionCredentials(outputs,
            priority: priority!, feeRate: customBitcoinFeeRate);

      case WalletType.monero:
        return monero!
            .createMoneroTransactionCreationCredentials(outputs: outputs, priority: priority!);

      case WalletType.haven:
        return haven!.createHavenTransactionCreationCredentials(
            outputs: outputs, priority: priority!, assetType: selectedCryptoCurrency.title);

      case WalletType.ethereum:
        return ethereum!.createEthereumTransactionCredentials(outputs,
            priority: priority!, currency: selectedCryptoCurrency);
      case WalletType.nano:
        return nano!.createNanoTransactionCredentials(outputs);
      case WalletType.polygon:
        return polygon!.createPolygonTransactionCredentials(outputs,
            priority: priority!, currency: selectedCryptoCurrency);
      case WalletType.solana:
        return solana!
            .createSolanaTransactionCredentials(outputs, currency: selectedCryptoCurrency);
      default:
        throw Exception('Unexpected wallet type: ${wallet.type}');
    }
  }

  String displayFeeRate(dynamic priority, int? customValue) {
    final _priority = priority as TransactionPriority;

    if (walletType == WalletType.bitcoin) {
      final rate = bitcoin!.getFeeRate(wallet, _priority);
      return bitcoin!.bitcoinTransactionPriorityWithLabel(_priority, rate, customRate: customValue);
    }

    if (isElectrumWallet) {
      final rate = bitcoin!.getFeeRate(wallet, _priority);
      return bitcoin!.bitcoinTransactionPriorityWithLabel(_priority, rate);
    }

    return priority.toString();
  }

  bool _isEqualCurrency(String currency) =>
      wallet.balance.keys.any((e) => currency.toLowerCase() == e.title.toLowerCase());

  TransactionPriority get bitcoinTransactionPriorityCustom =>
      bitcoin!.getBitcoinTransactionPriorityCustom();

  TransactionPriority get bitcoinTransactionPriorityMedium =>
      bitcoin!.getBitcoinTransactionPriorityMedium();

  @action
  void onClose() => _settingsStore.fiatCurrency = fiatFromSettings;

  @action
  void setFiatCurrency(FiatCurrency fiat) => _settingsStore.fiatCurrency = fiat;

  @action
  void setSelectedCryptoCurrency(String cryptoCurrency) {
    try {
      selectedCryptoCurrency = wallet.balance.keys
          .firstWhere((e) => cryptoCurrency.toLowerCase() == e.title.toLowerCase());
    } catch (e) {
      selectedCryptoCurrency = wallet.currency;
    }
  }

  ContactRecord? newContactAddress() {
    final Set<String> contactAddresses =
        Set.from(contactListViewModel.contacts.map((contact) => contact.address))
          ..addAll(contactListViewModel.walletContacts.map((contact) => contact.address));

    for (var output in outputs) {
      String address;
      if (output.isParsedAddress) {
        address = output.parsedAddress.addresses.first;
      } else {
        address = output.address;
      }

      if (address.isNotEmpty &&
          !contactAddresses.contains(address) &&
          selectedCryptoCurrency.raw != -1) {
        return ContactRecord(
            contactListViewModel.contactSource,
            Contact(
              name: '',
              address: address,
              type: selectedCryptoCurrency,
            ));
      }
    }
    return null;
  }

  String translateErrorMessage(
    Object error,
    WalletType walletType,
    CryptoCurrency currency,
  ) {
    String errorMessage = error.toString();

    if (walletType == WalletType.ethereum ||
        walletType == WalletType.polygon ||
        walletType == WalletType.solana ||
        walletType == WalletType.haven) {
      if (errorMessage.contains('gas required exceeds allowance') ||
          errorMessage.contains('insufficient funds')) {
        return S.current.do_not_have_enough_gas_asset(currency.toString());
      }

      return errorMessage;
    }

    if (walletType == WalletType.bitcoin ||
        walletType == WalletType.litecoin ||
        walletType == WalletType.bitcoinCash) {
      if (error is TransactionWrongBalanceException) {
        return S.current.tx_wrong_balance_exception(currency.toString());
      }
      if (error is TransactionNoInputsException) {
        return S.current.tx_not_enough_inputs_exception;
      }
      if (error is TransactionNoFeeException) {
        return S.current.tx_zero_fee_exception;
      }
      if (error is TransactionNoDustException) {
        return S.current.tx_no_dust_exception;
      }
      if (error is TransactionCommitFailed) {
        return "${S.current.tx_commit_failed}${error.errorMessage != null ? "\n\n${error.errorMessage}" : ""}";
      }
      if (error is TransactionCommitFailedDustChange) {
        return S.current.tx_rejected_dust_change;
      }
      if (error is TransactionCommitFailedDustOutput) {
        return S.current.tx_rejected_dust_output;
      }
      if (error is TransactionCommitFailedDustOutputSendAll) {
        return S.current.tx_rejected_dust_output_send_all;
      }
      if (error is TransactionCommitFailedVoutNegative) {
        return S.current.tx_rejected_vout_negative;
      }
      if (error is TransactionNoDustOnChangeException) {
        return S.current.tx_commit_exception_no_dust_on_change(error.min, error.max);
      }
    }

    return errorMessage;
  }

  bool _hasTaprootInput(PendingTransaction? pendingTransaction) {
    if (walletType == WalletType.bitcoin && pendingTransaction != null) {
      return bitcoin!.hasTaprootInput(pendingTransaction);
    }

    return false;
  }
}
