import 'package:cake_wallet/entities/wallet_info.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_item.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/core/execution_state.dart';

part 'wallet_edit_name_vm.g.dart';

class WalletEditNameVM = WalletEditNameVMBase with _$WalletEditNameVM;

abstract class WalletEditNameVMBase with Store {
  WalletEditNameVMBase(this._walletInfoSource, {WalletListItem wallet})
      : state = InitialExecutionState(),
        _wallet = wallet {
    displayName = _wallet?.displayName;
  }

  final Box<WalletInfo> _walletInfoSource;
  final WalletListItem _wallet;

  @observable
  ExecutionState state;

  @observable
  String displayName;

  @computed
  bool get isReady => displayName?.isNotEmpty ?? false;

  Future save() async {
    try {
      state = IsExecutingState();

      final info = _walletInfoSource.values.firstWhere((element) =>
      element.name == _wallet.name);
      info.displayName = displayName;
      await info.save();

      state = ExecutedSuccessfullyState();
    } catch (e) {
      state = FailureState(e.toString());
    }
  }
}