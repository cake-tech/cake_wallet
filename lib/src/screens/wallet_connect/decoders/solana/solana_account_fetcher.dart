import "package:cake_wallet/solana/solana.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cw_core/utils/print_verbose.dart";

class SolanaAccountFetcher {
  SolanaAccountFetcher(this.appStore);

  final AppStore? appStore;

  Future<List<List<int>?>?> fetchAccountsData(List<String> addresses) async {
    if (addresses.isEmpty) {
      return const [];
    }

    final wallet = appStore?.wallet;
    if (wallet == null || solana == null) {
      return null;
    }

    try {
      return await solana!
          .getAccountsData(wallet, addresses)
          .timeout(const Duration(seconds: 5), onTimeout: () => null);
    } catch (e) {
      printV("SolanaAccountFetcher: account fetch failed: $e");
      return null;
    }
  }

  Future<List<int>?> fetchAccountData(String address) async {
    final result = await fetchAccountsData([address]);
    if (result == null || result.isEmpty) {
      return null;
    }
    return result.first;
  }
}
