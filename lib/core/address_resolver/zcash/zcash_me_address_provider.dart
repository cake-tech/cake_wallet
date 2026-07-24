import 'package:cake_wallet/core/address_resolver/address_lookup_provider.dart';
import 'package:cake_wallet/core/address_resolver/address_sources.dart';
import 'package:cake_wallet/core/address_resolver/parsed_address.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/wallet_base.dart';

class ZcashMeAddressProvider extends AddressLookupProvider {
  @override
  AddressSource get source => AddressSource.zcashAddress;

  @override
  List<CryptoCurrency> get supportedCurrencies => [CryptoCurrency.zec];

  @override
  bool isEnabled(SettingsStore settingsStore) => settingsStore.lookupsZcashAddress;

  @override
  bool canHandle(String query) {
    final value = query.trim().toLowerCase();
    return value.startsWith('zcash.me/') && value.split('/').last.isNotEmpty;
  } // zcash.me profile example: zcash.me/username

  @override
  Future<List<ParsedAddress>> resolve({
    required String query,
    required List<CryptoCurrency> currencies,
    required WalletBase wallet,
  }) async {
    try {
      final handle = query.trim().split('/').last;
      if (handle.isEmpty) return [];

      final address = await _fetchZcashAddress(handle);
      if (address == null || address.isEmpty) return [];

      return [
        ParsedAddress(
          parsedAddressByCurrencyMap: {CryptoCurrency.zec: address},
          profileName: handle,
          addressSource: AddressSource.zcashAddress,
          handle: query,
        ),
      ];
    } catch (e) {
      printV('[address resolver] Error resolving zcash.me address: $e');
      return [];
    }
  }

  Future<String?> _fetchZcashAddress(String handle) async {
    final url = Uri.parse('https://zcash.me/$handle');

    try {
      final response = await ProxyWrapper().get(clearnetUri: url);

      if (response.statusCode == 200) {
        final addressRegex = RegExp(
          r'(t1[0-9A-Za-z]{33}|t3[0-9A-Za-z]{33}|zs[a-z0-9]{76}|u1[a-z0-9]{1,300})',
          caseSensitive: true,
        );

        final match = addressRegex.firstMatch(response.body);
        return match?.group(0);
      }
    } catch (e) {
      printV('[address resolver] Error fetching zcash.me profile: $e');
    }

    return null;
  }
}
