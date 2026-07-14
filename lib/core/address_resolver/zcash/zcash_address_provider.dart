import 'package:cake_wallet/core/address_resolver/address_lookup_provider.dart';
import 'package:cake_wallet/core/address_resolver/address_sources.dart';
import 'package:cake_wallet/core/address_resolver/parsed_address.dart';
import 'package:cake_wallet/core/address_resolver/zcash/zcash_names_record.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';

class ZcashNameAddressProvider extends AddressLookupProvider {
  @override
  AddressSource get source => AddressSource.zcashName;

  @override
  List<CryptoCurrency> get supportedCurrencies => [CryptoCurrency.zec];

  @override
  bool isEnabled(SettingsStore settingsStore) => settingsStore.lookupsZcashNames;

  @override
  bool canHandle(String query) {
    final lowerText = query.toLowerCase();
    return lowerText.endsWith(".zec") || lowerText.endsWith(".zcash");
  } // Zcash handle example: name.zec

  @override
  Future<List<ParsedAddress>> resolve({
    required String query,
    required List<CryptoCurrency> currencies,
    required WalletBase wallet,
  }) async {
    try {
      final address = await ZcashNamesRecord.fetchZcashNamesAddress(query);
      if (address == null || address.isEmpty) return [];

      return [
        ParsedAddress(
          parsedAddressByCurrencyMap: {CryptoCurrency.zec: address},
          profileName: query,
          addressSource: AddressSource.zcashName,
          handle: query,
        ),
      ];
    } catch (e) {
      printV('[address resolver] Error resolving Zcash Name: $e');
      return [];
    }
  }
}
