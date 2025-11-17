import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/evm/evm.dart';
import 'package:cw_core/cake_hive.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:cw_core/erc20_token.dart';
import 'package:cw_core/spl_token.dart';
import 'package:cw_core/tron_token.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:hive/hive.dart';

class TokenUtilities {
  static Future<List<Erc20Token>> loadAllUniqueEvmTokens() async {
    final allWi = await WalletInfo.getAll();
    final evmWallets = allWi.where(
      (w) => isEVMCompatibleChain(w.type),
    );

    final seen = <String>{};
    final unique = <Erc20Token>[];

    for (final wallet in evmWallets) {
      final chain = getTokenNameBasedOnWalletType(wallet.type);
      final box = await _openEvmTokensBoxFor(wallet);

      for (final t in box.values.where((t) => t.enabled)) {
        final key = '$chain|${t.contractAddress.toLowerCase()}';
        if (seen.add(key)) {
          unique.add(t);
        }
      }
    }

    return unique;
  }

  static Future<List<SPLToken>> loadAllUniqueSolTokens() async {
    final allWi = await WalletInfo.getAll();
    final solWallets = allWi.where(
      (w) => w.type == WalletType.solana,
    );

    final tokens = <SPLToken>[];
    for (final wallet in solWallets) {
      final box = await _openSolTokensBoxFor(wallet);
      tokens.addAll(box.values.where((t) => t.enabled));
    }

    final seen = <String>{};
    final unique = <SPLToken>[];
    for (final token in tokens) {
      final key = token.mintAddress.toLowerCase();
      if (seen.add(key)) unique.add(token);
    }
    return unique;
  }

  static Future<List<TronToken>> loadAllUniqueTronTokens() async {
    final allWi = await WalletInfo.getAll();
    final tronWallets = allWi.where(
      (w) => w.type == WalletType.tron,
    );

    final seen = <String>{};
    final unique = <TronToken>[];
    for (final wallet in tronWallets) {
      final box = await _openTronTokensBoxFor(wallet);
      for (final t in box.values.where((t) => t.enabled)) {
        final key = t.contractAddress.toLowerCase();
        if (seen.add(key)) unique.add(t);
      }
    }
    return unique;
  }

  /// Finds a token by address across wallets depending on [walletType]
  /// - EVM chains: match by contractAddress
  /// - Solana: match by mintAddress
  /// - Tron: match by contractAddress
  static Future<CryptoCurrency?> findTokenByAddress({
    required WalletType walletType,
    required String address,
  }) async {
    final lower = address.toLowerCase();
    switch (walletType) {
      case WalletType.ethereum:
      case WalletType.polygon:
      case WalletType.base:
        final tokens = await loadAllUniqueEvmTokens();
        for (final t in tokens) {
          if (t.contractAddress.toLowerCase() == lower) return t;
        }
        return null;
      case WalletType.solana:
        final solTokens = await loadAllUniqueSolTokens();
        for (final t in solTokens) {
          if (t.mintAddress.toLowerCase() == lower) return t;
        }
        return null;
      case WalletType.tron:
        final tronTokens = await loadAllUniqueTronTokens();
        for (final t in tronTokens) {
          if (t.contractAddress.toLowerCase() == lower) return t;
        }
        return null;
      default:
        return null;
    }
  }

  static Future<Box<Erc20Token>> _openEvmTokensBoxFor(
    WalletInfo walletInfo,
  ) async {
    final walletKey = walletInfo.name.replaceAll(' ', '_');
    final boxName = switch (walletInfo.type) {
      WalletType.ethereum => '${walletKey}_${Erc20Token.ethereumBoxName}',
      WalletType.polygon => '${walletKey}_${Erc20Token.polygonBoxName}',
      WalletType.base => '${walletKey}_${Erc20Token.baseBoxName}',
      WalletType.arbitrum => '${walletKey}_${Erc20Token.arbitrumBoxName}',
      _ => '${walletKey}_${Erc20Token.ethereumBoxName}',
    };

    if (CakeHive.isBoxOpen(boxName)) {
      return CakeHive.box<Erc20Token>(boxName);
    }
    return CakeHive.openBox<Erc20Token>(boxName);
  }

  static Future<Box<SPLToken>> _openSolTokensBoxFor(WalletInfo wallet) async {
    final boxName = '${wallet.name.replaceAll(' ', '_')}_${SPLToken.boxName}';
    if (CakeHive.isBoxOpen(boxName)) {
      return CakeHive.box<SPLToken>(boxName);
    }
    return CakeHive.openBox<SPLToken>(boxName);
  }

  static Future<Box<TronToken>> _openTronTokensBoxFor(
    WalletInfo walletInfo,
  ) async {
    final boxName = '${walletInfo.name.replaceAll(' ', '_')}_${TronToken.boxName}';
    if (CakeHive.isBoxOpen(boxName)) {
      return CakeHive.box<TronToken>(boxName);
    }
    return CakeHive.openBox<TronToken>(boxName);
  }

  static Erc20Token? findErc20Token(CryptoCurrency currency, WalletBase wallet) {
    if (currency is Erc20Token) return currency;

    // More of a fallback for us
    for (final balanceCurrency in wallet.balance.keys) {
      if (balanceCurrency is Erc20Token && _matchesCurrency(balanceCurrency, currency)) {
        return balanceCurrency;
      }
    }

    return null;
  }

  static bool isNativeToken(CryptoCurrency currency) {
    final title = currency.title.toLowerCase();
    final tag = currency.tag?.toLowerCase();

    return title == 'eth' ||
        title == 'ethereum' ||
        title == 'matic' ||
        title == 'polygon' ||
        title == 'bnb' ||
        title == 'bsc' ||
        title == 'avax' ||
        title == 'avalanche' ||
        tag == 'polygon' ||
        tag == 'bsc' ||
        tag == 'avalanche';
  }

  static int getChainId(CryptoCurrency currency) {
    final tag = currency.tag?.toUpperCase();
    final title = currency.title.toLowerCase();
    
    // Only check EVM registry for currencies that might be EVM-related
    final isPotentialEVM = 
        title == 'eth' || title == 'ethereum' || title == 'polygon' || 
        title == 'matic' || title == 'base' || title == 'arbitrum' ||
        (tag != null && (tag == 'ETH' || tag == 'POL' || tag == 'BASE' || tag == 'ARB')) ||
        isNativeToken(currency);
    
    if (isPotentialEVM) {
      // Try by tag first if available (e.g., 'POL', 'BASE', 'ARB')
      if (tag != null) {
        final chainId = evm!.getChainIdByTag(tag);
        if (chainId != null) return chainId;
      }
      
      // Try by title (case-insensitive)
      final titleChainId = evm!.getChainIdByTitle(title);
      if (titleChainId != null) return titleChainId;
    }
    
    // Fallback to hardcoded values for chains not in registry yet
    // BSC (Binance Smart Chain)
    if (title == 'bsc' || title == 'bnb' || tag == 'BSC') {
      return 56;
    }
    
    // Avalanche C-Chain
    if (title == 'avalanche' || title == 'avax' || tag == 'AVALANCHE') {
      return 43114;
    }
    
    // Optimism
    if (title == 'optimism' || title == 'op' || tag == 'OPTIMISM') {
      return 10;
    }
    
    // Fantom Opera
    if (title == 'fantom' || title == 'ftm' || tag == 'FANTOM') {
      return 250;
    }
    
    // Default to Ethereum mainnet
    return 1;
  }

  static Future<List<CryptoCurrency>> getAvailableTokensForNetwork(
    WalletType network,
  ) async {
    final baseCurrency = walletTypeToCryptoCurrency(network);
    final allTokens = <CryptoCurrency>[];
    final addedAddresses = <String>{};

    allTokens.add(baseCurrency);

    for (final currency in CryptoCurrency.all) {
      // For EVM networks: ETH has no tag, POL/BASE have tags
      // Match by tag for POL/BASE, match by title==tag for ETH
      final matches = (baseCurrency.tag == null && baseCurrency.title == currency.tag) ||
          (baseCurrency.tag != null &&
              currency.tag?.toLowerCase() == baseCurrency.tag?.toLowerCase());

      if (matches && _shouldAddToken(allTokens, currency, addedAddresses)) {
        allTokens.add(currency);
      }
    }

    // Add user tokens that don't already exist
    final userTokens = await _getUserTokensForNetwork(baseCurrency);
    for (final token in userTokens) {
      if (_shouldAddToken(allTokens, token, addedAddresses)) {
        allTokens.add(token);
        if (token is Erc20Token) {
          addedAddresses.add(token.contractAddress.toLowerCase());
        }
      }
    }

    return allTokens;
  }

  static bool _shouldAddToken(
    List<CryptoCurrency> existingTokens,
    CryptoCurrency token,
    Set<String> addedAddresses,
  ) {
    if (token is Erc20Token) {
      final address = token.contractAddress.toLowerCase();
      if (addedAddresses.contains(address)) {
        return false;
      }
      if (existingTokens.any((existing) => _matchesCurrency(existing, token))) {
        return false;
      }
      return true;
    }

    return !existingTokens.any((existing) => _matchesCurrency(existing, token));
  }

  static bool _matchesCurrency(CryptoCurrency a, CryptoCurrency b) {
    return a.title.toUpperCase() == b.title.toUpperCase() &&
        (a.tag?.toUpperCase() == b.tag?.toUpperCase());
  }

  static Future<List<CryptoCurrency>> _getUserTokensForNetwork(CryptoCurrency baseCurrency) async {
    final tokens = await TokenUtilities.loadAllUniqueEvmTokens();

    return tokens.where((token) {
      // Match by tag, except for ETH which has no tag - match by title instead
      if (baseCurrency.tag == null) return token.tag == baseCurrency.title;

      return token.tag?.toLowerCase() == baseCurrency.tag?.toLowerCase();
    }).toList();
  }
}
