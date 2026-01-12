import 'dart:convert';

import 'package:cake_wallet/arbitrum/arbitrum.dart';
import 'package:cake_wallet/base/base.dart';
import 'package:cake_wallet/core/fiat_conversion_service.dart';
import 'package:cake_wallet/entities/fiat_api_mode.dart';
import 'package:cake_wallet/entities/erc20_token_info_moralis.dart';
import 'package:cake_wallet/entities/sort_balance_types.dart';
import 'package:cake_wallet/ethereum/ethereum.dart';
import 'package:cake_wallet/polygon/polygon.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/solana/solana.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/tron/tron.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cake_wallet/view_model/dashboard/balance_view_model.dart';
import 'package:cake_wallet/zano/zano.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/erc20_token.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;

part 'home_settings_view_model.g.dart';

class HomeSettingsViewModel = HomeSettingsViewModelBase with _$HomeSettingsViewModel;

abstract class HomeSettingsViewModelBase with Store {
  HomeSettingsViewModelBase(this._settingsStore, this._balanceViewModel)
      : tokens = ObservableSet<CryptoCurrency>(),
        isAddingToken = false,
        isDeletingToken = false,
        isValidatingContractAddress = false {
    _updateTokensList();
  }

  final SettingsStore _settingsStore;
  final BalanceViewModel _balanceViewModel;

  final ObservableSet<CryptoCurrency> tokens;

  WalletType get walletType => _balanceViewModel.wallet.type;

  @observable
  bool isAddingToken;

  @observable
  bool isDeletingToken;

  @observable
  bool isValidatingContractAddress;

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

  @action
  Future<void> addToken({
    required String contractAddress,
    required CryptoCurrency token,
  }) async {
    try {
      isAddingToken = true;
      if (_balanceViewModel.wallet.type == WalletType.ethereum) {
        final erc20token = Erc20Token(
          name: token.name,
          symbol: token.title,
          decimal: token.decimals,
          contractAddress: contractAddress.toLowerCase(),
          iconPath: token.iconPath,
          isPotentialScam: token.isPotentialScam,
        );

        await ethereum!.addErc20Token(_balanceViewModel.wallet, erc20token);
      }

      if (_balanceViewModel.wallet.type == WalletType.polygon) {
        final polygonToken = Erc20Token(
          name: token.name,
          symbol: token.title,
          decimal: token.decimals,
          contractAddress: contractAddress.toLowerCase(),
          iconPath: token.iconPath,
          isPotentialScam: token.isPotentialScam,
        );
        await polygon!.addErc20Token(_balanceViewModel.wallet, polygonToken);
      }

      if (_balanceViewModel.wallet.type == WalletType.base) {
        final baseToken = Erc20Token(
          name: token.name,
          symbol: token.title,
          decimal: token.decimals,
          contractAddress: contractAddress.toLowerCase(),
          iconPath: token.iconPath,
          isPotentialScam: token.isPotentialScam,
        );
        await base!.addErc20Token(_balanceViewModel.wallet, baseToken);
      }
      if (_balanceViewModel.wallet.type == WalletType.arbitrum) {
        final arbitrumToken = Erc20Token(
          name: token.name,
          symbol: token.title,
          decimal: token.decimals,
          contractAddress: contractAddress.toLowerCase(),
          iconPath: token.iconPath,
          isPotentialScam: token.isPotentialScam,
        );
        await arbitrum!.addErc20Token(_balanceViewModel.wallet, arbitrumToken);
      }

      if (_balanceViewModel.wallet.type == WalletType.solana) {
        final splToken = token.copyWith(enabled: true);
        await solana!.addSPLToken(
          _balanceViewModel.wallet,
          splToken,
          contractAddress,
        );
      }

      if (_balanceViewModel.wallet.type == WalletType.tron) {
        final tronToken = token.copyWith(enabled: true);
        await tron!.addTronToken(_balanceViewModel.wallet, tronToken, contractAddress);
      }

      if (_balanceViewModel.wallet.type == WalletType.zano) {
        await zano!.addZanoAssetById(_balanceViewModel.wallet, contractAddress);
      }

      _updateTokensList();
      _updateFiatPrices(token);
    } catch (e) {
      throw e;
    } finally {
      isAddingToken = false;
    }
  }

  @action
  bool checkIfTokenIsAlreadyAdded(String contractAddress) {
    if (_balanceViewModel.wallet.type == WalletType.ethereum) {
      return ethereum!.isTokenAlreadyAdded(_balanceViewModel.wallet, contractAddress);
    }

    if (_balanceViewModel.wallet.type == WalletType.polygon) {
      return polygon!.isTokenAlreadyAdded(_balanceViewModel.wallet, contractAddress);
    }

    if (_balanceViewModel.wallet.type == WalletType.base) {
      return base!.isTokenAlreadyAdded(_balanceViewModel.wallet, contractAddress);
    }

    if (_balanceViewModel.wallet.type == WalletType.arbitrum) {
      return arbitrum!.isTokenAlreadyAdded(_balanceViewModel.wallet, contractAddress);
    }

    if (_balanceViewModel.wallet.type == WalletType.solana) {
      return solana!.isTokenAlreadyAdded(_balanceViewModel.wallet, contractAddress);
    }

    if (_balanceViewModel.wallet.type == WalletType.tron) {
      return tron!.isTokenAlreadyAdded(_balanceViewModel.wallet, contractAddress);
    }

    if (_balanceViewModel.wallet.type == WalletType.zano) {
      return zano!.isTokenAlreadyAdded(_balanceViewModel.wallet, contractAddress);
    }

    return false;
  }

  @action
  Future<void> deleteToken(CryptoCurrency token) async {
    try {
      isDeletingToken = true;
      if (_balanceViewModel.wallet.type == WalletType.ethereum) {
        await ethereum!.deleteErc20Token(_balanceViewModel.wallet, token as Erc20Token);
      }

      if (_balanceViewModel.wallet.type == WalletType.polygon) {
        await polygon!.deleteErc20Token(_balanceViewModel.wallet, token as Erc20Token);
      }

      if (_balanceViewModel.wallet.type == WalletType.base) {
        await base!.deleteErc20Token(_balanceViewModel.wallet, token as Erc20Token);
      }

      if (_balanceViewModel.wallet.type == WalletType.arbitrum) {
        await arbitrum!.deleteErc20Token(_balanceViewModel.wallet, token as Erc20Token);
      }

      if (_balanceViewModel.wallet.type == WalletType.solana) {
        await solana!.deleteSPLToken(_balanceViewModel.wallet, token);
      }

      if (_balanceViewModel.wallet.type == WalletType.tron) {
        await tron!.deleteTronToken(_balanceViewModel.wallet, token);
      }
      if (_balanceViewModel.wallet.type == WalletType.zano) {
        await zano!.deleteZanoAsset(_balanceViewModel.wallet, token);
      }
      _updateTokensList();
    } finally {
      isDeletingToken = false;
    }
  }

  Future<bool> checkIfERC20TokenContractAddressIsAPotentialScamAddress(
    String contractAddress,
  ) async {
    try {
      isValidatingContractAddress = true;

      if (!isEVMCompatibleChain(_balanceViewModel.wallet.type)) {
        return false;
      }

      bool isPotentialScamViaMoralis = await _isPotentialScamTokenViaMoralis(
        contractAddress,
        getChainNameBasedOnWalletType(_balanceViewModel.wallet.type),
      );

      bool isUnverifiedContract = await _isContractUnverified(
        contractAddress,
        chainId: getChainIdBasedOnWalletType(_balanceViewModel.wallet.type).toString(),
      );

      final showWarningForContractAddress = isPotentialScamViaMoralis || isUnverifiedContract;

      return showWarningForContractAddress;
    } finally {
      isValidatingContractAddress = false;
    }
  }

  bool checkIfTokenIsWhitelisted(String contractAddress) {
    // get the default tokens for each currency type:
    List<String> defaultTokenAddresses = [];
    switch (_balanceViewModel.wallet.type) {
      case WalletType.ethereum:
        defaultTokenAddresses = ethereum!.getDefaultTokenContractAddresses();
        break;
      case WalletType.polygon:
        defaultTokenAddresses = polygon!.getDefaultTokenContractAddresses();
        break;
      case WalletType.base:
        defaultTokenAddresses = base!.getDefaultTokenContractAddresses();
        break;
      case WalletType.arbitrum:
        defaultTokenAddresses = arbitrum!.getDefaultTokenContractAddresses();
        break;
      case WalletType.solana:
        defaultTokenAddresses = solana!.getDefaultTokenContractAddresses();
        break;
      case WalletType.tron:
        defaultTokenAddresses = tron!.getDefaultTokenContractAddresses();
        break;
      case WalletType.zano:
      case WalletType.banano:
      case WalletType.monero:
      case WalletType.none:
      case WalletType.bitcoin:
      case WalletType.litecoin:
      case WalletType.haven:
      case WalletType.nano:
      case WalletType.wownero:
      case WalletType.bitcoinCash:
      case WalletType.decred:
      case WalletType.dogecoin:
      case WalletType.zcash:
        return false;
    }

    // check if the contractAddress is in the defaultTokenAddresses
    bool isInWhitelist = defaultTokenAddresses
        .any((element) => element.toLowerCase() == contractAddress.toLowerCase());
    return isInWhitelist;
  }

  Future<bool> _isPotentialScamTokenViaMoralis(
    String contractAddress,
    String chainName,
  ) async {
    final uri = Uri.https(
      'deep-index.moralis.io',
      '/api/v2.2/erc20/metadata',
      {
        "chain": chainName,
        "addresses": contractAddress,
      },
    );

    try {
      final response = await ProxyWrapper().get(
        clearnetUri: uri,
        headers: {
          "Accept": "application/json",
          "X-API-Key": secrets.moralisApiKey,
        },
      );

      final decodedResponse = jsonDecode(response.body);

      final tokenInfo = Erc20TokenInfoMoralis.fromJson(decodedResponse[0] as Map<String, dynamic>);

      // Based on analysis using Moralis internal metrics
      if (tokenInfo.possibleSpam == true) {
        return true;
      }

      // Tokens whose contract have not been verified are potentially risky tokens.
      if (tokenInfo.verifiedContract == false) {
        return true;
      }

      // Tokens with a security score less than 40 are potentially risky, requiring caution when dealing with them.
      if (tokenInfo.securityScore != null && tokenInfo.securityScore! < 40) {
        return true;
      }

      // Having a Fully Diluted Valiuation of 0 is a significant red flag that could signify:
      // - An abandoned/unlaunched project
      // - Incorrect/missing token data
      // - Suspicious manipulation of token data

      /// commented out as it's failing a lot of legit tokens
      // if (tokenInfo.fullyDilutedValuation == '0') {
      //   return true;
      // }

      return false;
    } catch (e) {
      printV('Error while checking scam via moralis: ${e.toString()}');
      return true;
    }
  }

  Future<bool> _isContractUnverified(
    String contractAddress, {
    required String chainId,
  }) async {
    final uri = Uri.https(
      "api.etherscan.io",
      "/v2/api",
      {
        "chainid": chainId,
        "module": "contract",
        "action": "getsourcecode",
        "address": contractAddress,
        "apikey": secrets.etherScanApiKey,
      },
    );

    try {
      final response = await ProxyWrapper().get(clearnetUri: uri);

      final decodedResponse = jsonDecode(response.body) as Map<String, dynamic>;

      if (decodedResponse['status'] == '0') {
        printV('${response.body}\n');
        printV('${decodedResponse['result']}\n');
        return true;
      }

      if (decodedResponse['status'] == '1' &&
          decodedResponse['result'][0]['ABI'] == 'Contract source code not verified') {
        printV('Call is valid but contract is not verified');
        return true; // Contract is not verified
      } else {
        printV('Call is valid and contract is verified');
        return false; // Contract is verified
      }
    } catch (e) {
      printV('Error while checking contract verification: ${e.toString()}');
      return true;
    }
  }

  Future<CryptoCurrency?> getToken(String contractAddress) async {
    if (_balanceViewModel.wallet.type == WalletType.ethereum) {
      return await ethereum!.getErc20Token(_balanceViewModel.wallet, contractAddress);
    }

    if (_balanceViewModel.wallet.type == WalletType.polygon) {
      return await polygon!.getErc20Token(_balanceViewModel.wallet, contractAddress);
    }

    if (_balanceViewModel.wallet.type == WalletType.base) {
      return await base!.getErc20Token(_balanceViewModel.wallet, contractAddress);
    }

    if (_balanceViewModel.wallet.type == WalletType.arbitrum) {
      return await arbitrum!.getErc20Token(_balanceViewModel.wallet, contractAddress);
    }

    if (_balanceViewModel.wallet.type == WalletType.solana) {
      return await solana!.getSPLToken(_balanceViewModel.wallet, contractAddress);
    }

    if (_balanceViewModel.wallet.type == WalletType.tron) {
      return await tron!.getTronToken(_balanceViewModel.wallet, contractAddress);
    }

    if (_balanceViewModel.wallet.type == WalletType.zano) {
      return await zano!.getZanoAsset(_balanceViewModel.wallet, contractAddress);
    }

    return null;
  }

  CryptoCurrency get nativeToken => _balanceViewModel.wallet.currency;

  void _updateFiatPrices(CryptoCurrency token) async {
    if (token.isPotentialScam) return; // don't fetch price data for potential scam tokens
    try {
      _balanceViewModel.fiatConvertationStore.prices[token] =
          await FiatConversionService.fetchPrice(
              crypto: token,
              fiat: _settingsStore.fiatCurrency,
              torOnly: _settingsStore.fiatApiMode == FiatApiMode.torOnly);
    } catch (_) {}
  }

  void changeTokenAvailability(CryptoCurrency token, bool value) async {
    token.enabled = value;

    if (_balanceViewModel.wallet.type == WalletType.ethereum) {
      ethereum!.addErc20Token(_balanceViewModel.wallet, token as Erc20Token);
      if (!value) ethereum!.removeTokenTransactionsInHistory(_balanceViewModel.wallet, token);
    }

    if (_balanceViewModel.wallet.type == WalletType.polygon) {
      polygon!.addErc20Token(_balanceViewModel.wallet, token as Erc20Token);
      if (!value) polygon!.removeTokenTransactionsInHistory(_balanceViewModel.wallet, token);
    }

    if (_balanceViewModel.wallet.type == WalletType.base) {
      base!.addErc20Token(_balanceViewModel.wallet, token as Erc20Token);
      if (!value) base!.removeTokenTransactionsInHistory(_balanceViewModel.wallet, token);
    }

    if (_balanceViewModel.wallet.type == WalletType.arbitrum) {
      arbitrum!.addErc20Token(_balanceViewModel.wallet, token as Erc20Token);
      if (!value) arbitrum!.removeTokenTransactionsInHistory(_balanceViewModel.wallet, token);
    }

    if (_balanceViewModel.wallet.type == WalletType.solana) {
      final address = solana!.getTokenAddress(token);
      solana!.addSPLToken(_balanceViewModel.wallet, token, address);
    }

    if (_balanceViewModel.wallet.type == WalletType.tron) {
      final address = tron!.getTokenAddress(token);
      tron!.addTronToken(_balanceViewModel.wallet, token, address);
    }

    if (_balanceViewModel.wallet.type == WalletType.zano) {
      await zano!.changeZanoAssetAvailability(_balanceViewModel.wallet, token);
    }

    _refreshTokensList();
  }

  @action
  void _updateTokensList() {
    int _sortFunc(CryptoCurrency e1, CryptoCurrency e2) {
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

    if (_balanceViewModel.wallet.type == WalletType.base) {
      tokens.addAll(base!
          .getERC20Currencies(_balanceViewModel.wallet)
          .where((element) => _matchesSearchText(element))
          .toList()
        ..sort(_sortFunc));
    }

    if (_balanceViewModel.wallet.type == WalletType.arbitrum) {
      tokens.addAll(arbitrum!
          .getERC20Currencies(_balanceViewModel.wallet)
          .where((element) => _matchesSearchText(element))
          .toList()
        ..sort(_sortFunc));
    }

    if (_balanceViewModel.wallet.type == WalletType.solana) {
      tokens.addAll(solana!
          .getSPLTokenCurrencies(_balanceViewModel.wallet)
          .where((element) => _matchesSearchText(element))
          .toList()
        ..sort(_sortFunc));
    }

    if (_balanceViewModel.wallet.type == WalletType.tron) {
      tokens.addAll(tron!
          .getTronTokenCurrencies(_balanceViewModel.wallet)
          .where((element) => _matchesSearchText(element))
          .toList()
        ..sort(_sortFunc));
    }

    if (_balanceViewModel.wallet.type == WalletType.zano) {
      tokens.addAll(zano!
          .getZanoAssets(_balanceViewModel.wallet)
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

  bool _matchesSearchText(CryptoCurrency asset) {
    final address = getTokenAddressBasedOnWallet(asset);

    // The homes settings would only be displayed for either of Tron, EVM or Solana Wallets.
    if (address == null) return false;

    return searchText.isEmpty ||
        asset.fullName!.toLowerCase().contains(searchText.toLowerCase()) ||
        asset.title.toLowerCase().contains(searchText.toLowerCase()) ||
        address == searchText;
  }

  String? getTokenAddressBasedOnWallet(CryptoCurrency asset) {
    if (_balanceViewModel.wallet.type == WalletType.tron) {
      return tron!.getTokenAddress(asset);
    }

    if (_balanceViewModel.wallet.type == WalletType.solana) {
      return solana!.getTokenAddress(asset);
    }

    if (_balanceViewModel.wallet.type == WalletType.ethereum) {
      return ethereum!.getTokenAddress(asset);
    }

    if (_balanceViewModel.wallet.type == WalletType.polygon) {
      return polygon!.getTokenAddress(asset);
    }

    if (_balanceViewModel.wallet.type == WalletType.base) {
      return base!.getTokenAddress(asset);
    }

    if (_balanceViewModel.wallet.type == WalletType.arbitrum) {
      return arbitrum!.getTokenAddress(asset);
    }

    if (_balanceViewModel.wallet.type == WalletType.zano) {
      return zano!.getZanoAssetAddress(asset);
    }

    // We return null if it's neither Tron, EVM or Solana wallet (which is actually impossible because we only display home settings for either of these four wallets).
    return null;
  }
}
