import 'package:cake_wallet/core/address_resolver/address_lookup_provider.dart';
import 'package:cake_wallet/core/address_resolver/address_sources.dart';
import 'package:cake_wallet/core/address_resolver/parsed_address.dart';
import 'package:cake_wallet/core/address_resolver/wellknown/wellknown_record.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';

class WellKnownAddressProvider extends AddressLookupProvider {
  @override
  AddressSource get source => AddressSource.wellKnown;

  @override
  List<CryptoCurrency> get supportedCurrencies => [CryptoCurrency.nano];

  @override
  bool canHandle(String q) => q.contains('.') && q.contains('@');

  // .well-known handle example:

  @override
  bool isEnabled(SettingsStore settingsStore) => settingsStore.lookupsWellKnown;

  @override
  Future<List<ParsedAddress>> resolve({
    required String query,
    required List<CryptoCurrency> currencies,
    required WalletBase wallet,
  }) async {
    try {
      final rec = await WellKnownRecord.fetch(query, CryptoCurrency.nano);
      if (rec == null || rec.address.isEmpty) return [];

      return [
        ParsedAddress(
          parsedAddressByCurrencyMap: {CryptoCurrency.nano: rec.address},
          addressSource: AddressSource.wellKnown,
          handle: query,
          profileName: rec.title ?? '',
          profileImageUrl: rec.imageUrl ?? '',
        )
      ];
    } catch (e) {
      printV('[address resolver] Error resolving Well-Known address: $e');
      return [];
    }
  }
}
