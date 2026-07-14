import 'package:cake_wallet/core/address_resolver/address_lookup_provider.dart';
import 'package:cake_wallet/core/address_resolver/address_resolver_utils.dart';
import 'package:cake_wallet/core/address_resolver/address_sources.dart';
import 'package:cake_wallet/core/address_resolver/nostr/nostr_api.dart';
import 'package:cake_wallet/core/address_resolver/parsed_address.dart';
import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';

class NostrAddressProvider extends AddressLookupProvider {
  @override
  AddressSource get source => AddressSource.nostr;

  @override
  List<CryptoCurrency> get supportedCurrencies => AddressValidator.reliableValidateCurrencies;

  @override
  bool canHandle(String q) =>
      AddressResolverUtils.isEmailFormat(q); // Nostr handle example: username@domain

  @override
  bool isEnabled(SettingsStore settingsStore) => settingsStore.lookupsNostr;

  @override
  Future<List<ParsedAddress>> resolve({
    required String query,
    required List<CryptoCurrency> currencies,
    required WalletBase wallet,
  }) async {
    try {
      final profile = await NostrProfileHandler.queryProfile(query);
      if (profile == null) return [];

      final data = await NostrProfileHandler.processRelays(profile, query);
      if (data == null) return [];

      final result = <CryptoCurrency, String>{};

      String queryTxt = data.about;

      for (final cur in currencies) {
        final addr = AddressResolverUtils.extractAddressByType(raw: queryTxt, type: cur);
        if (addr != null && addr.isNotEmpty) {
          result[cur] = addr;
          queryTxt = queryTxt.replaceFirst(addr, '');
        }
      }
      if (result.isEmpty) return [];

      return [
        ParsedAddress(
          parsedAddressByCurrencyMap: result,
          addressSource: AddressSource.nostr,
          handle: query,
          profileImageUrl: data.picture,
          profileName: data.name,
        )
      ];
    } catch (e) {
      printV('Error looking up Nostr profile: $e');
      return [];
    }
  }
}
