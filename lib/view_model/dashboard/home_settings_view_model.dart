import 'package:cake_wallet/core/fiat_conversion_service.dart';
import 'package:cake_wallet/entities/fiat_api_mode.dart';
import 'package:cake_wallet/entities/sort_balance_types.dart';
import 'package:cake_wallet/ethereum/ethereum.dart';
import 'package:cake_wallet/polygon/polygon.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/view_model/dashboard/balance_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/erc20_token.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';

part 'home_settings_view_model.g.dart';

class HomeSettingsViewModel = HomeSettingsViewModelBase with _$HomeSettingsViewModel;

abstract class HomeSettingsViewModelBase with Store {
  HomeSettingsViewModelBase(this._settingsStore, this._balanceViewModel)
      : tokens = ObservableSet<Erc20Token>() {
    _updateTokensList();
  }

  final SettingsStore _settingsStore;
  final BalanceViewModel _balanceViewModel;

  final ObservableSet<Erc20Token> tokens;

  @observable
  String searchText = '';

  @computed
  SortBalanceBy get sortBalanceBy => _settingsStore.sortBalanceBy;

  @action
  void setSortBalanceBy(SortBalanceBy value) {
    _settingsStore.sortBalanceBy = value;
    _updateTokensList();
  }

  @computed
  bool get pinNativeToken => _settingsStore.pinNativeTokenAtTop;

  @action
  void setPinNativeToken(bool value) => _settingsStore.pinNativeTokenAtTop = value;

  Future<void> addErc20Token(Erc20Token token) async {
    if (_balanceViewModel.wallet.type == WalletType.ethereum) {
      await ethereum!.addErc20Token(_balanceViewModel.wallet, token);
    }

    if (_balanceViewModel.wallet.type == WalletType.polygon) {
      await polygon!.addErc20Token(_balanceViewModel.wallet, token);
    }

    _updateTokensList();
    _updateFiatPrices(token);
  }

  Future<void> deleteErc20Token(Erc20Token token) async {
    if (_balanceViewModel.wallet.type == WalletType.ethereum) {
      await ethereum!.deleteErc20Token(_balanceViewModel.wallet, token);
    }

    if (_balanceViewModel.wallet.type == WalletType.polygon) {
      await polygon!.deleteErc20Token(_balanceViewModel.wallet, token);
    }

    _updateTokensList();
  }

  Future<Erc20Token?> getErc20Token(String contractAddress) async {
    if (_balanceViewModel.wallet.type == WalletType.ethereum) {
      return await ethereum!.getErc20Token(_balanceViewModel.wallet, contractAddress);
    }

    if (_balanceViewModel.wallet.type == WalletType.polygon) {
      return await polygon!.getErc20Token(_balanceViewModel.wallet, contractAddress);
    }

    return null;
  }

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

  void changeTokenAvailability(Erc20Token token, bool value) async {
    token.enabled = value;
    if (_balanceViewModel.wallet.type == WalletType.ethereum) {
      ethereum!.addErc20Token(_balanceViewModel.wallet, token);
    }
    if (_balanceViewModel.wallet.type == WalletType.polygon) {
      polygon!.addErc20Token(_balanceViewModel.wallet, token);
    }
    _refreshTokensList();
  }

  @action
  void _updateTokensList() {
    int _sortFunc(Erc20Token e1, Erc20Token e2) {
      int index1 = _balanceViewModel.formattedBalances.indexWhere((element) => element.asset == e1);
      int index2 = _balanceViewModel.formattedBalances.indexWhere((element) => element.asset == e2);

      if (e1.enabled && !e2.enabled) {
        return -1;
      } else if (e2.enabled && !e1.enabled) {
        return 1;
      } else if (!e1.enabled && !e2.enabled) {
        // if both are disabled then sort alphabetically
        return e1.name.compareTo(e2.name);
      }

      return index1.compareTo(index2);
    }

    tokens.clear();

    if (_balanceViewModel.wallet.type == WalletType.ethereum) {
      tokens.addAll(ethereum!
          .getERC20Currencies(_balanceViewModel.wallet)
          .where((element) => _matchesSearchText(element))
          .toList()
        ..sort(_sortFunc));
    }

    if (_balanceViewModel.wallet.type == WalletType.polygon) {
      tokens.addAll(polygon!
          .getERC20Currencies(_balanceViewModel.wallet)
          .where((element) => _matchesSearchText(element))
          .toList()
        ..sort(_sortFunc));
    }
  }

  @action
  void _refreshTokensList() {
    final _tokens = Set.of(tokens);
    tokens.clear();
    tokens.addAll(_tokens);
  }

  @action
  void changeSearchText(String text) {
    searchText = text;
    _updateTokensList();
  }

  bool _matchesSearchText(Erc20Token asset) {
    return searchText.isEmpty ||
        asset.fullName!.toLowerCase().contains(searchText.toLowerCase()) ||
        asset.title.toLowerCase().contains(searchText.toLowerCase()) ||
        asset.contractAddress == searchText;
  }
}
