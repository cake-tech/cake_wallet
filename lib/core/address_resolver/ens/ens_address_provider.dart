import 'package:cake_wallet/core/address_resolver/address_lookup_provider.dart';
import 'package:cake_wallet/core/address_resolver/address_sources.dart';
import 'package:cake_wallet/core/address_resolver/ens/ens_record.dart';
import 'package:cake_wallet/core/address_resolver/parsed_address.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_base.dart';

class EnsAddressProvider extends AddressLookupProvider {
  @override
  AddressSource get source => AddressSource.ens;

  @override
  List<CryptoCurrency> get supportedCurrencies => [CryptoCurrency.eth];

  @override
  bool isEnabled(SettingsStore settingsStore) => settingsStore.lookupsENS;

  @override
  bool canHandle(String query) => query.endsWith('.eth'); // ENS handle example: name.eth

  @override
  Future<List<ParsedAddress>> resolve({
    required String query,
    required List<CryptoCurrency> currencies,
    required WalletBase wallet,
  }) async {
    final Map<CryptoCurrency, String> result = {};

    for (final cur in currencies) {
      final address = await EnsRecord.fetchEnsAddress(query, cur, wallet: wallet);
      if (address.isNotEmpty && address != "0x0000000000000000000000000000000000000000") {
        result[cur] = address;
      }
    }

    if (result.isNotEmpty) {
      return [
        ParsedAddress(
          parsedAddressByCurrencyMap: result,
          addressSource: AddressSource.ens,
          handle: query,
        )
      ];
    }
    return [];
  }
}
