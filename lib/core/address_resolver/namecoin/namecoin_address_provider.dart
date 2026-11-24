import 'package:cake_wallet/core/address_resolver/address_lookup_provider.dart';
import 'package:cake_wallet/core/address_resolver/address_sources.dart';
import 'package:cake_wallet/core/address_resolver/namecoin/namecoin_electrumx_client.dart';
import 'package:cake_wallet/core/address_resolver/namecoin/namecoin_record.dart';
import 'package:cake_wallet/core/address_resolver/parsed_address.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';

class NamecoinAddressProvider extends AddressLookupProvider {
  NamecoinAddressProvider({NamecoinElectrumXClient? client})
      : client = client ?? NamecoinElectrumXClient();

  final NamecoinElectrumXClient client;

  @override
  AddressSource get source => AddressSource.namecoin;

  @override
  List<CryptoCurrency> get supportedCurrencies => CryptoCurrency.all;

  @override
  bool canHandle(String query) => NamecoinRecord.isNamecoinIdentifier(query);

  @override
  bool isEnabled(SettingsStore settingsStore) => settingsStore.lookupsNamecoin;

  @override
  Future<List<ParsedAddress>> resolve({
    required String query,
    required List<CryptoCurrency> currencies,
    required WalletBase wallet,
  }) async {
    final name = NamecoinRecord.normalizeIdentifier(query);
    if (name == null || currencies.isEmpty) return [];

    try {
      final lookup = await client.resolve(name);
      if (lookup == null) return [];

      final addresses = NamecoinRecord.parseAddresses(lookup.value, currencies: currencies);
      if (addresses.isEmpty) return [];

      return [
        ParsedAddress(
          parsedAddressByCurrencyMap: addresses,
          addressSource: AddressSource.namecoin,
          handle: name,
        ),
      ];
    } catch (error) {
      printV('[namecoin] Unable to resolve $name: $error');
      return [];
    }
  }
}
