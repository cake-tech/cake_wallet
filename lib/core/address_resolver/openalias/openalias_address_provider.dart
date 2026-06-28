import 'package:cake_wallet/core/address_resolver/address_lookup_provider.dart';
import 'package:cake_wallet/core/address_resolver/address_sources.dart';
import 'package:cake_wallet/core/address_resolver/openalias/openalias_record.dart';
import 'package:cake_wallet/core/address_resolver/parsed_address.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';

class OpenaliasAddressProvider extends AddressLookupProvider {
  @override
  AddressSource get source => AddressSource.openAlias;

  @override
  List<CryptoCurrency> get supportedCurrencies => [CryptoCurrency.xmr, CryptoCurrency.btc];

  @override
  bool canHandle(String q) {
    final formattedName = OpenaliasRecord.formatDomainName(q);
    return formattedName.contains(".");
  }

  @override
  bool isEnabled(SettingsStore settingsStore) => settingsStore.lookupsOpenAlias;

  @override
  Future<List<ParsedAddress>> resolve({
    required String query,
    required List<CryptoCurrency> currencies,
    required WalletBase wallet,
  }) async {
    try {
      final formatted = OpenaliasRecord.formatDomainName(query);

      final txtRecords = await OpenaliasRecord.lookupOpenAliasRecord(formatted);
      if (txtRecords == null) return [];

      final result = <CryptoCurrency, String>{};

      for (final cur in currencies) {
        final rec = OpenaliasRecord.fetchAddressAndName(
          formattedName: formatted,
          ticker: cur.title.toLowerCase(),
          txtRecord: txtRecords,
        );

        if (rec.address.isNotEmpty) result[cur] = rec.address;
      }

      if (result.isEmpty) return [];

      return [
        ParsedAddress(
          parsedAddressByCurrencyMap: result,
          addressSource: AddressSource.openAlias,
          handle: query,
        )
      ];
    } catch (e) {
      printV('[address resolver] Error resolving OpenAlias address: $e');
      return [];
    }
  }
}
