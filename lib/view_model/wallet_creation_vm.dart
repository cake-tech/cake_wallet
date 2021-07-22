import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/core/wallet_credentials.dart';
import 'package:cake_wallet/entities/pathForWallet.dart';
import 'package:cake_wallet/entities/wallet_info.dart';
import 'package:cake_wallet/entities/wallet_type.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/entities/generate_name.dart';

part 'wallet_creation_vm.g.dart';

class WalletCreationVM = WalletCreationVMBase with _$WalletCreationVM;

abstract class WalletCreationVMBase with Store {
  WalletCreationVMBase(this._appStore, this._walletInfoSource,
      {@required this.type, @required this.isRecovery}) {
    state = InitialExecutionState();
    name = '';
  }

  @observable
  String name;

  @observable
  ExecutionState state;

  WalletType type;
  final bool isRecovery;
  final Box<WalletInfo> _walletInfoSource;
  final AppStore _appStore;

  Future<void> create({dynamic options}) async {
    try {
      state = IsExecutingState();
      name = await generateName();
      final dirPath = await pathForWalletDir(name: name, type: type);
      final path = await pathForWallet(name: name, type: type);
      final credentials = getCredentials(options);
      final walletInfo = WalletInfo.external(
          id: WalletBase.idFor(name, type),
          name: name,
          type: type,
          isRecovery: isRecovery,
          restoreHeight: credentials.height ?? 0,
          date: DateTime.now(),
          path: path,
          dirPath: dirPath);
      credentials.walletInfo = walletInfo;
      final wallet = await process(credentials);
      walletInfo.address = wallet.walletAddresses.address;
      await _walletInfoSource.add(walletInfo);
      _appStore.changeCurrentWallet(wallet);
      _appStore.authenticationStore.allowed();
      state = ExecutedSuccessfullyState();
    } catch (e) {
      state = FailureState(e.toString());
    }
  }

  WalletCredentials getCredentials(dynamic options) =>
      throw UnimplementedError();

  Future<WalletBase> process(WalletCredentials credentials) =>
      throw UnimplementedError();
}
