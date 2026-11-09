import 'package:cake_wallet/nano/nano.dart';
import 'package:cw_core/nano_account.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';

import 'package:mobx/mobx.dart';
import 'package:cake_wallet/core/execution_state.dart';

part 'nano_account_edit_or_create_view_model.g.dart';

class NanoAccountEditOrCreateViewModel = NanoAccountEditOrCreateViewModelBase
    with _$NanoAccountEditOrCreateViewModel;

abstract class NanoAccountEditOrCreateViewModelBase with Store {
  NanoAccountEditOrCreateViewModelBase(this._nanoAccountList,
      {required WalletBase wallet, NanoAccount? accountListItem})
      : state = InitialExecutionState(),
        isEdit = accountListItem != null,
        label = accountListItem?.label ?? '',
        _accountListItem = accountListItem,
        _wallet = wallet;

  final bool isEdit;

  @observable
  ExecutionState state;

  @observable
  String label;

  final NanoAccountList _nanoAccountList;
  final NanoAccount? _accountListItem;
  final WalletBase _wallet;

  Future<void> save() async {
    if (_wallet.type == WalletType.nano) {
      await saveNano();
    }
  }

  Future<void> saveNano() async {
    try {
      state = IsExecutingState();

      if (_accountListItem != null) {
        await _nanoAccountList.setLabelAccount(_wallet,
            accountIndex: _accountListItem!.id, label: label);
      } else {
        await _nanoAccountList.addAccount(_wallet, label: label);
      }

      await _wallet.save();
      state = ExecutedSuccessfullyState();
    } catch (e) {
      state = FailureState(e.toString());
    }
  }
}
