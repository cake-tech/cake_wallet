import "dart:convert";

import "package:cake_wallet/core/erc20_token_checks.dart";
import "package:cake_wallet/entities/preferences_key.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cw_core/erc20_token.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/utils/proxy_wrapper.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/foundation.dart";
import "package:shared_preferences/shared_preferences.dart";

class PopularEvmToken {
  const PopularEvmToken({
    required this.name,
    required this.symbol,
    required this.contractAddress,
    required this.decimals,
    this.logoUrl,
  });

  static PopularEvmToken? tryFromCoinGeckoJson(Map<String, dynamic> json) {
    final address = json["address"];
    final symbol = json["symbol"];
    final decimals = json["decimals"];
    if (address is! String || symbol is! String || decimals is! int) {
      return null;
    }

    return PopularEvmToken(
      name: json["name"] as String? ?? symbol,
      symbol: symbol,
      contractAddress: address,
      decimals: decimals,
      logoUrl: (json["logoURI"] as String?)?.replaceFirst("/thumb/", "/large/"),
    );
  }

  final String name;
  final String symbol;
  final String contractAddress;
  final int decimals;
  final String? logoUrl;
}

class PopularEvmTokens {
  static const _maxTokens = 4;

  static const _popularSymbols = ["USDC", "USDT", "USDT0", "DAI", "WETH", "WBTC"];

  static const _tetherSymbols = {"USDT", "USDT0"};

  static final _attemptedWalletIds = <String>{};

  static Future<void> addToWallet(WalletBase wallet, SharedPreferences prefs) async {
    final chainId = evm!.getSelectedChainId(wallet);
    if (wallet.type != WalletType.evm || chainId == null) {
      return;
    }

    final addedKey = PreferencesKey.popularEvmTokensAddedKey(wallet.walletInfo.id);
    if (prefs.getBool(addedKey) == true || !_attemptedWalletIds.add(wallet.walletInfo.id)) {
      return;
    }

    final chainTokens = await _fetchCoinGeckoTokens(chainId);
    if (chainTokens == null) {
      return;
    }

    final walletContracts =
        evm!.getERC20Currencies(wallet).map((token) => token.contractAddress.toLowerCase()).toSet();

    bool hasFailures = false;
    for (final token in pick(chainTokens, wallet.currency.title)) {
      if (walletContracts.contains(token.contractAddress.toLowerCase())) {
        continue;
      }

      try {
        await _addToken(wallet, chainId, token);
      } catch (e) {
        printV("Adding popular token ${token.symbol} on chain $chainId failed: $e");
        hasFailures = true;
      }
    }

    // Without the flag, the tokens that failed are tried again the next time the app starts
    if (!hasFailures) {
      await prefs.setBool(addedKey, true);
    }
  }

  static List<PopularEvmToken> pick(List<PopularEvmToken> chainTokens, String nativeSymbol) {
    final picked = <PopularEvmToken>[];

    for (final symbol in {"W${nativeSymbol.toUpperCase()}", ..._popularSymbols}) {
      if (picked.length == _maxTokens) {
        break;
      }

      if (_isTether(symbol) && picked.any((token) => _isTether(token.symbol))) {
        continue;
      }

      final token = _onlyTokenWithSymbol(chainTokens, symbol);
      if (token != null) {
        picked.add(token);
      }
    }

    return picked;
  }

  static bool _isTether(String symbol) => _tetherSymbols.contains(symbol.toUpperCase());

  // It's possible that a symbol listed more than once is bridged or a fake copy, so we don't use any of them
  static PopularEvmToken? _onlyTokenWithSymbol(List<PopularEvmToken> tokens, String symbol) {
    final matches = tokens.where((token) => token.symbol.toUpperCase() == symbol);
    return matches.length == 1 ? matches.single : null;
  }

  static Future<void> _addToken(WalletBase wallet, int chainId, PopularEvmToken token) async {
    final onChain = await evm!.getErc20Token(wallet, token.contractAddress);
    if (onChain == null) {
      throw Exception("${token.symbol} could not be read from the chain");
    }

    if (onChain.decimal != token.decimals) {
      printV("Popular token ${token.symbol} does not match chain $chainId, skipping it");
      return;
    }

    final checks = [
      await Erc20TokenChecks.moralisScamCheck(token.contractAddress, chainId),
      await Erc20TokenChecks.contractVerificationCheck(token.contractAddress, chainId),
    ];
    if (checks.contains(TokenCheckResult.risky)) {
      return;
    }

    await evm!.addErc20Token(
      wallet,
      Erc20Token(
        name: onChain.name.isNotEmpty ? onChain.name : token.name,
        symbol: token.symbol,
        contractAddress: token.contractAddress.toLowerCase(),
        decimal: token.decimals,
        iconPath: token.logoUrl,
        enabled:
            checks.contains(TokenCheckResult.safe) && !checks.contains(TokenCheckResult.failed),
      ),
    );
  }

  static Future<List<PopularEvmToken>?> _fetchCoinGeckoTokens(int chainId) async {
    try {
      final platformId = await _fetchCoinGeckoPlatformId(chainId);
      if (platformId == null) {
        return [];
      }

      final tokenList = await _getJson(Uri.https("tokens.coingecko.com", "/$platformId/all.json"));
      final tokens = (tokenList as Map<String, dynamic>)["tokens"] as List;

      return tokens
          .whereType<Map<String, dynamic>>()
          .where((json) => json["chainId"] == chainId)
          .map(PopularEvmToken.tryFromCoinGeckoJson)
          .whereType<PopularEvmToken>()
          .toList();
    } catch (e) {
      printV("Fetching CoinGecko tokens for chain $chainId failed: $e");
      return null;
    }
  }

  static Future<String?> _fetchCoinGeckoPlatformId(int chainId) async {
    final platforms =
        await _getJson(Uri.https("api.coingecko.com", "/api/v3/asset_platforms")) as List;

    final platform = platforms
        .whereType<Map<String, dynamic>>()
        .where((platform) => platform["chain_identifier"] == chainId)
        .firstOrNull;

    return platform?["id"] as String?;
  }

  static Future<Object> _getJson(Uri uri) async {
    final response =
        await ProxyWrapper().get(clearnetUri: uri).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception("${uri.host} answered ${response.statusCode}");
    }

    return await compute(jsonDecode, response.body) as Object;
  }
}
