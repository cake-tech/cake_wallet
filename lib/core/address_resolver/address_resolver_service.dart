import 'package:cake_wallet/core/address_resolver/address_lookup_provider.dart';
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
  AddressResolverService({
    required this.settingsStore,
  }) : providers = [
          TwitterAddressProvider(),
          MastodonAddressProvider(),
          UnstoppableAddressProvider(),
          ZcashMeAddressProvider(),
          ZcashNameAddressProvider(),
          ZanoAliasAddressProvider(),
          Bip353AddressProvider(),
          EnsAddressProvider(),
          FioAddressProvider(),
          NostrAddressProvider(),
          OpenaliasAddressProvider(),
          WellKnownAddressProvider(),
          YatAddressProvider(),
          ThorchainAddressProvider(),
          LNUrlPayAddressProvider(),
        ];

  final SettingsStore settingsStore;
  final List<AddressLookupProvider> providers;

  Future<List<ParsedAddress>> resolve({
    required String query,
    required WalletBase wallet,
    CryptoCurrency? currency,
  }) async {
    try {
      final tasks = <Future<List<ParsedAddress>>>[];

      for (final provider in providers) {
        if (!provider.isEnabled(settingsStore)) continue;
        if (!provider.canHandle(query)) continue;

        final coins = currency == null
            ? provider.supportedCurrencies.toList()
            : provider.supportedCurrencies.contains(currency)
                ? [currency]
                : const <CryptoCurrency>[];

        if (coins.isEmpty) continue;

        tasks.add(
          provider.resolve(
            query: query,
            currencies: coins,
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
