import 'package:cake_wallet/core/wallet_creation_service.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/background_tasks.dart';
import 'package:cake_wallet/view_model/restore/restore_wallet.dart';
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

part 'wallet_creation_vm.g.dart';

class WalletCreationVM = WalletCreationVMBase with _$WalletCreationVM;

abstract class WalletCreationVMBase with Store {
  WalletCreationVMBase(this._appStore, this._walletInfoSource, this.walletCreationService,
      {required this.type, required this.isRecovery})
      : state = InitialExecutionState(),
        name = '';

  @observable
  bool _useTestnet = false;

  @computed
  bool get useTestnet => _useTestnet;

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
      state = IsExecutingState();
      if (name.isEmpty) {
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
        showIntroCakePayCard: (!walletCreationService.typeExists(type)) && type != WalletType.haven,
        derivationPath: credentials.derivationPath,
        derivationType: credentials.derivationType,
      );
      credentials.walletInfo = walletInfo;
      final wallet = restoreWallet != null
          ? await processFromRestoredWallet(credentials, restoreWallet)
          : await process(credentials);
      walletInfo.address = wallet.walletAddresses.address;
      await _walletInfoSource.add(walletInfo);
      await _appStore.changeCurrentWallet(wallet);
      getIt.get<BackgroundTasks>().registerSyncTask();
      _appStore.authenticationStore.allowed();
      state = ExecutedSuccessfullyState();
    } catch (e) {
      state = FailureState(e.toString());
    }
  }

  WalletCredentials getCredentials(dynamic options) => throw UnimplementedError();

  Future<WalletBase> process(WalletCredentials credentials) => throw UnimplementedError();

  WalletCredentials getCredentialsFromRestoredWallet(
          dynamic options, RestoredWallet restoreWallet) =>
      throw UnimplementedError();

  Future<WalletBase> processFromRestoredWallet(
          WalletCredentials credentials, RestoredWallet restoreWallet) =>
      throw UnimplementedError();

  @action
  void toggleUseTestnet(bool? value) {
    _useTestnet = value ?? !_useTestnet;
  }
}
