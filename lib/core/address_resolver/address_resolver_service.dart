import 'package:cake_wallet/core/address_resolver/address_sources.dart';
import 'package:cake_wallet/core/address_resolver/ens/ens_record.dart';
import 'package:cake_wallet/core/address_resolver/mastodon/mastodon_api.dart';
import 'package:cake_wallet/core/address_resolver/openalias/openalias_record.dart';
import 'package:cake_wallet/core/address_resolver/parsed_address.dart';
import 'package:cake_wallet/core/address_resolver/twitter/twitter_api.dart';
import 'package:cake_wallet/core/address_resolver/unstoppable/unstoppable_domain_address.dart';
import 'package:cake_wallet/core/address_resolver/wellknown/wellknown_record.dart';
import 'package:cake_wallet/core/address_resolver/yat/yat_service.dart';
import 'package:cake_wallet/core/address_resolver/zano/zano_alias.dart';
import 'package:cake_wallet/core/address_resolver/zcash/zcash_names_record.dart';
import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/entities/emoji_string_extension.dart';
import 'package:cake_wallet/entities/lnurlpay_record.dart';
import 'package:cake_wallet/exchange/provider/thorchain_exchange.provider.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';

import 'bip_353/bip_353_record.dart';
import 'fio/fio_address_provider.dart';
import 'nostr/nostr_api.dart';

class AddressResolverService {
  AddressResolverService({required this.yatService, required this.settingsStore}) {
    _buildLookupTable();
  }

  final YatService yatService;
  final SettingsStore settingsStore;

  late final List<LookupEntry> _lookupTable;

  void _buildLookupTable() {
    _lookupTable = [
      LookupEntry(
        source: AddressSource.zcashMe,
        currencies: AddressSource.zcashMe.supportedCurrencies,
        applies: (q) => q.startsWith('zcash.me/'),
        // zcash.me profile example: zcash.me/username
        run: _lookupZcashMe,
      ),
      LookupEntry(
        source: AddressSource.twitter,
        currencies: AddressSource.twitter.supportedCurrencies,
        applies: (q) => settingsStore.lookupsTwitter && q.startsWith('@'),
        // x handle example: @username
        run: _lookupTwitter,
      ),
      LookupEntry(
        source: AddressSource.zanoAlias,
        currencies: AddressSource.zanoAlias.supportedCurrencies,
        applies: (q) => settingsStore.lookupsZanoAlias && q.startsWith('@'),
        // zano handle example: @username
        run: _lookupZano,
      ),
      LookupEntry(
        source: AddressSource.mastodon,
        currencies: AddressSource.mastodon.supportedCurrencies,
        applies: (q) =>
            settingsStore.lookupsMastodon &&
            q.startsWith('@') &&
            q.contains('@', 1) &&
            q.contains('.', 1),
        // Mastodon handle example: @username@hostname.xxx
        run: _lookupMastodon,
      ),
      LookupEntry(
        source: AddressSource.wellKnown,
        currencies: AddressSource.wellKnown.supportedCurrencies,
        applies: (q) => settingsStore.lookupsWellKnown && q.contains('.') && q.contains('@'),
        // .well-known handle example:
        run: _lookupWellKnown,
      ),
      LookupEntry(
        source: AddressSource.lnurlPay,
        currencies: AddressSource.lnurlPay.supportedCurrencies,
        applies: (q) => q.contains('.') && q.contains('@'),
        // LNURL-pay handle example: user@domain.com
        run: _lookupLnurlPay,
      ),
      LookupEntry(
        source: AddressSource.fio,
        currencies: AddressSource.fio.supportedCurrencies,
        applies: (q) =>
            settingsStore.lookupsFio && !q.startsWith('@') && q.contains('@') && !q.contains('.'),
        // FIO handle example: username@domain
        run: _lookupFio,
      ),
      LookupEntry(
        source: AddressSource.yatRecord,
        currencies: AddressSource.yatRecord.supportedCurrencies,
        applies: (q) => settingsStore.lookupsYatService && q.hasOnlyEmojis,
        // Yat handle example: 🐶🐾
        run: _lookupYatService,
      ),
      LookupEntry(
        source: AddressSource.thorChain,
        currencies: AddressSource.thorChain.supportedCurrencies,
        applies: (q) => settingsStore.lookupsThorChain && q.isNotEmpty,
        run: _lookupThorChain,
      ),
      LookupEntry(
        source: AddressSource.unstoppableDomains,
        currencies: AddressSource.unstoppableDomains.supportedCurrencies,
        applies: (q) {
          if (!settingsStore.lookupsUnstoppableDomains) return false;
          // Unstoppable Domains handle example: name.crypto
          final formattedName = OpenaliasRecord.formatDomainName(q);
          final domainParts = formattedName.split('.');
          final name = domainParts.last;
          return domainParts.length > 1 &&
              domainParts.first.isNotEmpty &&
              name.isNotEmpty &&
              unstoppableDomains.any((domain) => name.trim() == domain);
        },
        run: _lookupsUnstoppableDomains,
      ),
      LookupEntry(
        source: AddressSource.bip353,
        currencies: AddressSource.bip353.supportedCurrencies,
        applies: (q) => settingsStore.lookupsBip353 && q.contains('@') && q.contains('.'),
        run: _lookupsBip353,
      ),
      LookupEntry(
        source: AddressSource.zcashMe,
        currencies: AddressSource.zcashMe.supportedCurrencies,
        applies: (q) {
          if (!settingsStore.lookupsZcashNames) return false;
          final lowerText = q.toLowerCase();
          return lowerText.endsWith('.zec') || lowerText.endsWith('.zcash');
        },
        // Zcash Names handle example: name.zec or name.zcash
        run: _lookupZcashNames,
      ),
      LookupEntry(
        source: AddressSource.ens,
        currencies: AddressSource.ens.supportedCurrencies,
        applies: (q) => settingsStore.lookupsENS && q.endsWith('.eth'),
        // ENS handle example: name.eth
        run: _lookupEns,
      ),
      LookupEntry(
        source: AddressSource.openAlias,
        currencies: AddressSource.openAlias.supportedCurrencies,
        applies: (q) {
          if (!settingsStore.lookupsOpenAlias) return false;
          // OpenAlias handle example:
          final formattedName = OpenaliasRecord.formatDomainName(q);
          return formattedName.contains(".");
        },
        run: _lookupsOpenAlias,
      ),
      LookupEntry(
        source: AddressSource.nostr,
        currencies: AddressSource.nostr.supportedCurrencies,
        applies: (q) => settingsStore.lookupsNostr && isEmailFormat(q),
        // Nostr handle example: name@domain
        run: _lookupsNostr,
      ),
    ];
  }

  static String _stripHtmlTags(String value) {
    return value
        .replaceAll(RegExp(r'[\u2028\u2029]'), '\n')
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .trim();
  }

  static String extractUnstoppableDomain(String raw) {
    // sort by length to avoid matching shorter tld instead of longer
    final domains = List<String>.from(unstoppableDomains)..sort((a, b) => b.length.compareTo(a.length));
    for (final tld in domains) {
      final pattern = RegExp(r'([A-Za-z0-9-]+)\.' + RegExp.escape(tld), caseSensitive: false);
      final match = pattern.firstMatch(raw);
      if (match != null) return match.group(0)!;
    }
    return '';
  }

  static String? extractAddressByType({
    required String raw,
    required CryptoCurrency type,
    bool requireSurroundingWhitespaces = true,
  }) {
    var addressPattern = AddressValidator.getAddressFromStringPattern(type);
    if (addressPattern == null) {
      printV('Unknown pattern for $type');
      return null;
    }
    if (requireSurroundingWhitespaces) addressPattern = "$BEFORE_REGEX$addressPattern$AFTER_REGEX";
    final text = _stripHtmlTags(raw);
    final match = RegExp(addressPattern, multiLine: true, caseSensitive: false).firstMatch(text);
    if (match == null) return null;
    return match.group(0)?.replaceAllMapped(RegExp('[^0-9a-zA-Z]|bitcoincash:|nano_|ban_'),
        (Match match) {
      String group = match.group(0)!;
      if (group.startsWith('bitcoincash:') ||
          group.startsWith('nano_') ||
          group.startsWith('ban_')) {
        return group;
      }
      return '';
    });
  }

  bool isEmailFormat(String address) {
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      caseSensitive: false,
    );
    return emailRegex.hasMatch(address);
  }

  Future<List<ParsedAddress>> resolve({
    required String query,
    required WalletBase wallet,
    CryptoCurrency? currency,
  }) async {
    try {
      final tasks = <Future<ParsedAddress?>>[];

      for (final entry in _lookupTable) {
        if (!supportedSources.contains(entry.source)) continue;
        if (!entry.applies(query)) continue;

        final coins = currency == null
            ? entry.currencies.toList()
            : (entry.currencies.contains(currency) ? [currency] : const <CryptoCurrency>[]);

        if (coins.isEmpty) continue;
        tasks.add(entry.run(query, coins, wallet));
      }

      final results = await Future.wait(tasks);

      return results.whereType<ParsedAddress>().toList();
    } catch (e) {
      printV('Error resolving address: $e');
      return [];
    }
  }

  Future<ParsedAddress?> _lookupZcashMe(
      String text, List<CryptoCurrency> currencies, WalletBase _) async {
    if (!currencies.contains(CryptoCurrency.zec)) return null;

    final parts = text.split('/');
    final handle = parts.last;
    if (parts.length != 2 || handle.isEmpty) return null;

    final address = await _fetchZcashAddress(handle);
    if (address == null || address.isEmpty) return null;

    return ParsedAddress(
      parsedAddressByCurrencyMap: {CryptoCurrency.zec: address},
      addressSource: AddressSource.zcashMe,
      handle: handle,
      profileName: handle,
    );
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

        if (match != null) {
          return match.group(0);
        }
      }
    } catch (e) {
      printV('Error fetching zcash.me profile: $e');
    }
    return null;
  }

  Future<ParsedAddress?> _lookupTwitter(
      String text, List<CryptoCurrency> currencies, WalletBase wallet) async {
    final formattedName = text.substring(1);
    final twitterUser = await TwitterApi.lookupUserByName(userName: formattedName);

    if (twitterUser == null) return null;

    final Map<CryptoCurrency, String> result = {};

    String queryTxt = twitterUser.description;
    final profileDomain = extractUnstoppableDomain(queryTxt);

    try {
      for (final cur in currencies) {
        final addressFromBio =
            extractAddressByType(raw: queryTxt, type: CryptoCurrency.fromString(cur.title));
        printV('Address from bio: $addressFromBio');

        if (addressFromBio != null && addressFromBio.isNotEmpty) {
          result[cur] = addressFromBio;
          queryTxt = queryTxt.replaceFirst(addressFromBio, '');
        }
      }
    } catch (e) {
      printV('Error extracting address from Twitter bio: $e');
    }

    if (result.isEmpty && profileDomain.isNotEmpty) {
      final domainResult = await _lookupsUnstoppableDomains(profileDomain, currencies, wallet);
      if (domainResult != null) {
        return ParsedAddress(
          parsedAddressByCurrencyMap: domainResult.parsedAddressByCurrencyMap,
          addressSource: AddressSource.twitter,
          handle: text,
          profileImageUrl: twitterUser.profileImageUrl,
          profileName: twitterUser.name,
        );
      }
    }

    String locationTxt = twitterUser.location;
    final locationDomain = extractUnstoppableDomain(locationTxt);

    try {
      for (final cur in currencies) {
        final addressFromLocation = extractAddressByType(
          raw: locationTxt,
          type: CryptoCurrency.fromString(cur.title),
          requireSurroundingWhitespaces: false,
        );

        if (addressFromLocation != null && addressFromLocation.isNotEmpty) {
          result[cur] = addressFromLocation;
          locationTxt = locationTxt.replaceFirst(addressFromLocation, '');
        }
      }
    } catch (e) {
      printV('Error extracting address from Twitter location: $e');
    }

    if (result.isEmpty && locationDomain.isNotEmpty) {
      final domainResult = await _lookupsUnstoppableDomains(locationDomain, currencies, wallet);
      if (domainResult != null) {
        return ParsedAddress(
          parsedAddressByCurrencyMap: domainResult.parsedAddressByCurrencyMap,
          addressSource: AddressSource.twitter,
          handle: text,
          profileImageUrl: twitterUser.profileImageUrl,
          profileName: twitterUser.name,
        );
      }
    }

    String pinnedTweet = twitterUser.pinnedTweet?.text ?? '';

    try {
      if (pinnedTweet.isNotEmpty) {
        for (final cur in currencies) {
          final addressFromPinnedTweet =
              extractAddressByType(raw: pinnedTweet, type: CryptoCurrency.fromString(cur.title));
          if (addressFromPinnedTweet != null && addressFromPinnedTweet.isNotEmpty) {
            result[cur] = addressFromPinnedTweet;
            pinnedTweet = pinnedTweet.replaceFirst(addressFromPinnedTweet, '');
          }
        }
      }
    } catch (e) {
      printV('Error extracting address from Twitter pinned tweet: $e');
    }

    if (result.isEmpty && pinnedTweet.isNotEmpty) {
      final pinnedTweetDomain = extractUnstoppableDomain(pinnedTweet);
      if (pinnedTweetDomain.isNotEmpty) {
        final domainResult =
            await _lookupsUnstoppableDomains(pinnedTweetDomain, currencies, wallet);
        if (domainResult != null) {
          return ParsedAddress(
            parsedAddressByCurrencyMap: domainResult.parsedAddressByCurrencyMap,
            addressSource: AddressSource.twitter,
            handle: text,
            profileImageUrl: twitterUser.profileImageUrl,
            profileName: twitterUser.name,
          );
        }
      }
    }

    if (result.isNotEmpty) {
      return ParsedAddress(
        parsedAddressByCurrencyMap: result,
        addressSource: AddressSource.twitter,
        handle: text,
        profileImageUrl: twitterUser.profileImageUrl,
        profileName: twitterUser.name,
      );
    }
    return null;
  }

  Future<ParsedAddress?> _lookupZano(String text, List<CryptoCurrency> _, WalletBase __) async {
    final formattedName = text.substring(1);

    final zanoAddress = await ZanoAlias.fetchZanoAliasAddress(formattedName);
    if (zanoAddress != null && zanoAddress.isNotEmpty) {
      return ParsedAddress(
        parsedAddressByCurrencyMap: {CryptoCurrency.zano: zanoAddress},
        addressSource: AddressSource.zanoAlias,
        handle: text,
      );
    }
    return null;
  }

  Future<ParsedAddress?> _lookupMastodon(
      String text, List<CryptoCurrency> currencies, WalletBase _) async {
    final subText = text.substring(1);
    final hostNameIndex = subText.indexOf('@');
    final hostName = subText.substring(hostNameIndex + 1);
    final userName = subText.substring(0, hostNameIndex);

    final Map<CryptoCurrency, String> result = {};

    final mastodonUser =
        await MastodonAPI.lookupUserByUserName(userName: userName, apiHost: hostName);

    if (mastodonUser != null) {
      String queryTxt = _stripHtmlTags(mastodonUser.note);
      for (final cur in currencies) {
        String? addressFromBio = extractAddressByType(raw: queryTxt, type: cur);
        if (addressFromBio != null && addressFromBio.isNotEmpty) {
          result[cur] = addressFromBio;
          queryTxt = queryTxt.replaceFirst(addressFromBio, '');
        }
      }

      final pinnedPosts =
          await MastodonAPI.getPinnedPosts(userId: mastodonUser.id, apiHost: hostName);

      if (pinnedPosts.isNotEmpty) {
        String userPinnedPostsText =
            pinnedPosts.map((item) => _stripHtmlTags(item.content)).join('\n');

        for (final cur in currencies) {
          String? addressFromPinnedPost = extractAddressByType(raw: userPinnedPostsText, type: cur);
          if (addressFromPinnedPost != null && addressFromPinnedPost.isNotEmpty) {
            result[cur] = addressFromPinnedPost;
            userPinnedPostsText = userPinnedPostsText.replaceFirst(addressFromPinnedPost, '');
          }
        }
      }

      if (result.isNotEmpty) {
        return ParsedAddress(
          parsedAddressByCurrencyMap: result,
          addressSource: AddressSource.mastodon,
          handle: text,
          profileImageUrl: mastodonUser.profileImageUrl,
          profileName: mastodonUser.username,
        );
      }
    }
    return null;
  }

  Future<ParsedAddress?> _lookupWellKnown(
      String text, List<CryptoCurrency> currencies, WalletBase _) async {
    if (!currencies.contains(CryptoCurrency.nano)) return null;

    final rec = await WellKnownRecord.fetch(text, CryptoCurrency.nano);
    if (rec == null || rec.address.isEmpty) return null;

    return ParsedAddress(
      parsedAddressByCurrencyMap: {CryptoCurrency.nano: rec.address},
      addressSource: AddressSource.wellKnown,
      handle: text,
      profileName: rec.title ?? '',
      profileImageUrl: rec.imageUrl ?? '',
    );
  }

  Future<ParsedAddress?> _lookupFio(
      String text, List<CryptoCurrency> currencies, WalletBase _) async {
    final Map<CryptoCurrency, String> result = {};
    final bool isFioRegistered = await FioAddressProvider.checkAvail(text);
    if (!isFioRegistered) return null;

    for (final cur in currencies) {
      final address = await FioAddressProvider.getPubAddress(text, cur.title);
      if (address != null && address.isNotEmpty) {
        result[cur] = address;
      }
    }

    if (result.isNotEmpty) {
      return ParsedAddress(
        parsedAddressByCurrencyMap: result,
        addressSource: AddressSource.fio,
        handle: text,
      );
    }
    return null;
  }

  Future<ParsedAddress?> _lookupYatService(
      String text, List<CryptoCurrency> currencies, WalletBase _) async {
    final result = <CryptoCurrency, String>{};

    for (final cur in currencies) {
      final records = await yatService.fetchYatAddress(text, cur.title);
      if (records.isEmpty) continue;

      final chosen = cur == CryptoCurrency.xmr
          ? records.firstWhere((r) => r.isMoneroSub, orElse: () => records.first)
          : records.first;

      result[cur] = chosen.address;
    }

    return result.isEmpty
        ? null
        : ParsedAddress(
      parsedAddressByCurrencyMap: result,
      addressSource: AddressSource.yatRecord,
      handle: text,
    );
  }

  Future<ParsedAddress?> _lookupThorChain(
      String text, List<CryptoCurrency> currencies, WalletBase _) async {
    final isNormalAddress =
        currencies.any((cur) => extractAddressByType(raw: text, type: cur)?.isNotEmpty ?? false);
    if (text.length > 30 || isNormalAddress) return null;

    final map = await ThorChainExchangeProvider.lookupAddressByName(text);
    if (map == null || map.isEmpty) return null;

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

    return result.isEmpty
        ? null
        : ParsedAddress(
            parsedAddressByCurrencyMap: result,
            addressSource: AddressSource.thorChain,
            handle: text,
          );
  }

  Future<ParsedAddress?> _lookupsUnstoppableDomains(
      String text, List<CryptoCurrency> currency, WalletBase _) async {
    final Map<CryptoCurrency, String> result = {};
    for (final cur in currency) {
      final address = await fetchUnstoppableDomainAddress(text, cur.title);
      if (address.isNotEmpty) {
        result[cur] = address;
      }
    }

    if (result.isNotEmpty) {
      return ParsedAddress(
        parsedAddressByCurrencyMap: result,
        profileImageUrl: 'assets/images/profile.png',
        profileName: text,
        addressSource: AddressSource.unstoppableDomains,
        handle: text,
      );
    }

    return null;
  }

  Future<ParsedAddress?> _lookupsBip353(
      String text, List<CryptoCurrency> currencies, WalletBase _) async {
    final result = <CryptoCurrency, String>{};
    String? dnsProof;

    for (final cur in currencies) {
      final bip353AddressMap = await Bip353Record.fetchUriByCryptoCurrency(text, cur.title);
      if (bip353AddressMap == null || bip353AddressMap.isEmpty) continue;

      final spAddress = bip353AddressMap['sp'];
      final address = bip353AddressMap['address'];
      final chosenAddress = spAddress?.isNotEmpty == true ? spAddress : address;

      if (chosenAddress != null && chosenAddress.isNotEmpty) {
        result[cur] = chosenAddress;
      }
    }

    if (result.isEmpty) return null;

    try {
      dnsProof = await Bip353Record.fetchDnsProof(text);
    } catch (e) {
      printV('Bip353Record.fetchDnsProof error: $e');
    }

    return ParsedAddress(
      parsedAddressByCurrencyMap: result,
      addressSource: AddressSource.bip353,
      handle: text,
      bip353DnsProof: dnsProof ?? '',
    );
  }

  Future<ParsedAddress?> _lookupLnurlPay(
      String text, List<CryptoCurrency> currencies, WalletBase wallet) async {
    if (wallet.type != WalletType.bitcoin || !currencies.contains(CryptoCurrency.btc)) {
      return null;
    }

    final record = await LNUrlPayRecord.fetchAddressAndName(
      formattedName: text,
      currency: CryptoCurrency.btc,
    );
    if (record == null || record.address.isEmpty) return null;

    return ParsedAddress(
      parsedAddressByCurrencyMap: {CryptoCurrency.btc: record.address},
      addressSource: AddressSource.lnurlPay,
      handle: text,
    );
  }

  Future<ParsedAddress?> _lookupZcashNames(
      String text, List<CryptoCurrency> currencies, WalletBase _) async {
    if (!currencies.contains(CryptoCurrency.zec)) return null;

    final address = await ZcashNamesRecord.fetchZcashNamesAddress(text);
    if (address == null || address.isEmpty) return null;

    return ParsedAddress(
      parsedAddressByCurrencyMap: {CryptoCurrency.zec: address},
      addressSource: AddressSource.zcashMe,
      handle: text,
      profileName: text,
    );
  }

  Future<ParsedAddress?> _lookupEns(
      String text, List<CryptoCurrency> currency, WalletBase wallet) async {
    final Map<CryptoCurrency, String> result = {};

    for (final cur in currency) {
      final address = await EnsRecord.fetchEnsAddress(text, cur, wallet: wallet);
      if (address.isNotEmpty && address != "0x0000000000000000000000000000000000000000") {
        result[cur] = address;
      }
    }

    if (result.isNotEmpty) {
      return ParsedAddress(
        parsedAddressByCurrencyMap: result,
        addressSource: AddressSource.ens,
        handle: text,
      );
    }
    return null;
  }

  Future<ParsedAddress?> _lookupsOpenAlias(
    String text,
    List<CryptoCurrency> currencies,
    WalletBase _,
  ) async {
    final formatted = OpenaliasRecord.formatDomainName(text);

    final txtRecords = await OpenaliasRecord.lookupOpenAliasRecord(formatted);
    if (txtRecords == null) return null;

    final result = <CryptoCurrency, String>{};

    for (final cur in currencies) {
      final rec = OpenaliasRecord.fetchAddressAndName(
        formattedName: formatted,
        ticker: cur.title.toLowerCase(),
        txtRecord: txtRecords,
      );

      if (rec.address.isNotEmpty) result[cur] = rec.address;
    }

    return result.isEmpty
        ? null
        : ParsedAddress(
            parsedAddressByCurrencyMap: result,
            addressSource: AddressSource.openAlias,
            handle: text,
          );
  }

  Future<ParsedAddress?> _lookupsNostr(
      String text, List<CryptoCurrency> currencies, WalletBase _) async {
    try {
      final profile = await NostrProfileHandler.queryProfile(text);
      if (profile == null) return null;

      final data = await NostrProfileHandler.processRelays(profile, text);
      if (data == null) return null;

      final result = <CryptoCurrency, String>{};

      String queryTxt = data.about;

      for (final cur in currencies) {
        final addr = extractAddressByType(raw: queryTxt, type: cur);
        if (addr != null && addr.isNotEmpty) {
          result[cur] = addr;
          queryTxt = queryTxt.replaceFirst(addr, '');
        }
      }
      if (result.isEmpty) return null;

      return ParsedAddress(
        parsedAddressByCurrencyMap: result,
        addressSource: AddressSource.nostr,
        handle: text,
        profileImageUrl: data.picture,
        profileName: data.name,
      );
    } catch (e) {
      printV('Error looking up Nostr profile: $e');
      return null;
    }
  }
}

class LookupEntry {
  const LookupEntry({
    required this.source,
    required this.currencies,
    required this.applies,
    required this.run,
  });

  final AddressSource source;
  final List<CryptoCurrency> currencies;
  final bool Function(String query) applies;
  final Future<ParsedAddress?> Function(
      String query, List<CryptoCurrency> currencies, WalletBase wallet) run;
}
