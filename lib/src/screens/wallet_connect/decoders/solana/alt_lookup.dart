import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/solana_account_fetcher.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:on_chain/solana/solana.dart";

class AltLookup {
  AltLookup(this.fetcher);

  final SolanaAccountFetcher fetcher;

  static const _maxTableBytes = 56 + 256 * 32;

  Future<List<String>> resolveAccountKeys(SolanaTransaction transaction) async {
    final message = transaction.message;
    final statics = message.accountKeys.map((key) => key.address).toList();
    if (message is! MessageV0 || message.addressTableLookups.isEmpty) {
      return statics;
    }

    try {
      final lookups = message.addressTableLookups;
      final tableData = await fetcher.fetchAccountsData(
        lookups.map((lookup) => lookup.accountKey.address).toList(),
      );
      if (tableData == null || tableData.length != lookups.length) {
        return statics;
      }

      final tables = <AddressLookupTableAccount>[];
      for (final (index, lookup) in lookups.indexed) {
        final data = tableData[index];
        if (data == null || data.length > _maxTableBytes) {
          return statics;
        }
        tables.add(
          AddressLookupTableAccount.fromBuffer(accountKey: lookup.accountKey, accountData: data),
        );
      }

      final keys = message.getAccounts(addressLookupTableAccounts: tables);
      return [for (var index = 0; index < keys.length; index++) keys.byIndex(index)!.address];
    } catch (e) {
      printV("AltLookup: lookup table resolution failed: $e");
      return statics;
    }
  }
}
