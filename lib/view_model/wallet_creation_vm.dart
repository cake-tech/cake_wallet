import 'dart:async';
import 'dart:developer';

import 'package:cake_wallet/core/wallet_creation_service.dart';
import 'package:cake_wallet/entities/load_current_wallet.dart';
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
  WalletCreationVMBase(this._appStore, this._walletInfoSource,
      this.walletCreationService, this._fiatConversationStore,
      {required this.type, required this.isRecovery})
      : state = InitialExecutionState(),
        name = '';

  @observable
  String name;

  @observable
  ExecutionState state;

  @observable
  PendingTransaction? pendingTransaction;

  WalletType type;
  final bool isRecovery;
  final WalletCreationService walletCreationService;
  final Box<WalletInfo> _walletInfoSource;
  final AppStore _appStore;
  final FiatConversionStore _fiatConversationStore;

  bool nameExists(String name) => walletCreationService.exists(name);

  bool typeExists(WalletType type) => walletCreationService.typeExists(type);

  Future<void> create({dynamic options, RestoredWallet? restoreWallet}) async {
    final type = restoreWallet?.type ?? this.type;
    try {
      //! Create a restoredWallet from the scanned wallet parameters
      final restoredWallet = await createNewWalletWithoutSwitching(
          options: options, restoreWallet: restoreWallet);
      print(
          'Restored Wallet Address ' + restoredWallet.walletAddresses.address);

      //TODO Get transactions details to verify 10 confirmations

      // if (restoreWallet != null &&
      //     restoreWallet.restoreMode == WalletRestoreMode.txids) {

      //* Switch to the restoredWallet in order to activate the node connection
      await _walletInfoSource.add(restoredWallet.walletInfo);
      await connectToNode(restoredWallet);
      _appStore.changeCurrentWallet(restoredWallet);
      await loadCurrentWallet();
      await restoredWallet.startSync();
      print('Before syncing starts');
      await syncCompleter.future;
      print('After syncing ends');

      // * Create the newWallet that will receive the funds
      final newWallet = await createNewWalletWithoutSwitching(
        options: options,
        regenerateName: true,
      );
      final newWalletAddress = newWallet.walletAddresses.address;
      print('New Wallet Address ' + newWalletAddress);

      // * Sweep all funds from restoredWallet to newWallet
      await sweepAllFundsToNewWallet(
        restoredWallet,
        newWallet,
        type,
        newWalletAddress,
        restoreWallet?.txId ?? '',
      );
      // } else {
      // await _walletInfoSource.add(restoredWallet.walletInfo);
      // _appStore.changeCurrentWallet(restoredWallet);
      _appStore.authenticationStore.allowed();
      state = ExecutedSuccessfullyState();
      // }
    } catch (e) {
      print('Errorrrrr');
      state = FailureState(e.toString());
    }
  }

  Future<void> connectToNode(
      WalletBase<Balance, TransactionHistoryBase<TransactionInfo>,
              TransactionInfo>
          wallet) async {
    final node = _appStore.settingsStore.getCurrentNode(wallet.type);
    await wallet.connectToNode(node: node);
  }

  Future<
      WalletBase<Balance, TransactionHistoryBase<TransactionInfo>,
          TransactionInfo>> createNewWalletWithoutSwitching(
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
        isRecovery: isRecovery,
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

  Future<void> sweepAllFundsToNewWallet(
      WalletBase<Balance, TransactionHistoryBase<TransactionInfo>,
              TransactionInfo>
          wallet,
      WalletBase<Balance, TransactionHistoryBase<TransactionInfo>,
              TransactionInfo>
          newWallet,
      WalletType type,
      String newWalletAddress,
      String paymentId) async {
    final output = Output(wallet, _appStore.settingsStore,
        _fiatConversationStore, () => wallet.currency);
    output.address = newWalletAddress;
    output.sendAll = true;
    output.note = 'testing the sweep all function';
    final credentials = _credentials(type, wallet.currency.title, output);
    print('About to enter create function');
    try {
      await createTransaction(wallet, credentials);
      // final currentNode = _appStore.settingsStore.getCurrentNode(type);
      // final result = await walletCreationService.sweepAllFunds(currentNode, newWalletAddress, paymentId);

      //* Switch back to new wallet
      _appStore.changeCurrentWallet(wallet);

      await _walletInfoSource.deleteAt(0);
      //* Add the new Wallet info to the walletInfoSource
      await _walletInfoSource.add(newWallet.walletInfo);

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

  @action
  Future<void> createTransaction(WalletBase wallet, Object credentials) async {
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

// class SweepAllService {
//   final AppStore _appStore;
//   final WalletBase<Balance, TransactionHistoryBase<TransactionInfo>,
//       TransactionInfo> restoredWallet;
//   final WalletBase<Balance, TransactionHistoryBase<TransactionInfo>,
//       TransactionInfo> newWallet;
//   final FiatConversionStore _fiatConversationStore;
//   final Box<WalletInfo> _walletInfoSource;
//   final String? txId;

//   SweepAllService(
//     this._appStore,
//     this.restoredWallet,
//     this._fiatConversationStore,
//     this._walletInfoSource,
//     this.newWallet,
//     this.txId,
//   );

//   Future<void> create() async {
//     try {
//       //* Connect to the Node first
//       await connectToNode(restoredWallet);

//       //* Switch wallet to that of the restoredWallet
//       _appStore.changeCurrentWallet(restoredWallet);

//       //* Load the restore wallet to imitate actual loading
//       await loadCurrentWallet();

//       //* Start the sync
//       await restoredWallet.startSync();
//       print('Before syncing starts');
//       await syncCompleter.future;
//       print('After syncing ends');

//       // * Sweep all funds from restoredWallet to newWallet
//       await sweepAllFundsToNewWallet(
//         restoredWallet,
//         restoredWallet.type,
//         newWallet.walletAddresses.address,
//         txId ?? '',
//       );

//       //* Switch back to new wallet
//       _appStore.changeCurrentWallet(newWallet);

//       //* Add the new Wallet info to the walletInfoSource
//       await _walletInfoSource.add(newWallet.walletInfo);

//       //* Approve authentication as successful
//       _appStore.authenticationStore.allowed();
//     } catch (e) {
//       print('Errorrrrr');
//     }
//   }

//   Future<void> connectToNode(
//       WalletBase<Balance, TransactionHistoryBase<TransactionInfo>,
//               TransactionInfo>
//           wallet) async {
//     final node = _appStore.settingsStore.getCurrentNode(wallet.type);
//     await wallet.connectToNode(node: node);
//   }

//   Future<void> sweepAllFundsToNewWallet(
//       WalletBase<Balance, TransactionHistoryBase<TransactionInfo>,
//               TransactionInfo>
//           wallet,
//       WalletType type,
//       String newWalletAddress,
//       String paymentId) async {
//     final output = Output(wallet, _appStore.settingsStore,
//         _fiatConversationStore, () => wallet.currency);
//     output.address = newWalletAddress;
//     output.sendAll = true;
//     output.note = 'testing the sweep all function';
//     final credentials = _credentials(type, wallet.currency.title, output);
//     print('About to enter create function');
//     try {
//       await createTransaction(wallet, credentials);
//       // final currentNode = _appStore.settingsStore.getCurrentNode(type);
//       // final result = await walletCreationService.sweepAllFunds(currentNode, newWalletAddress, paymentId);
//     } catch (e) {
//       log(e.toString());
//     }
//   }

//   @action
//   Future<void> createTransaction(WalletBase wallet, Object credentials) async {
//     try {
//       print('about to enter wallet create transaction function');
//       final pendingTransaction = await wallet.createTransaction(credentials);
//       print(pendingTransaction);
//     } catch (e) {
//       log(e.toString());
//     }
//   }

//   Object _credentials(
//       WalletType type, String cryptoCurrencyTitle, Output output) {
//     switch (type) {
//       case WalletType.bitcoin:
//         final priority = _appStore.settingsStore.priority[type];

//         if (priority == null) {
//           throw Exception('Priority is null for wallet type: ${type}');
//         }

//         return bitcoin!
//             .createBitcoinTransactionCredentials([output], priority: priority);
//       case WalletType.litecoin:
//         final priority = _appStore.settingsStore.priority[type];

//         if (priority == null) {
//           throw Exception('Priority is null for wallet type: ${type}');
//         }

//         return bitcoin!
//             .createBitcoinTransactionCredentials([output], priority: priority);
//       case WalletType.monero:
//         final priority = _appStore.settingsStore.priority[type];

//         if (priority == null) {
//           throw Exception('Priority is null for wallet type: ${type}');
//         }

//         return monero!.createMoneroTransactionCreationCredentials(
//             outputs: [output], priority: priority);
//       case WalletType.haven:
//         final priority = _appStore.settingsStore.priority[type];

//         if (priority == null) {
//           throw Exception('Priority is null for wallet type: ${type}');
//         }

//         return haven!.createHavenTransactionCreationCredentials(
//             outputs: [output],
//             priority: priority,
//             assetType: cryptoCurrencyTitle);
//       default:
//         throw Exception('Unexpected wallet type: ${type}');
//     }
//   }
// }
