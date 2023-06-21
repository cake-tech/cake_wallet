import 'package:cake_wallet/entities/sort_balance_types.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/view_model/dashboard/balance_view_model.dart';
import 'package:mobx/mobx.dart';

part 'home_settings_view_model.g.dart';

class HomeSettingsViewModel = HomeSettingsViewModelBase with _$HomeSettingsViewModel;

abstract class HomeSettingsViewModelBase with Store {
  HomeSettingsViewModelBase(this._settingsStore, this._balanceViewModel) {
  }

  final SettingsStore _settingsStore;
  final BalanceViewModel _balanceViewModel;

  @computed
  SortBalanceBy get sortBalanceBy => _settingsStore.sortBalanceBy;

  @action
  void setSortBalanceBy(SortBalanceBy value) => _settingsStore.sortBalanceBy = value;

  @observable
  bool pinNativeToken = false;

  List<String> get tokens =>
      _balanceViewModel.balances.keys.map((e) => e.fullName ?? e.title).toList();
}
