import 'package:cake_wallet/core/wallet_base.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/monero/monero_account_list.dart';
import 'package:cake_wallet/view_model/monero_account_list/account_list_item.dart';

part 'monero_account_edit_or_create_view_model.g.dart';

class MoneroAccountEditOrCreateViewModel = MoneroAccountEditOrCreateViewModelBase
    with _$MoneroAccountEditOrCreateViewModel;

abstract class MoneroAccountEditOrCreateViewModelBase with Store {
  MoneroAccountEditOrCreateViewModelBase(this._moneroAccountList,
      {@required WalletBase wallet, AccountListItem accountListItem})
      : state = InitialExecutionState(),
        isEdit = accountListItem != null,
        label = accountListItem?.label??'',
        _accountListItem = accountListItem,
        _wallet = wallet;

  final bool isEdit;

  @observable
  ExecutionState state;

  @observable
  String label;

  final MoneroAccountList _moneroAccountList;
  final AccountListItem _accountListItem;
  final WalletBase _wallet;

  Future<void> save() async {
    try {
      state = IsExecutingState();

      if (_accountListItem != null) {
        await _moneroAccountList.setLabelAccount(
            accountIndex: _accountListItem.id, label: label);
      } else {
        await _moneroAccountList.addAccount(label: label);
      }

      await _wallet.save();
      state = ExecutedSuccessfullyState();
    } catch (e) {
      state = FailureState(e.toString());
    }
  }
}
