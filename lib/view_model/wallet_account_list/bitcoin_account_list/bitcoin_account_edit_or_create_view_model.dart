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
    final accounts = await _wallet.walletInfo.getAccounts();

    final nextIndex = accounts.isEmpty
        ? 0
        : accounts.map((e) => e.accountIndex).reduce((a, b) => a > b ? a : b) + 1;

    await _wallet.walletInfo.addAccount(
      accountIndex: nextIndex,
      label: label.isEmpty ? 'Account $nextIndex' : label,
    );

    await _wallet.walletInfo.setSelectedAccount(nextIndex);
  }

  Future<void> _renameAccount(int accountIndex, String label) async {
    await _wallet.walletInfo.renameAccount(
      accountIndex: accountIndex,
      label: label.isEmpty ? 'Account $accountIndex' : label,
    );
  }
}
