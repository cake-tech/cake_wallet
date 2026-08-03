import 'package:cake_wallet/core/address_resolver/address_lookup_provider.dart';
import 'package:cake_wallet/core/address_resolver/address_sources.dart';
import 'package:cake_wallet/core/address_resolver/bip_353/bip_353_record.dart';
import 'package:cake_wallet/core/address_resolver/parsed_address.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';

class Bip353AddressProvider extends AddressLookupProvider {
  @override
  AddressSource get source => AddressSource.bip353;

  @override
  List<CryptoCurrency> get supportedCurrencies => [CryptoCurrency.btc];

  @override
  bool isEnabled(SettingsStore settingsStore) => settingsStore.lookupsBip353;

  @override
  bool canHandle(String query) {
    final value = query.trim();
    return value.contains('@') && value.contains('.') && !value.startsWith('@');
  }

  @override
  Future<List<ParsedAddress>> resolve({
    required String query,
    required List<CryptoCurrency> currencies,
    required WalletBase wallet,
  }) async {
    try {
      final result = <CryptoCurrency, String>{};
      String? dnsProof;

      for (final cur in currencies) {
        final bip353AddressMap = await Bip353Record.fetchUriByCryptoCurrency(query, cur.title);
        if (bip353AddressMap == null || bip353AddressMap.isEmpty) continue;

        final spAddress = bip353AddressMap['sp'];
        final address = bip353AddressMap['address'];
        final chosenAddress = spAddress?.isNotEmpty == true ? spAddress : address;

        if (chosenAddress != null && chosenAddress.isNotEmpty) {
          result[cur] = chosenAddress;
        }
      }

      if (result.isEmpty) return [];

      try {
        dnsProof = await Bip353Record.fetchDnsProof(query);
      } catch (e) {
        printV('Bip353Record.fetchDnsProof error: $e');
      }

      return [
        ParsedAddress(
          parsedAddressByCurrencyMap: result,
          addressSource: AddressSource.bip353,
          handle: query,
          bip353DnsProof: dnsProof ?? '',
        )
      ];
    } catch (e) {
      printV('[address resolver] Error resolving BIP353 address: $e');
      return [];
    }
  }
}
