import 'dart:convert';

import 'package:cake_wallet/core/address_resolver/address_lookup_provider.dart';
import 'package:cake_wallet/core/address_resolver/address_sources.dart';
import 'package:cake_wallet/core/address_resolver/parsed_address.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/wallet_base.dart';

class ZanoAliasAddressProvider extends AddressLookupProvider {
  @override
  AddressSource get source => AddressSource.zanoAlias;

  @override
  List<CryptoCurrency> get supportedCurrencies => [CryptoCurrency.zano];

  @override
  bool isEnabled(SettingsStore settingsStore) => settingsStore.lookupsZanoAlias;

  @override
  bool canHandle(String query) => query.startsWith('@'); // zano handle example: @username

  static const _zanoUrl = 'http://37.27.100.59:10500/json_rpc';
  @override
  Future<List<ParsedAddress>> resolve({
    required String query,
    required List<CryptoCurrency> currencies,
    required WalletBase wallet,
  }) async {
    try {
      if (!currencies.contains(CryptoCurrency.zano)) return [];

      final formattedName = query.replaceFirst("@", "");
      if (formattedName.isEmpty) return [];

      final zanoAddress = await fetchZanoAliasAddress(formattedName);
      if (zanoAddress == null || zanoAddress.isEmpty) return [];

      return [
        ParsedAddress(
          parsedAddressByCurrencyMap: {CryptoCurrency.zano: zanoAddress},
          addressSource: AddressSource.zanoAlias,
          handle: query,
        ),
      ];
    } catch (e) {
      printV('[address resolver] Error resolving Zano Alias: $e');
      return [];
    }
  }

  static Future<String?> fetchZanoAliasAddress(String alias) async {
    try {
      final uri = Uri.parse(_zanoUrl);
      final response = await ProxyWrapper().post(
        clearnetUri: uri,
        body: json.encode({
          'id': 0,
          'jsonrpc': '2.0',
          'method': 'get_alias_details',
          'params': {'alias': alias},
        }),
      );

      final jsonParsed = json.decode(response.body) as Map<String, dynamic>;
      return jsonParsed['result']?['alias_details']?['address'] as String?;
    } catch (e) {
      printV('[address resolver] Zano Alias error: $e');
      return null;
    }
  }
}
