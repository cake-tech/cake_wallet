import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/solana_account_fetcher.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:on_chain/solana/solana.dart";

class AltLookup {
  AltLookup(this.fetcher);

  final SolanaAccountFetcher fetcher;

  Future<List<String>> resolveAccountKeys(SolanaTransaction transaction) async {
    final message = transaction.message;
    final statics = message.accountKeys.map((a) => a.address).toList();
    if (message is! MessageV0 || message.addressTableLookups.isEmpty) {
      return statics;
    }

    try {
      final lookups = message.addressTableLookups;
      final tableData =
          await fetcher.fetchAccountsData(lookups.map((l) => l.accountKey.address).toList());
      if (tableData == null || tableData.length != lookups.length) {
        return statics;
      }

      final tables = <AddressLookupTableAccount>[];
      for (var i = 0; i < lookups.length; i++) {
        final data = tableData[i];
        if (data == null) {
          return statics;
        }
        tables.add(
          AddressLookupTableAccount.fromBuffer(
            accountKey: lookups[i].accountKey,
            accountData: data,
          ),
        );
      }
      return combinedKeys(message, tables) ?? statics;
    } catch (e) {
      printV("AltLookup: lookup table resolution failed: $e");
      return statics;
    }
  }

  static List<String>? combinedKeys(
    MessageV0 message,
    List<AddressLookupTableAccount> tables,
  ) {
    try {
      final keys = message.getAccounts(addressLookupTableAccounts: tables);
      return [for (var i = 0; i < keys.length; i++) keys.byIndex(i)!.address];
    } catch (e) {
      printV("AltLookup: combining account keys failed: $e");
      return null;
    }
  }
}
