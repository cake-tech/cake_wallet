import 'package:cake_wallet/entities/sort_balance_types.dart';
import 'package:cake_wallet/ethereum/ethereum.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/view_model/dashboard/balance_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/erc20_token.dart';
import 'package:mobx/mobx.dart';

part 'home_settings_view_model.g.dart';

class HomeSettingsViewModel = HomeSettingsViewModelBase with _$HomeSettingsViewModel;

abstract class HomeSettingsViewModelBase with Store {
  HomeSettingsViewModelBase(this._settingsStore, this._balanceViewModel);

  final SettingsStore _settingsStore;
  final BalanceViewModel _balanceViewModel;

  @computed
  SortBalanceBy get sortBalanceBy => _settingsStore.sortBalanceBy;

  @action
  void setSortBalanceBy(SortBalanceBy value) => _settingsStore.sortBalanceBy = value;

  @computed
  bool get pinNativeToken => _settingsStore.pinNativeTokenAtTop;

  @action
  void setPinNativeToken(bool value) => _settingsStore.pinNativeTokenAtTop = value;

  @computed
  List<String> get tokens =>
      _balanceViewModel.balances.keys.map((e) => e.fullName ?? e.title).toList();

  Future<CryptoCurrency?> addErc20Token(String contractAddress) async =>
      await ethereum!.addErc20Token(_balanceViewModel.wallet, contractAddress);

  Future<Erc20Token?> getErc20Token(String contractAddress) async =>
      await ethereum!.getErc20Token(_balanceViewModel.wallet, contractAddress);

  String get nativeToken => _balanceViewModel.wallet.currency.title;
}
