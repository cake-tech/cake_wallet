import 'package:cake_wallet/core/address_resolver/address_lookup_provider.dart';
import 'package:cake_wallet/core/address_resolver/address_resolver_utils.dart';
import 'package:cake_wallet/core/address_resolver/address_sources.dart';
import 'package:cake_wallet/core/address_resolver/parsed_address.dart';
import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/exchange/provider/thorchain_exchange.provider.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';

class ThorchainAddressProvider extends AddressLookupProvider {
  @override
  AddressSource get source => AddressSource.thorChain;

  @override
  List<CryptoCurrency> get supportedCurrencies => AddressValidator.reliableValidateCurrencies;

  @override
  bool canHandle(String q) => q.isNotEmpty; // can be any string

  @override
  bool isEnabled(SettingsStore settingsStore) => settingsStore.lookupsThorChain;

  @override
  Future<List<ParsedAddress>> resolve({
    required String query,
    required List<CryptoCurrency> currencies,
    required WalletBase wallet,
  }) async {
    try {
      final isNormalAddress = currencies.any((cur) =>
          AddressResolverUtils.extractAddressByType(raw: query, type: cur)?.isNotEmpty ?? false);
      if (query.length > 30 || isNormalAddress) return [];

      final map = await ThorChainExchangeProvider.lookupAddressByName(query);
      if (map == null || map.isEmpty) return [];

      final result = <CryptoCurrency, String>{};

      for (final cur in currencies) {
        final key = cur.title.toUpperCase();
        final addr = map[key];
        final runeAddr = cur.title.toUpperCase() == 'RUNE' ? map['THOR'] : null;
        final resolvedAddress = addr ?? runeAddr;
        if (resolvedAddress != null && resolvedAddress.isNotEmpty) {
          if (!result.containsValue(resolvedAddress)) result[cur] = resolvedAddress;
        }
      }

      if (result.isEmpty) return [];

      return [
        ParsedAddress(
          parsedAddressByCurrencyMap: result,
          addressSource: AddressSource.thorChain,
          handle: query,
        )
      ];
    } catch (e) {
      printV('[address resolver] Error resolving address: $e');
      return [];
    }
  }
}
