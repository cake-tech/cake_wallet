import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/haven/haven.dart';
import 'package:cake_wallet/view_model/monero_account_list/account_list_item.dart';

part 'monero_account_edit_or_create_view_model.g.dart';

class MoneroAccountEditOrCreateViewModel = MoneroAccountEditOrCreateViewModelBase
    with _$MoneroAccountEditOrCreateViewModel;

abstract class MoneroAccountEditOrCreateViewModelBase with Store {
  MoneroAccountEditOrCreateViewModelBase(this._moneroAccountList, this._havenAccountList,
      {required WalletBase wallet, AccountListItem? accountListItem})
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
  final HavenAccountList? _havenAccountList;
  final AccountListItem? _accountListItem;
  final WalletBase _wallet;

  Future<void> save() async {
    if (_wallet.type == WalletType.monero) {
      await saveMonero();
    }

    if (_wallet.type == WalletType.haven) {
      await saveHaven();
    }
  }

  Future<void> saveMonero() async {
    try {
      state = IsExecutingState();

      if (_accountListItem != null) {
        await _moneroAccountList.setLabelAccount(
            _wallet,
            accountIndex: _accountListItem!.id,
            label: label);
      } else {
        await _moneroAccountList.addAccount(
          _wallet,
          label: label);
      }

      await _wallet.save();
      state = ExecutedSuccessfullyState();
    } catch (e) {
      state = FailureState(e.toString());
    }
  }

  Future<void> saveHaven() async {
    if (!(_wallet.type == WalletType.haven)) {
      return;
    }

    try {
      state = IsExecutingState();

      if (_accountListItem != null) {
        await _havenAccountList!.setLabelAccount(
            _wallet,
            accountIndex: _accountListItem!.id,
            label: label);
      } else {
        await _havenAccountList!.addAccount(
          _wallet,
          label: label);
      }

      await _wallet.save();
      state = ExecutedSuccessfullyState();
    } catch (e) {
      state = FailureState(e.toString());
    }
  }
}
