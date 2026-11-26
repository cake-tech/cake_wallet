import "dart:async";
import 'dart:convert';

import 'package:cake_wallet/core/fiat_conversion_service.dart';
import 'package:cake_wallet/entities/fiat_api_mode.dart';
import 'package:cake_wallet/entities/erc20_token_info_moralis.dart';
import 'package:cake_wallet/entities/sort_balance_types.dart';
import 'package:cake_wallet/evm/evm.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/solana/solana.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/tron/tron.dart';
import 'package:cake_wallet/utils/token_utilities.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cake_wallet/view_model/dashboard/balance_view_model.dart';
import 'package:cake_wallet/zano/zano.dart';
import "package:collection/collection.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/balance.dart";
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/erc20_token.dart';
import 'package:cw_core/utils/homoglyph_normalizer.dart';
import 'package:cw_core/utils/print_verbose.dart';
import "package:cw_core/wallet_base.dart";
import 'package:cw_core/wallet_type.dart';
import "package:cw_core/zano_asset.dart";
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;

part 'home_settings_view_model.g.dart';

class HomeSettingsViewModel = HomeSettingsViewModelBase with _$HomeSettingsViewModel;

abstract class HomeSettingsViewModelBase with Store {
  HomeSettingsViewModelBase(this._settingsStore, this._balanceViewModel)
      : tokens = ObservableSet<CryptoCurrency>(),
        isAddingToken = false,
        isDeletingToken = false,
        isValidatingContractAddress = false,
        showCombinedBalance = _balanceViewModel.wallet.walletInfo.showCombinedBalance,
        favoriteToken = _balanceViewModel.wallet.currency {
    _updateLocalFavoriteToken();

    _walletTokensReaction = reaction(
      (_) => _walletTokens(),
      (_) {
        _updateTokensList();
        unawaited(_loadTokenBalances());
      },
      fireImmediately: true,
    );
  }

  final SettingsStore _settingsStore;
  final BalanceViewModel _balanceViewModel;

  final ObservableSet<CryptoCurrency> tokens;

  final ObservableMap<CryptoCurrency, Balance> _tokenBalances = ObservableMap();
  final ObservableSet<CryptoCurrency> _toggledOff = ObservableSet();
  Map<String, int> _defaultTokenRanks = {};
  late final ReactionDisposer _walletTokensReaction;
  int _balanceRequestId = 0;
  WalletBase? _balancesWallet;

  @observable
  bool isLoadingTokenBalances = true;

  @computed
  List<CryptoCurrency> get enabledTokens =>
      [_balanceViewModel.wallet.currency, ...tokens.where((item) => item.enabled).toList()];

  ({List<CryptoCurrency> holdings, List<CryptoCurrency> popular, List<CryptoCurrency> other})
      get tokenSections {
    final holdings = <CryptoCurrency>[];
    final popular = <CryptoCurrency>[];
    final other = <CryptoCurrency>[];

    for (final token in tokens) {
      if (heldBalance(token) != null) {
        holdings.add(token);
      } else if (_isDefaultToken(token)) {
        popular.add(token);
      } else {
        other.add(token);
      }
    }

    return (holdings: holdings, popular: popular, other: other);
  }

  List<CryptoCurrency> visiblePopular(List<CryptoCurrency> popular) {
    bool isOn(CryptoCurrency token) => token.enabled || _toggledOff.contains(token);
    var topUp = 3 - popular.where(isOn).length;
    return [
      for (final token in popular)
        if (isOn(token) || topUp-- > 0) token,
    ];
  }

  void clearToggledOff() => _toggledOff.clear();

  bool isVerified(CryptoCurrency token) =>
      token != nativeToken &&
      (token is ZanoAsset ? token.isInGlobalWhitelist : _isDefaultToken(token));

  Money? heldBalance(CryptoCurrency token) {
    final balance = _balance(token);
    return balance == null || (balance.available.isZero && balance.unavailable.isZero)
        ? null
        : balance.available;
  }

  CryptoCurrency _balanceKey(CryptoCurrency token, Iterable<CryptoCurrency> keys) {
    if (token is ZanoAsset) {
      return keys.firstWhereOrNull((key) => key is ZanoAsset && key.assetId == token.assetId) ??
          token;
    }
    return token;
  }

  Balance? _balance(CryptoCurrency token) {
    final balances = _balanceViewModel.wallet.balance;
    return balances[_balanceKey(token, balances.keys)] ??
        _tokenBalances[_balanceKey(token, _tokenBalances.keys)];
  }

  bool _isDefaultToken(CryptoCurrency token) =>
      checkIfTokenIsWhitelisted(getTokenAddressBasedOnWallet(token)!);

  void dispose() {
    _walletTokensReaction();
    _balanceRequestId++;
  }

  WalletType get walletType => _balanceViewModel.wallet.type;

  @observable
  bool isAddingToken;

  @observable
  bool isDeletingToken;

  @observable
  bool isValidatingContractAddress;

  @computed
  SortBalanceBy get sortBalanceBy => _settingsStore.sortBalanceBy;

  @action
  void setSortBalanceBy(SortBalanceBy value) => _settingsStore.sortBalanceBy = value;

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

      if (isEVMCompatibleChain(_balanceViewModel.wallet.type)) {
        final evmToken = Erc20Token(
          name: token.name,
          symbol: token.title,
          decimal: token.decimals,
          contractAddress: contractAddress.toLowerCase(),
          iconPath: token.iconPath,
          isPotentialScam: token.isPotentialScam,
        );
        await evm!.addErc20Token(_balanceViewModel.wallet, evmToken);
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
    if (isEVMCompatibleChain(_balanceViewModel.wallet.type)) {
      return evm!.isTokenAlreadyAdded(_balanceViewModel.wallet, contractAddress);
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
      if (isEVMCompatibleChain(_balanceViewModel.wallet.type)) {
        await evm!.deleteErc20Token(_balanceViewModel.wallet, token as Erc20Token);
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

      final moralisChainName = evm!.getMoralisChainName(_balanceViewModel.wallet);

      final isPotentialScamViaMoralis = moralisChainName != null &&
          await _isPotentialScamTokenViaMoralis(contractAddress, moralisChainName);

      bool isUnverifiedContract = await _isContractUnverified(
        contractAddress,
        chainId: evm!.getSelectedChainId(_balanceViewModel.wallet).toString(),
      );

      final showWarningForContractAddress = isPotentialScamViaMoralis || isUnverifiedContract;

      return showWarningForContractAddress;
    } finally {
      isValidatingContractAddress = false;
    }
  }

  bool checkIfTokenIsWhitelisted(String contractAddress) =>
      _defaultTokenRanks.containsKey(contractAddress.toLowerCase());

  List<String> _defaultTokenAddresses() {
    switch (_balanceViewModel.wallet.type) {
      case WalletType.ethereum:
      case WalletType.polygon:
      case WalletType.base:
      case WalletType.arbitrum:
      case WalletType.bsc:
      case WalletType.robinhood:
        return evm!.getDefaultTokenContractAddresses(_balanceViewModel.wallet);
      case WalletType.solana:
        return solana!.getDefaultTokenContractAddresses();
      case WalletType.tron:
        return tron!.getDefaultTokenContractAddresses();
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
        return [];
    }
  }

  bool checkIfTokenSymbolMatchesDefaultToken(String symbol) {
    final normalizedSymbol = normalizeHomoglyphs(symbol.trim().toUpperCase());
    if (normalizedSymbol.isEmpty) return false;

    List<String> defaultTokenSymbols = [];
    switch (_balanceViewModel.wallet.type) {
      case WalletType.ethereum:
      case WalletType.polygon:
      case WalletType.base:
      case WalletType.arbitrum:
      case WalletType.bsc:
      case WalletType.robinhood:
        defaultTokenSymbols = evm!.getDefaultTokenSymbols(_balanceViewModel.wallet);
        break;
      case WalletType.solana:
        defaultTokenSymbols = solana!.getDefaultTokenSymbols();
        break;
      case WalletType.tron:
        defaultTokenSymbols = tron!.getDefaultTokenSymbols();
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

    return defaultTokenSymbols.any((s) => s.toUpperCase() == normalizedSymbol);
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
      // if (tokenInfo.verifiedContract == false) {
      //   return true;
      // }

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
    if (isEVMCompatibleChain(_balanceViewModel.wallet.type)) {
      return await evm!.getErc20Token(_balanceViewModel.wallet, contractAddress);
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

  Future<bool?> checkIfTokenIsVerifiedOnJupiter(String mintAddress) async {
    if (_balanceViewModel.wallet.type != WalletType.solana) {
      return null;
    }

    return solana!.isTokenVerifiedOnJupiter(_balanceViewModel.wallet, mintAddress);
  }

  CryptoCurrency get nativeToken => _balanceViewModel.wallet.currency;

  void _updateFiatPrices(CryptoCurrency token) async {
    if (token.isPotentialScam) return; // don't fetch price data for potential scam tokens
    try {
      _balanceViewModel.fiatConversionStore.prices[token] = await FiatConversionService.fetchPrice(
          crypto: token,
          fiat: _settingsStore.fiatCurrency,
          torOnly: _settingsStore.fiatApiMode == FiatApiMode.torOnly);
    } catch (_) {}
  }

  void changeTokenAvailability(CryptoCurrency token, bool value) async {
    if (!value) {
      _toggledOff.add(token);
      final balance = _balance(token);
      if (balance != null) {
        _tokenBalances[_balanceKey(token, _tokenBalances.keys)] = balance;
      }
    }
    token.enabled = value;

    if (isEVMCompatibleChain(_balanceViewModel.wallet.type)) {
      evm!.addErc20Token(_balanceViewModel.wallet, token as Erc20Token);
      if (!value) evm!.removeTokenTransactionsInHistory(_balanceViewModel.wallet, token);
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

  List<CryptoCurrency> _walletTokens() {
    final wallet = _balanceViewModel.wallet;
    if (isEVMCompatibleChain(wallet.type)) {
      return evm!.getERC20Currencies(wallet);
    }
    if (wallet.type == WalletType.solana) {
      return solana!.getSPLTokenCurrencies(wallet);
    }
    if (wallet.type == WalletType.tron) {
      return tron!.getTronTokenCurrencies(wallet);
    }
    if (wallet.type == WalletType.zano) {
      return zano!.getZanoAssets(wallet);
    }
    return [];
  }

  @action
  void _updateTokensList() {
    _defaultTokenRanks = {
      for (final (index, address) in _defaultTokenAddresses().indexed) address.toLowerCase(): index,
    };

    int popularityRank(CryptoCurrency token) =>
        _defaultTokenRanks[getTokenAddressBasedOnWallet(token)!.toLowerCase()] ??
        _defaultTokenRanks.length;

    int byPopularity(CryptoCurrency a, CryptoCurrency b) {
      final byRank = popularityRank(a).compareTo(popularityRank(b));
      if (byRank != 0) {
        return byRank;
      }
      if (a.isPotentialScam != b.isPotentialScam) {
        return a.isPotentialScam ? 1 : -1;
      }
      return a.title.compareTo(b.title);
    }

    tokens.clear();
    tokens.addAll(_walletTokens()..sort(byPopularity));
  }

  @action
  Future<void> _loadTokenBalances() async {
    if (_balanceViewModel.wallet != _balancesWallet) {
      _balancesWallet = _balanceViewModel.wallet;
      _tokenBalances.clear();
    }
    final requestId = ++_balanceRequestId;
    final missing = tokens.where((token) => _balance(token) == null).toList();
    if (walletType == WalletType.solana && missing.isNotEmpty) {
      Map<CryptoCurrency, Balance>? held;
      try {
        held = await solana!.getHeldTokenBalances(_balanceViewModel.wallet);
      } catch (e) {
        printV("Error fetching held token balances: $e");
      }
      if (requestId != _balanceRequestId) {
        return;
      }
      for (final token in missing) {
        _storeIfMissing(token, held?[token]);
      }
      // No per-token fallback: it hits the same rate-limited RPC
      missing.clear();
    }
    isLoadingTokenBalances = missing.isNotEmpty;
    for (final batch in missing.slices(5)) {
      final balances = await Future.wait(batch.map(_fetchTokenBalance));
      if (requestId != _balanceRequestId) {
        return;
      }
      for (final (index, token) in batch.indexed) {
        _storeIfMissing(token, balances[index]);
      }
    }
    isLoadingTokenBalances = false;
  }

  void _storeIfMissing(CryptoCurrency token, Balance? balance) {
    if (balance != null && _balance(token) == null) {
      _tokenBalances[token] = balance;
    }
  }

  Future<Balance?> _fetchTokenBalance(CryptoCurrency token) async {
    try {
      return await _balanceViewModel.wallet.fetchTokenBalance(token);
    } catch (e) {
      printV("Error fetching ${token.title} balance: $e");
      return null;
    }
  }

  // FIXME these two observables cause duplicated state and are needed because mobx. remove them as part of the refactor and replace with proper getters
  @observable
  bool showCombinedBalance;

  @observable
  CryptoCurrency favoriteToken;

  @action
  void setShowCombinedBalance(bool value) {
    _balanceViewModel.wallet.walletInfo.showCombinedBalance = value;
    showCombinedBalance = value;
    _balanceViewModel.wallet.updateBalance();
    _balanceViewModel.wallet.walletInfo.save();
  }

  @action
  Future<void> setFavoriteToken(CryptoCurrency token) async {
    final String? address;

    if (token == _balanceViewModel.wallet.currency) {
      address = null;
    } else {
      address = getTokenAddressBasedOnWallet(token);
    }

    _balanceViewModel.wallet.walletInfo.favoriteTokenAddress = address;
    _balanceViewModel.wallet.walletInfo.save();
    _updateLocalFavoriteToken();
  }

  @action
  Future<void> _updateLocalFavoriteToken() async {
    favoriteToken = await TokenUtilities.findTokenByAddress(
            walletType: _balanceViewModel.wallet.type,
            address: _balanceViewModel.wallet.walletInfo.favoriteTokenAddress ?? "") ??
        _balanceViewModel.wallet.currency;
  }

  @action
  void _refreshTokensList() {
    final _tokens = Set.of(tokens);
    tokens.clear();
    tokens.addAll(_tokens);
  }

  bool matchesSearch(CryptoCurrency asset, String query) {
    final text = query.trim().toLowerCase();
    return text.isEmpty ||
        asset.fullName!.toLowerCase().contains(text) ||
        asset.title.toLowerCase().contains(text) ||
        getTokenAddressBasedOnWallet(asset)!.toLowerCase() == text;
  }

  String? getTokenAddressBasedOnWallet(CryptoCurrency asset) {
    if (_balanceViewModel.wallet.type == WalletType.tron) {
      return tron!.getTokenAddress(asset);
    }

    if (_balanceViewModel.wallet.type == WalletType.solana) {
      return solana!.getTokenAddress(asset);
    }

    if (isEVMCompatibleChain(_balanceViewModel.wallet.type)) {
      return evm!.getTokenAddress(asset);
    }

    if (_balanceViewModel.wallet.type == WalletType.zano) {
      return zano!.getZanoAssetAddress(asset);
    }

    // We return null if it's neither Tron, EVM or Solana wallet (which is actually impossible because we only display home settings for either of these four wallets).
    return null;
  }
}
