import 'package:cake_wallet/core/address_resolver/address_lookup_provider.dart';
import 'package:cake_wallet/core/address_resolver/address_resolver_utils.dart';
import 'package:cake_wallet/core/address_resolver/address_sources.dart';
import 'package:cake_wallet/core/address_resolver/mastodon/mastodon_api.dart';
import 'package:cake_wallet/core/address_resolver/parsed_address.dart';
import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';

class MastodonAddressProvider extends AddressLookupProvider {
  @override
  AddressSource get source => AddressSource.mastodon;

  @override
  List<CryptoCurrency> get supportedCurrencies => AddressValidator.reliableValidateCurrencies;

  @override
  bool isEnabled(SettingsStore settingsStore) => settingsStore.lookupsMastodon;

  @override
  bool canHandle(String query) =>
      query.startsWith('@') &&
      query.contains('@', 1) &&
      query.contains('.', 1); // Mastodon handle example: @username@hostname.xxx

  @override
  Future<List<ParsedAddress>> resolve({
    required String query,
    required List<CryptoCurrency> currencies,
    required WalletBase wallet,
  }) async {
    try {
      final subText = query.substring(1); // Remove '@' from the beginning of the handle
      final hostNameIndex = subText.indexOf('@');
      if (hostNameIndex <= 0 || hostNameIndex == subText.length - 1) return [];

      final userName = subText.substring(0, hostNameIndex);
      final hostName = subText.substring(hostNameIndex + 1);

      final result = <CryptoCurrency, String>{};

      final mastodonUser = await MastodonAPI.lookupUserByUserName(
        userName: userName,
        apiHost: hostName,
      );
      if (mastodonUser == null) return [];

      final bio = AddressResolverUtils.stripHtmlTags(mastodonUser.note);
      result.addAll(
        AddressResolverUtils.extractAddressesFromText(
          raw: bio,
          currencies: currencies,
        ),
      );

      final pinnedPosts = await MastodonAPI.getPinnedPosts(
        userId: mastodonUser.id,
        apiHost: hostName,
      );

      if (pinnedPosts.isNotEmpty) {
        final pinnedPostsText = pinnedPosts
            .map((item) => AddressResolverUtils.stripHtmlTags(item.content))
            .where((text) => text.isNotEmpty)
            .join('\n');

        result.addAll(
          AddressResolverUtils.extractAddressesFromText(
            raw: pinnedPostsText,
            currencies: currencies,
          ),
        );
      }

      if (result.isEmpty) return [];

      return [
        ParsedAddress(
          parsedAddressByCurrencyMap: result,
          addressSource: AddressSource.mastodon,
          handle: query,
          profileImageUrl: mastodonUser.profileImageUrl,
          profileName: mastodonUser.username,
        ),
      ];
    } catch (e) {
      printV('[address resolver] Error resolving Mastodon address: $e');
      return [];
    }
  }
}
