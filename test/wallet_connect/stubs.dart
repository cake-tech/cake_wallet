import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/erc20_token_resolver.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/solana_account_fetcher.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/spl_token_resolver.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/erc20_token.dart";

/// Resolves the contracts it was seeded with and nothing else, so a decoder's
/// unknown-token path stays reachable.
class StubErc20Resolver extends Erc20TokenResolver {
  StubErc20Resolver(this.tokens) : super(null);

  final Map<String, Erc20Token> tokens;

  @override
  Future<Erc20Token?> resolve(String contractAddress) async =>
      tokens[contractAddress.toLowerCase()];

  @override
  String? fiatFor(CryptoCurrency currency, String cryptoAmount) => null;
}

class StubSplResolver extends SplTokenResolver {
  StubSplResolver({
    this.byMint = const {},
    this.balances = const {},
  }) : super(null);

  final Map<String, CryptoCurrency> byMint;
  final Map<String, BigInt> balances;

  @override
  Future<CryptoCurrency?> resolve(String mintAddress) async => byMint[mintAddress];

  @override
  Map<String, CryptoCurrency> trackedAndDefaultTokensByMint() => byMint;

  @override
  Iterable<CryptoCurrency> walletKnownTokens() => byMint.values;

  @override
  String? mintAddressOf(CryptoCurrency token) {
    for (final entry in byMint.entries) {
      if (entry.value.title == token.title) {
        return entry.key;
      }
    }
    return null;
  }

  @override
  BigInt balanceFor(CryptoCurrency? token) =>
      token == null ? BigInt.zero : (balances[token.title] ?? BigInt.zero);
}

class StubAccountFetcher extends SolanaAccountFetcher {
  StubAccountFetcher(this.accounts) : super(null);

  /// Address to raw account data. A missing address resolves to null, the
  /// same shape getMultipleAccounts returns for an account that does not exist.
  final Map<String, List<int>> accounts;

  int fetchCalls = 0;

  @override
  Future<List<List<int>?>?> fetchAccountsData(List<String> addresses) async {
    fetchCalls += 1;
    return addresses.map<List<int>?>((a) => accounts[a]).toList();
  }
}
