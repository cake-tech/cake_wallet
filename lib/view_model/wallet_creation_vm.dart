import 'package:cake_wallet/core/wallet_creation_service.dart';
import 'package:cake_wallet/view_model/restore/restore_wallet.dart';
import 'package:cw_core/balance.dart';
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
  WalletCreationVMBase(this._appStore, this._walletInfoSource, this.walletCreationService,
      {required this.type, required this.isRecovery})
      : state = InitialExecutionState(),
        name = '';

  @observable
  String name;

  @observable
  ExecutionState state;

  WalletType type;
  final bool isRecovery;
  final WalletCreationService walletCreationService;
  final Box<WalletInfo> _walletInfoSource;
  final AppStore _appStore;

  bool nameExists(String name) => walletCreationService.exists(name);

  bool typeExists(WalletType type) => walletCreationService.typeExists(type);

  Future<void> create({dynamic options, RestoredWallet? restoreWallet}) async {
    final type = restoreWallet?.type ?? this.type;
    try {
      //! Create a restoredWallet from the scanned wallet parameters
      final restoredWallet =
          await createNewWalletWithoutSwitching(options: options, restoreWallet: restoreWallet);
      print('Restored Wallet Address ' + restoredWallet.walletAddresses.address);

      //TODO Get transactions details to verify 10 confirmations

      //! Create the newWallet that will received the funds
      final newWallet = await createNewWalletWithoutSwitching(
        options: options,
        regenerateName: true,
      );
      final newWalletAddress = newWallet.walletAddresses.address;
      print('New Wallet Address ' + newWalletAddress);

      //! Switch to the restoredWallet in order to activate the node connection
      _appStore.changeCurrentWallet(restoredWallet);

      //! Sweep all funds from restoredWallet to newWallet
      await sweepAllFundsToNewWallet(type, newWalletAddress, restoreWallet?.txId ?? '');

      //! Switch back to new wallet
      _appStore.changeCurrentWallet(newWallet);

      //! Add the new Wallet info to the walletInfoSource
      await _walletInfoSource.add(newWallet.walletInfo);

      //! Approve authentication as successful
      _appStore.authenticationStore.allowed();
      state = ExecutedSuccessfullyState();
    } catch (e) {
      state = FailureState(e.toString());
    }
  }

  Future<WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo>>
      createNewWalletWithoutSwitching(
          {dynamic options, RestoredWallet? restoreWallet, bool regenerateName = false}) async {
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
        showIntroCakePayCard:
            (!walletCreationService.typeExists(type)) && type != WalletType.haven);
    credentials.walletInfo = walletInfo;

    final wallet = restoreWallet != null
        ? await processFromRestoredWallet(credentials, restoreWallet)
        : await process(credentials);
    walletInfo.address = wallet.walletAddresses.address;
   
    return wallet;
  }

  Future<Map<String, dynamic>> sweepAllFundsToNewWallet(
      WalletType type, String address, String paymentId) async {
    final currentNode = _appStore.settingsStore.getCurrentNode(type);
    final result = await walletCreationService.sweepAllFunds(currentNode, address, paymentId);
    return result;
  }

  WalletCredentials getCredentials(dynamic options) {
    switch (type) {
      case WalletType.monero:
        return monero!
            .createMoneroNewWalletCredentials(name: name, language: options as String? ?? '');
      case WalletType.bitcoin:
        return bitcoin!.createBitcoinNewWalletCredentials(name: name);
      case WalletType.litecoin:
        return bitcoin!.createBitcoinNewWalletCredentials(name: name);
      case WalletType.haven:
        return haven!
            .createHavenNewWalletCredentials(name: name, language: options as String? ?? '');
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
