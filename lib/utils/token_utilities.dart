import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cw_core/cake_hive.dart';
import 'package:cw_core/crypto_currency.dart';
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
      if (balanceCurrency is Erc20Token && _matchesToken(balanceCurrency, currency)) {
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
    final title = currency.title.toLowerCase();
    final tag = currency.tag?.toLowerCase();

    // Polygon
    if (title == 'polygon' || title == 'matic' || tag == 'polygon') {
      return 137;
    }

    // BSC (Binance Smart Chain)
    if (title == 'bsc' || title == 'bnb' || tag == 'bsc') {
      return 56;
    }

    // Avalanche C-Chain
    if (title == 'avalanche' || title == 'avax' || tag == 'avalanche') {
      return 43114;
    }

    // Arbitrum One
    if (title == 'arbitrum' || title == 'arb' || tag == 'arb') {
      return 42161;
    }

    // Optimism
    if (title == 'optimism' || title == 'op' || tag == 'optimism') {
      return 10;
    }

    // Base
    if (title == 'base' || tag == 'base') {
      return 8453;
    }

    // Fantom Opera
    if (title == 'fantom' || title == 'ftm' || tag == 'fantom') {
      return 250;
    }

    // Default to Ethereum mainnet
    return 1;
  }

  /// Checks if two currencies match (by title and tag)
  static bool _matchesToken(Erc20Token token, CryptoCurrency currency) {
    return token.title.toLowerCase() == currency.title.toLowerCase() &&
        (token.tag?.toLowerCase() == currency.tag?.toLowerCase() ||
            (token.tag == null && currency.tag == null));
  }
}
