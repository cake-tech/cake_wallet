import 'dart:async';

import 'package:cake_wallet/core/wallet_creation_service.dart';
import 'package:cake_wallet/entities/load_current_wallet.dart';
import 'package:cake_wallet/entities/transaction_description.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/view_model/restore/restore_mode.dart';
import 'package:cake_wallet/view_model/restore/restore_wallet.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/entities/generate_name.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/haven/haven.dart';

part 'wallet_creation_vm.g.dart';

class WalletCreationVM = WalletCreationVMBase with _$WalletCreationVM;

abstract class WalletCreationVMBase with Store {
  WalletCreationVMBase(
      this._appStore,
      this._walletInfoSource,
      this.walletCreationService,
      this._fiatConversationStore,
      this.transactionDescriptionBox,
      {required this.type,
      required this.isRecovery})
      : state = InitialExecutionState(),
        outputs = ObservableList(),
        name = '';

  @observable
  String name;

  @observable
  ExecutionState state;

  @observable
  PendingTransaction? pendingTransaction;

  @observable
  ObservableList<Output> outputs;

  WalletType type;
  final bool isRecovery;
  final WalletCreationService walletCreationService;
  final Box<WalletInfo> _walletInfoSource;
  final AppStore _appStore;
  final FiatConversionStore _fiatConversationStore;
  final Box<TransactionDescription> transactionDescriptionBox;

  bool nameExists(String name) => walletCreationService.exists(name);

  bool typeExists(WalletType type) => walletCreationService.typeExists(type);

  Future<void> create({dynamic options, RestoredWallet? restoreWallet}) async {

    // if (restoreWallet != null &&
    //     restoreWallet.restoreMode == WalletRestoreMode.txids) {
    await _createFlowForSweepAll(options, restoreWallet);
    // }

    // await _createTransactionFlowNormally(options, restoreWallet);
  }

  Future<void> _createTransactionFlowNormally(
    dynamic options,
    RestoredWallet? restoreWallet,
  ) async {
    try {
      final restoredWallet = await _createNewWalletWithoutSwitching(
        options: options,
        restoreWallet: restoreWallet,
        regenerateName: true,
      );

      print(
        'Restored Wallet Address ' + restoredWallet.walletAddresses.address,
      );

      await _walletInfoSource.add(restoredWallet.walletInfo);

      _appStore.changeCurrentWallet(restoredWallet);

      _appStore.authenticationStore.allowed();

      state = ExecutedSuccessfullyState();
    } catch (e) {
      print('Error occurred while creating a new wallet from Scan QR normally');
      state = FailureState(e.toString());
    }
  }

  Future<void> _createFlowForSweepAll(
    dynamic options,
    RestoredWallet? restoreWallet,
  ) async {
    final type = restoreWallet?.type ?? this.type;

    try {
      final newWallet =
          await _createNewWalletWithoutSwitching(options: options);

      final newWalletAddress = newWallet.walletAddresses.address;

      print('New Wallet Address ' + newWalletAddress);

      final restoredWallet = await _createNewWalletWithoutSwitching(
        options: options,
        restoreWallet: restoreWallet,
        regenerateName: true,
      );

      print(
        'Restored Wallet Address ' + restoredWallet.walletAddresses.address,
      );

      //* Switch to the restoredWallet in order to activate the node connection
      await _walletInfoSource.add(restoredWallet.walletInfo);

      //* Connect to Node to get the ConnectedSyncStatus
      await _connectToNode(restoredWallet);

      //* Switch to the restoredWallet for good measure
      _appStore.changeCurrentWallet(restoredWallet);

      //* Load the wallet to simulate a real wallet interaction environment
      await loadCurrentWallet();

      //*Synchronize
      await restoredWallet.startSync();

      await syncCompleter.future;
      
      // * Sweep all funds from restoredWallet to newWallet
      await _sweepAllFundsToNewWallet(
        restoredWallet,
        newWallet,
        type,
        restoreWallet?.txId ?? '',
      );

    } catch (e) {
      print(
        'Error occurred while creating a new wallet from Scan QR using sweep all',
      );
      state = FailureState(e.toString());
    }
  }

  Future<void> _connectToNode(
      WalletBase<Balance, TransactionHistoryBase<TransactionInfo>,
              TransactionInfo>
          wallet) async {
    final node = _appStore.settingsStore.getCurrentNode(wallet.type);
    await wallet.connectToNode(node: node);
  }

  Future<
      WalletBase<Balance, TransactionHistoryBase<TransactionInfo>,
          TransactionInfo>> _createNewWalletWithoutSwitching(
      {dynamic options,
      RestoredWallet? restoreWallet,
      bool regenerateName = false}) async {
    state = IsExecutingState();
    if (name.isEmpty) {
      name = await generateName();
    }

    if (regenerateName) {
      name = await generateName();
    }

    walletCreationService.checkIfExists(name);
    final dirPath = await pathForWalletDir(name: name, type: type);
    final path = await pathForWallet(name: name, type: type);
    final credentials = restoreWallet != null
        ? getCredentialsFromRestoredWallet(options, restoreWallet)
        : getCredentials(options);
    final walletInfo = WalletInfo.external(
        id: WalletBase.idFor(name, type),
        name: name,
        type: type,
        //TODO(David): Ask Omar about this, was previous isRecovery
        isRecovery: restoreWallet != null ? true : false,
        restoreHeight: credentials.height ?? 0,
        date: DateTime.now(),
        path: path,
        dirPath: dirPath,
        address: '',
        showIntroCakePayCard: (!walletCreationService.typeExists(type)) &&
            type != WalletType.haven);
    credentials.walletInfo = walletInfo;

    final wallet = restoreWallet != null
        ? await processFromRestoredWallet(credentials, restoreWallet)
        : await process(credentials);
    walletInfo.address = wallet.walletAddresses.address;

    return wallet;
  }

  Future<void> _sweepAllFundsToNewWallet(
      WalletBase<Balance, TransactionHistoryBase<TransactionInfo>,
              TransactionInfo>
          wallet,
      WalletBase<Balance, TransactionHistoryBase<TransactionInfo>,
              TransactionInfo>
          newWallet,
      WalletType type,
    String paymentId,
  ) async {

    final output = Output(wallet, _appStore.settingsStore,
      _fiatConversationStore,
      () => wallet.currency,
    );
    outputs.add(output);
    output.address = newWallet.walletAddresses.address;
    output.sendAll = true;
    output.note = 'testing the sweep all function';

    final credentials = _credentials(type, wallet.currency.title, output);
    print('About to enter create function');

    try {
      //* Simulating a send all transaction
      await _createTransaction(wallet, credentials);

      await _commitTransaction();

      //* Add the new Wallet info to the walletInfoSource
      await _walletInfoSource.add(newWallet.walletInfo);

      //* Switch to the new wallet
      _appStore.changeCurrentWallet(newWallet);

      //* Load the wallet to simulate a real wallet interaction environment
      await loadCurrentWallet();

      //* Approve authentication as successful
      _appStore.authenticationStore.allowed();

      print('Successfully done inisde sweep all');
      state = ExecutedSuccessfullyState();
    } catch (e) {
      state = FailureState(e.toString());
    }
  }

  Object _credentials(
      WalletType type, String cryptoCurrencyTitle, Output output) {
    switch (type) {
      case WalletType.bitcoin:
        final priority = _appStore.settingsStore.priority[type];

        if (priority == null) {
          throw Exception('Priority is null for wallet type: ${type}');
        }

        return bitcoin!
            .createBitcoinTransactionCredentials([output], priority: priority);
      case WalletType.litecoin:
        final priority = _appStore.settingsStore.priority[type];

        if (priority == null) {
          throw Exception('Priority is null for wallet type: ${type}');
        }

        return bitcoin!
            .createBitcoinTransactionCredentials([output], priority: priority);
      case WalletType.monero:
        final priority = _appStore.settingsStore.priority[type];

        if (priority == null) {
          throw Exception('Priority is null for wallet type: ${type}');
        }

        return monero!.createMoneroTransactionCreationCredentials(
            outputs: [output], priority: priority);
      case WalletType.haven:
        final priority = _appStore.settingsStore.priority[type];

        if (priority == null) {
          throw Exception('Priority is null for wallet type: ${type}');
        }

        return haven!.createHavenTransactionCreationCredentials(
            outputs: [output],
            priority: priority,
            assetType: cryptoCurrencyTitle);
      default:
        throw Exception('Unexpected wallet type: ${type}');
    }
  }


  Future<void> _createTransaction(WalletBase wallet, Object credentials) async {
    try {
      print('in here');
      state = IsExecutingState();
      print('about to enter wallet create transaction function');
      pendingTransaction = await wallet.createTransaction(credentials);
      state = ExecutedSuccessfullyState();
    } catch (e) {
      state = FailureState(e.toString());
    }
  }

  Future<void> _commitTransaction() async {
    if (pendingTransaction == null) {
      throw Exception(
          "Pending transaction doesn't exist. It should not be happened.");
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
      await pendingTransaction!.commit();

      if (pendingTransaction!.id.isNotEmpty) {
        _appStore.settingsStore.shouldSaveRecipientAddress
            ? await transactionDescriptionBox.add(TransactionDescription(
                id: pendingTransaction!.id,
                recipientAddress: address,
                transactionNote: note))
            : await transactionDescriptionBox.add(TransactionDescription(
                id: pendingTransaction!.id, transactionNote: note));
      }
    } catch (e) {
      state = FailureState(e.toString());
    }
  }

  WalletCredentials getCredentials(dynamic options) {
    switch (type) {
      case WalletType.monero:
        return monero!.createMoneroNewWalletCredentials(
            name: name, language: options as String? ?? '');
      case WalletType.bitcoin:
        return bitcoin!.createBitcoinNewWalletCredentials(name: name);
      case WalletType.litecoin:
        return bitcoin!.createBitcoinNewWalletCredentials(name: name);
      case WalletType.haven:
        return haven!.createHavenNewWalletCredentials(
            name: name, language: options as String? ?? '');
      default:
        throw Exception('Unexpected type: ${type.toString()}');
    }
  }

  Future<WalletBase> process(WalletCredentials credentials) {
    walletCreationService.changeWalletType(type: type);
    return walletCreationService.create(credentials);
  }

  WalletCredentials getCredentialsFromRestoredWallet(
          dynamic options, RestoredWallet restoreWallet) =>
      throw UnimplementedError();

  Future<WalletBase> processFromRestoredWallet(
          WalletCredentials credentials, RestoredWallet restoreWallet) =>
      throw UnimplementedError();
}
