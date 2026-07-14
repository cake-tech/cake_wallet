import 'package:cake_wallet/core/address_resolver/address_lookup_provider.dart';
import 'package:cake_wallet/core/address_resolver/address_sources.dart';
import 'package:cake_wallet/core/address_resolver/bip_353/bip_353_address_provider.dart';
import 'package:cake_wallet/core/address_resolver/ens/ens_address_provider.dart';
import 'package:cake_wallet/core/address_resolver/fio/fio_address_provider.dart';
import 'package:cake_wallet/core/address_resolver/lnurl_pay/lnurl_pay_address_provider.dart';
import 'package:cake_wallet/core/address_resolver/mastodon/mastodon_address_provider.dart';
import 'package:cake_wallet/core/address_resolver/nostr/nostr_address_provider.dart';
import 'package:cake_wallet/core/address_resolver/openalias/openalias_address_provider.dart';
import 'package:cake_wallet/core/address_resolver/parsed_address.dart';
import 'package:cake_wallet/core/address_resolver/thorchain/thorchain_address_provider.dart';
import 'package:cake_wallet/core/address_resolver/twitter/twitter_address_provider.dart';
import 'package:cake_wallet/core/address_resolver/unstoppable/unstoppable_address_provider.dart';
import 'package:cake_wallet/core/address_resolver/wellknown/wellknown_address_provider.dart';
import 'package:cake_wallet/core/address_resolver/yat/yat_address_provider.dart';
import 'package:cake_wallet/core/address_resolver/zano/zano_alias_address_provider.dart';
import 'package:cake_wallet/core/address_resolver/zcash/zcash_address_provider.dart';
import 'package:cake_wallet/core/address_resolver/zcash/zcash_me_address_provider.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';

class AddressResolverService {
  AddressResolverService({required this.settingsStore});

  final SettingsStore settingsStore;

// Sources available for address resolution and lookup settings.
  static const supportedSources = [
    AddressSource.lnurlPay,
    AddressSource.twitter,
    AddressSource.mastodon,
    AddressSource.yatRecord,
    AddressSource.unstoppableDomains,
    AddressSource.openAlias,
    AddressSource.ens,
    AddressSource.zcashName,
    AddressSource.zcashAddress,
    AddressSource.wellKnown,
    AddressSource.zanoAlias,
    AddressSource.bip353,
    AddressSource.fio,
    AddressSource.thorChain,
    AddressSource.nostr,
  ];

  List<AddressLookupProvider> _buildProviders() {
    final allProviders = <AddressLookupProvider>[
      LNUrlPayAddressProvider(),
      TwitterAddressProvider(),
      MastodonAddressProvider(),
      YatAddressProvider(),
      UnstoppableAddressProvider(),
      OpenaliasAddressProvider(),
      EnsAddressProvider(),
      ZcashNameAddressProvider(),
      ZcashMeAddressProvider(),
      WellKnownAddressProvider(),
      ZanoAliasAddressProvider(),
      Bip353AddressProvider(),
      FioAddressProvider(),
      ThorchainAddressProvider(),
      NostrAddressProvider(),
    ];

    return allProviders.where((provider) => supportedSources.contains(provider.source)).toList();
  }

  Future<List<ParsedAddress>> resolve({
    required String query,
    required WalletBase wallet,
    required CryptoCurrency currency,
  }) async {
    try {
      final providers = _buildProviders();
      // return first entry if currency is specified and provider supports it
      if (currency != null) {
        for (final provider in providers) {
          final cur = currency.title;
          final src = provider.source.label;

          printV('[address resolver service] checking $src - $cur - $query');
          if (!provider.isEnabled(settingsStore)) {
            printV('[address resolver service] ...skipping $src (disabled)');
            continue;
          }
          if (!provider.canHandle(query)) {
            printV('[address resolver service] ...skipping $src (cannot handle)');
            continue;
          }
          if (!provider.supportedCurrencies.contains(currency)) {
            printV('[address resolver service] ...skipping $src (unsupported currency)');
            continue;
          }

          try {
            printV('[address resolver service] ...resolving $src - $cur - $query');
            final results = await provider.resolve(
              query: query,
              currencies: [currency],
              wallet: wallet,
            );

            if (results.isNotEmpty) {
              final parsedAddress = results.first.parsedAddressByCurrencyMap[currency];
              final parsedAddressStr =
                  parsedAddress == null || parsedAddress.isEmpty ? 'N/A' : parsedAddress;
              printV('[address resolver service] resolved $src - $cur - $parsedAddressStr');
              return [results.first];
            }
          } catch (e) {
            printV('[address resolver service] Error resolving $src: $e');
          }
        }

        return [];
      }

      return []; // TODO: Implement multi-currency resolution if no specific currency is provided.

      final tasks = <Future<List<ParsedAddress>>>[];

      for (final provider in providers) {
        if (!provider.isEnabled(settingsStore)) continue;
        if (!provider.canHandle(query)) continue;

        tasks.add(
          provider.resolve(
            query: query,
            currencies: provider.supportedCurrencies,
            wallet: wallet,
          ),
        );
      }

      final results = await Future.wait(tasks);
      return results.expand((items) => items).toList();
    } catch (e) {
      printV('Error resolving address: $e');
      return [];
    }
  }
}
