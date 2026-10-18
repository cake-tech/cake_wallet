import 'package:cake_wallet/core/address_resolver/address_lookup_provider.dart';
import 'package:cake_wallet/core/address_resolver/address_sources.dart';
import 'package:cake_wallet/core/address_resolver/parsed_address.dart';
import 'package:cake_wallet/core/address_resolver/yat/yat_service.dart';
import 'package:cake_wallet/entities/emoji_string_extension.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';

class YatAddressProvider extends AddressLookupProvider {
  @override
  AddressSource get source => AddressSource.yatRecord;

  @override
  List<CryptoCurrency> get supportedCurrencies =>
      [CryptoCurrency.xmr, CryptoCurrency.btc, CryptoCurrency.eth, CryptoCurrency.ltc];

  @override
  bool canHandle(String q) => q.hasOnlyEmojis; // Yat handle example: 🐶🐾

  @override
  bool isEnabled(SettingsStore settingsStore) => settingsStore.lookupsYatService;

  @override
  Future<List<ParsedAddress>> resolve({
    required String query,
    required List<CryptoCurrency> currencies,
    required WalletBase wallet,
  }) async {
    try {
      final result = <CryptoCurrency, String>{};

      for (final cur in currencies) {
        final records = await YatService.fetchYatAddress(query, cur.title);
        if (records.isEmpty) continue;

        final chosen = cur == CryptoCurrency.xmr
            ? records.firstWhere((r) => r.isMoneroSub, orElse: () => records.first)
            : records.first;

        result[cur] = chosen.address;
      }

      if (result.isEmpty) return [];

      return [
        ParsedAddress(
          parsedAddressByCurrencyMap: result,
          addressSource: AddressSource.yatRecord,
          handle: query,
        )
      ];
    } catch (e) {
      printV('[address resolver] Error resolving Yat address: $e');
      return [];
    }
  }
}
