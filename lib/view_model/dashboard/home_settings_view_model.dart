import 'package:cake_wallet/core/fiat_conversion_service.dart';
import 'package:cake_wallet/entities/fiat_api_mode.dart';
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
  HomeSettingsViewModelBase(this._settingsStore, this._balanceViewModel)
      : tokens = ObservableList<Erc20Token>() {
    _updateTokensList();
  }

  final SettingsStore _settingsStore;
  final BalanceViewModel _balanceViewModel;

  final ObservableList<Erc20Token> tokens;

  @computed
  SortBalanceBy get sortBalanceBy => _settingsStore.sortBalanceBy;

  @action
  void setSortBalanceBy(SortBalanceBy value) {
    _settingsStore.sortBalanceBy = value;
    _sortTokens();
  }

  @computed
  bool get pinNativeToken => _settingsStore.pinNativeTokenAtTop;

  @action
  void setPinNativeToken(bool value) => _settingsStore.pinNativeTokenAtTop = value;

  @action
  void _updateTokensList() {
    _sortTokens();
  }

  Future<void> addErc20Token(Erc20Token token) async {
    await ethereum!.addErc20Token(_balanceViewModel.wallet, token);
    _updateTokensList();
    _updateFiatPrices(token);
  }

  Future<void> deleteErc20Token(Erc20Token token) async {
    await ethereum!.deleteErc20Token(_balanceViewModel.wallet, token);
    _updateTokensList();
  }

  Future<Erc20Token?> getErc20Token(String contractAddress) async =>
      await ethereum!.getErc20Token(_balanceViewModel.wallet, contractAddress);

  CryptoCurrency get nativeToken => _balanceViewModel.wallet.currency;

  void _updateFiatPrices(Erc20Token token) async {
    try {
      _balanceViewModel.fiatConvertationStore.prices[token] =
          await FiatConversionService.fetchPrice(
              crypto: token,
              fiat: _settingsStore.fiatCurrency,
              torOnly: _settingsStore.fiatApiMode == FiatApiMode.torOnly);
    } catch (_) {}
  }

  void changeTokenAvailability(int index, bool value) async {
    tokens[index].enabled = value;
    _balanceViewModel.wallet.updateBalance();
    _updateTokensList();
  }

  void _sortTokens() {
    tokens.clear();

    // Add Sorted Enabled tokens
    for (int i = 0; i < _balanceViewModel.balances.keys.length; i++) {
      final CryptoCurrency currency = _balanceViewModel.balances.keys.elementAt(i);
      if (currency is Erc20Token) {
        tokens.add(currency);
      }
    }

    // Add disabled tokens
    tokens.addAll(ethereum!
        .getERC20Currencies(_balanceViewModel.wallet)
        .where((element) => !element.enabled));
  }
}
