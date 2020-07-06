import 'package:mobx/mobx.dart';
import 'package:cake_wallet/monero/monero_account_list.dart';
import 'package:cake_wallet/view_model/monero_account_list/account_list_item.dart';
import 'package:cake_wallet/view_model/monero_account_list/monero_account_edit_or_create_state.dart';

part 'monero_account_edit_or_create_view_model.g.dart';

class MoneroAccountEditOrCreateViewModel = MoneroAccountEditOrCreateViewModelBase
    with _$MoneroAccountEditOrCreateViewModel;

abstract class MoneroAccountEditOrCreateViewModelBase with Store {
  MoneroAccountEditOrCreateViewModelBase(this._moneroAccountList,
      {AccountListItem accountListItem})
      : state = InitialAccountCreationState(),
        isEdit = accountListItem != null,
        _accountListItem = accountListItem;

  final bool isEdit;

  @observable
  MoneroAccountEditOrCreateState state;

  @observable
  String label;

  final MoneroAccountList _moneroAccountList;
  final AccountListItem _accountListItem;

  Future<void> save() async {
    try {
      state = AccountIsCreating();

      if (_accountListItem != null) {
        await _moneroAccountList.setLabelAccount(
            accountIndex: _accountListItem.id, label: label);
      } else {
        await _moneroAccountList.addAccount(label: label);
      }

      state = AccountCreatedSuccessfully();
    } catch (e) {
      state = AccountCreationFailure(error: e.toString());
    }
  }
}
