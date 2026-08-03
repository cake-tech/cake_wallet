import 'package:cake_wallet/core/address_resolver/address_lookup_provider.dart';
import 'package:cake_wallet/core/address_resolver/address_resolver_utils.dart';
import 'package:cake_wallet/core/address_resolver/address_sources.dart';
import 'package:cake_wallet/core/address_resolver/parsed_address.dart';
import 'package:cake_wallet/core/address_resolver/twitter/twitter_api.dart';
import 'package:cake_wallet/core/address_resolver/twitter/twitter_user.dart';
import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';

class TwitterAddressProvider extends AddressLookupProvider {
  @override
  AddressSource get source => AddressSource.twitter;

  @override
  List<CryptoCurrency> get supportedCurrencies => AddressValidator.reliableValidateCurrencies;

  @override
  bool isEnabled(SettingsStore settingsStore) => settingsStore.lookupsTwitter;

  @override
  bool canHandle(String query) =>
      query.startsWith('@') && !query.substring(1).contains('@'); // x handle example: @username

  /// Resolves a Twitter handle to a list of ParsedAddress objects by extracting potential cryptocurrency addresses
  /// from the user's, profile.
  /// fallback to resolving Unstoppable Domains if no addresses are found in each of the Twitter user's bio, location, and pinned tweet.

  @override
  Future<List<ParsedAddress>> resolve({
    required String query,
    required List<CryptoCurrency> currencies,
    required WalletBase wallet,
  }) async {
    final formattedName = query.replaceFirst("@", "");
    try {
      final result = <CryptoCurrency, String>{};

      final twitterUser = await TwitterApi.lookupUserByName(userName: formattedName);

      final bio = (text: twitterUser.description, whitespaces: true);
      final location = (text: twitterUser.location, whitespaces: false);
      final pinnedTweet = (text: twitterUser.pinnedTweet?.text ?? '', whitespaces: true);

      final twitterTexts = [
        bio,
        location,
        pinnedTweet,
      ].where((item) => item.text.isNotEmpty);

      for (final item in twitterTexts) {
        result.addAll(
          AddressResolverUtils.extractAddressesFromText(
            raw: item.text,
            currencies: currencies,
            requireSurroundingWhitespaces: item.whitespaces,
          ),
        );

        if (result.isEmpty) {
          final domainResult = await AddressResolverUtils.resolveUnstoppableDomainFromText(
            raw: item.text,
            currencies: currencies,
          );

          if (domainResult.isNotEmpty) {
            return [_buildTwitterParsedAddress(query, twitterUser, domainResult)];
          }
        }
      }

      if (result.isEmpty) return [];

      return [_buildTwitterParsedAddress(query, twitterUser, result)];
    } catch (e) {
      printV('[address resolver service] Twitter error: $e');
      return [];
    }
  }

  ParsedAddress _buildTwitterParsedAddress(
    String query,
    TwitterUser twitterUser,
    Map<CryptoCurrency, String> result,
  ) {
    return ParsedAddress(
      parsedAddressByCurrencyMap: result,
      addressSource: AddressSource.twitter,
      handle: query,
      profileImageUrl: twitterUser.profileImageUrl,
      profileName: twitterUser.name,
    );
  }
}
