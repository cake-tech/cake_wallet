import "package:cake_wallet/solana/solana.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/solana_lookup_budget.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cw_core/utils/print_verbose.dart";

class SolanaAccountFetcher {
  SolanaAccountFetcher(this.appStore, this.budget);

  final AppStore? appStore;
  final SolanaLookupBudget budget;
  final _fetched = <String, Future<List<List<int>?>?>>{};

  Future<List<List<int>?>?> fetchAccountsData(List<String> addresses) =>
      _fetched.putIfAbsent(addresses.join(","), () => _requestAccountsData(addresses));

  Future<List<List<int>?>?> _requestAccountsData(List<String> addresses) async {
    if (addresses.isEmpty) {
      return const [];
    }

    final wallet = appStore?.wallet;
    if (wallet == null || solana == null) {
      return null;
    }

    try {
      return await budget.run(
        () => solana!.getAccountsData(wallet, addresses),
        timeout: const Duration(seconds: 5),
      );
    } catch (e) {
      printV("SolanaAccountFetcher: account fetch failed: $e");
      return null;
    }
  }
}
