import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/erc20_token_resolver.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/solana_account_fetcher.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/solana_lookup_budget.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/spl_token_resolver.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/erc20_token.dart";
import "package:on_chain/solana/solana.dart";

class StubErc20Resolver extends Erc20TokenResolver {
  StubErc20Resolver(this.tokens, {Set<String>? known})
    : known = known ?? tokens.keys.toSet(),
      super(null);

  final Map<String, Erc20Token> tokens;
  final Set<String> known;

  @override
  bool isKnown(String contractAddress, {required int? chainId}) =>
      known.contains(contractAddress.toLowerCase());

  @override
  Future<Erc20Token?> resolve(String contractAddress) async =>
      tokens[contractAddress.toLowerCase()];
}

class StubSplResolver extends SplTokenResolver {
  StubSplResolver({this.byMint = const {}, Set<String>? known})
    : known = known ?? byMint.keys.toSet(),
      super(null, SolanaLookupBudget());

  final Map<String, CryptoCurrency> byMint;
  final Set<String> known;

  @override
  bool isKnown(String mintAddress) => known.contains(mintAddress);

  @override
  Future<CryptoCurrency?> resolve(String mintAddress) async => byMint[mintAddress];
}

class StubAccountFetcher extends SolanaAccountFetcher {
  StubAccountFetcher(this.accounts) : super(null, SolanaLookupBudget());

  final Map<String, List<int>> accounts;

  int fetchCalls = 0;

  @override
  Future<List<List<int>?>?> fetchAccountsData(List<String> addresses) async {
    fetchCalls += 1;
    return addresses.map<List<int>?>((a) => accounts[a]).toList();
  }
}

String ataFor(String owner, String mint) =>
    AssociatedTokenAccountProgramUtils.associatedTokenAccount(
      mint: SolAddress(mint),
      owner: SolAddress(owner),
    ).address.address;

String row(String label, String value) => "$label: $value";

List<String> rowLines(List<WCDecodedRow> rows) => [
  for (final shown in rows) row(shown.label, shown.value),
];

String? rowValue(List<WCDecodedRow> rows, String label) {
  final matches = rows.where((shown) => shown.label == label);
  return matches.isEmpty ? null : matches.single.value;
}
