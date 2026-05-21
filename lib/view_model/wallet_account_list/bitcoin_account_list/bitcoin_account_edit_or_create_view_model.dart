import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/view_model/wallet_account_list/account_edit_or_create_view_model.dart';
import 'package:cake_wallet/view_model/wallet_account_list/account_list_item.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';

part 'bitcoin_account_edit_or_create_view_model.g.dart';

class BitcoinAccountEditOrCreateViewModel = BitcoinAccountEditOrCreateViewModelBase
    with _$BitcoinAccountEditOrCreateViewModel;

abstract class BitcoinAccountEditOrCreateViewModelBase with Store implements WalletAccountEditOrCreateViewModel{
  BitcoinAccountEditOrCreateViewModelBase({
    required WalletBase wallet,
    AccountListItem? accountListItem,
  })  : state = InitialExecutionState(),
        isEdit = accountListItem != null,
        label = accountListItem?.label ?? '',
        _accountListItem = accountListItem,
        _wallet = wallet;

  final bool isEdit;

  @observable
  ExecutionState state;

  @observable
  String label;

  final AccountListItem? _accountListItem;
  final WalletBase _wallet;

  Future<void> save() async {
    try {
      state = IsExecutingState();

      if (_accountListItem != null) {
        await _renameAccount(_accountListItem.id, label);
      } else {
        await _createAccount(label);
      }

      await _wallet.save();
      state = ExecutedSuccessfullyState();
    } catch (e) {
      state = FailureState(e.toString());
    }
  }

  Future<void> _createAccount(String label) async {
    // TODO: connect this to Bitcoin wallet account storage/service.
    // Expected behavior:
    // 1. Get next account index.
    // 2. Save account label.
    // 3. Generate initial receive/change addresses for this account if needed.
    debugPrint('Create Bitcoin account: $label');
  }

  Future<void> _renameAccount(int accountIndex, String label) async {
    // TODO: connect this to Bitcoin wallet account storage/service.
    // Expected behavior:
    // 1. Find account by index.
    // 2. Update label.
    debugPrint('Rename Bitcoin account $accountIndex: $label');
  }
}
