import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/core/yat_service.dart';
import 'package:cake_wallet/entities/emoji_string_extension.dart';
import 'package:cake_wallet/entities/ens_record.dart';
import 'package:cake_wallet/entities/fio_address_provider.dart';
import 'package:cake_wallet/entities/openalias_record.dart';
import 'package:cake_wallet/entities/parsed_address.dart';
import 'package:cake_wallet/entities/unstoppable_domain_address.dart';
import 'package:cake_wallet/entities/wellknown_record.dart';
import 'package:cake_wallet/entities/zano_alias.dart';
import 'package:cake_wallet/exchange/provider/thorchain_exchange.provider.dart';
import 'package:cake_wallet/mastodon/mastodon_api.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/twitter/twitter_api.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';

import 'bip_353_record.dart';

class AddressResolverService {
  AddressResolverService({required this.yatService, required this.settingsStore}) {
    _buildLookupTable();
  }

  final YatService yatService;
  final SettingsStore settingsStore;

  static const unstoppableDomains = [
    "888",
    "academy",
    "agency",
    "altimist",
    "anime",
    "austin",
    "bald",
    "bay",
    "benji",
    "bet",
    "binanceus",
    "bitcoin",
    "bitget",
    "bitscrunch",
    "blockchain",
    "boomer",
    "boston",
    "ca",
    "caw",
    "cc",
    "chat",
    "chomp",
    "clay",
    "club",
    "co",
    "com",
    "company",
    "crypto",
    "dao",
    "design",
    "dfz",
    "digital",
    "doga",
    "donut",
    "dream",
    "email",
    "emir",
    "eth",
    "ethermail",
    "family",
    "farms",
    "finance",
    "fun",
    "fyi",
    "games",
    "global",
    "go",
    "group",
    "guru",
    "hi",
    "hockey",
    "host",
    "info",
    "io",
    "klever",
    "kresus",
    "kryptic",
    "lfg",
    "life",
    "live",
    "llc",
    "ltc",
    "ltd",
    "manga",
    "me",
    "media",
    "metropolis",
    "miami",
    "miku",
    "money",
    "moon",
    "mumu",
    "net",
    "network",
    "news",
    "nft",
    "npc",
    "onchain",
    "online",
    "org",
    "podcast",
    "pog",
    "polygon",
    "press",
    "privacy",
    "pro",
    "propykeys",
    "pudgy",
    "pw",
    "quantum",
    "rad",
    "raiin",
    "retardio",
    "rip",
    "rocks",
    "secret",
    "services",
    "site",
    "smobler",
    "social",
    "solutions",
    "space",
    "stepn",
    "store",
    "studio",
    "systems",
    "tball",
    "tea",
    "team",
    "tech",
    "technology",
    "today",
    "tribe",
    "u",
    "ubu",
    "uno",
    "unstoppable",
    "vip",
    "wallet",
    "website",
    "wif",
    "wifi",
    "witg",
    "work",
    "world",
    "wrkx",
    "wtf",
    "x",
    "xmr",
    "xyz",
    "zil",
    "zone"
  ];

  late final List<LookupEntry> _lookupTable;

  void _buildLookupTable() {
    _lookupTable = [
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
        source: AddressSource.fio,
        currencies: AddressSource.fio.supportedCurrencies,
        applies: (q) => !q.startsWith('@') && q.contains('@') && !q.contains('.'),
        // TODO: Add condition for FIO lookups
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
        applies: (q) => true,
        // ThorChain handles can be any string //TODO: Add condition for ThorChain lookups
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
        applies: (q) => true, //TODO: Add condition for BIP-353 lookups
        run: _lookupsBip353,
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
        currencies: [CryptoCurrency.btc],
        applies: (q) => isEmailFormat(q),
        // Nostr handle example: name@domain //TODO: Add condition for Nostr lookups
        run: _lookupsNostr,
      ),
    ];
  }



      static  String _cleanInput(String raw) => raw
      .replaceAll(RegExp(r'[\u2028\u2029]'), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), ' ');

  static String? extractAddressByType({
    required String raw,
    required CryptoCurrency type,
  }) {
    final pat = AddressValidator.getAddressFromStringPattern(type);
    if (pat == null) {
      throw StateError('Unknown pattern for $type');
    }

    final text = _cleanInput(raw);

    final regex = RegExp(r'(?:^|[^0-9A-Za-z])(' + pat + r')',
        multiLine: true, caseSensitive: false);

    final m = regex.firstMatch(text);
    if (m == null) return null;

    // 3.  Strip BCH / NANO prefixes and punctuation just like before
    final cleaned = m
        .group(1)!
        .replaceAllMapped(RegExp(r'[^0-9a-zA-Z]|bitcoincash:|nano_|ban_'), (m) {
      final g = m.group(0)!;
      return (g.startsWith('bitcoincash:') || g.startsWith('nano_') || g.startsWith('ban_'))
          ? g
          : '';
    });

    return cleaned;
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

  Future<ParsedAddress?> _lookupTwitter(
      String text, List<CryptoCurrency> currencies, WalletBase wallet) async {
    final formattedName = text.substring(1);
    final twitterUser = await TwitterApi.lookupUserByName(userName: formattedName);

    if (twitterUser == null) return null;

    final Map<CryptoCurrency, String> result = {};

    for (final cur in currencies) {
      final addressFromBio = extractAddressByType(
          raw: twitterUser.description, type: CryptoCurrency.fromString(cur.title));

      if (addressFromBio != null && addressFromBio.isNotEmpty) {
        result[cur] = addressFromBio;
      }
    }

    final pinnedTweet = twitterUser.pinnedTweet?.text;
    if (pinnedTweet != null) {
      for (final cur in currencies) {
        final addressFromPinnedTweet =
            extractAddressByType(raw: pinnedTweet, type: CryptoCurrency.fromString(cur.title));
        if (addressFromPinnedTweet != null && addressFromPinnedTweet.isNotEmpty) {
          result[cur] = addressFromPinnedTweet;
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

  Future<ParsedAddress?> _lookupZano(
      String text, List<CryptoCurrency> currencies, WalletBase _) async {
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
      for (final cur in currencies) {
        String? addressFromBio = extractAddressByType(raw: mastodonUser.note, type: cur);
        if (addressFromBio != null && addressFromBio.isNotEmpty) {
          result[cur] = addressFromBio;
        }
      }

      final pinnedPosts =
          await MastodonAPI.getPinnedPosts(userId: mastodonUser.id, apiHost: hostName);

      if (pinnedPosts.isNotEmpty) {
        final userPinnedPostsText = pinnedPosts.map((item) => item.content).join('\n');

        for (final cur in currencies) {
          String? addressFromPinnedPost = extractAddressByType(raw: userPinnedPostsText, type: cur);
          if (addressFromPinnedPost != null && addressFromPinnedPost.isNotEmpty) {
            result[cur] = addressFromPinnedPost;
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
    final Map<CryptoCurrency, String> result = {};

    for (final cur in currencies) {
      final record = await WellKnownRecord.fetchAddressAndName(formattedName: text, currency: cur);
      if (record != null) {
        result[cur] = record.address;
      }
    }

    if (result.isNotEmpty) {
      return ParsedAddress(
        parsedAddressByCurrencyMap: result,
        addressSource: AddressSource.wellKnown,
        handle: text,
      );
    }
    return null;
  }

  Future<ParsedAddress?> _lookupFio(
      String text, List<CryptoCurrency> currencies, WalletBase _) async {
    final Map<CryptoCurrency, String> result = {};
    final bool isFioRegistered = await FioAddressProvider.checkAvail(text);
    if (!isFioRegistered) return null;

    for (final cur in currencies) {
      final address = await FioAddressProvider.getPubAddress(text, cur.title);
      if (address.isNotEmpty) {
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
      String text, List<CryptoCurrency> currency, WalletBase _) async {
    final Map<CryptoCurrency, String> result = {};

    for (final cur in currency) {
      final addresses = await yatService.fetchYatAddress(text, cur.title);
      if (addresses.isNotEmpty) {
        result[cur] = addresses.first.address; //TODO: Handle multiple addresses
      }
      if (result.isNotEmpty) {
        return ParsedAddress(
          parsedAddressByCurrencyMap: result,
          addressSource: AddressSource.yatRecord,
          handle: text,
        );
      }
    }
    return null;
  }

  Future<ParsedAddress?> _lookupThorChain(
      String text, List<CryptoCurrency> currency, WalletBase _) async {
    final Map<CryptoCurrency, String> result = {};

    final thorChainAddress = await ThorChainExchangeProvider.lookupAddressByName(text);
    if (thorChainAddress != null && thorChainAddress.isNotEmpty) {
      for (final cur in currency) {
        String? address =
            thorChainAddress[cur.title] ?? (cur.title == 'RUNE' ? thorChainAddress['THOR'] : null);
        if (address != null && address.isNotEmpty) {
          result[cur] = address;
        }
      }

      if (result.isNotEmpty) {
        return ParsedAddress(
          parsedAddressByCurrencyMap: result,
          addressSource: AddressSource.thorChain,
          handle: text,
        );
      }
    }
    return null;
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
      String text, List<CryptoCurrency> currency, WalletBase _) async {
    final Map<CryptoCurrency, String> result = {};

    for (final cur in currency) {
      final bip353AddressMap = await Bip353Record.fetchUriByCryptoCurrency(text, cur.title);
      if (bip353AddressMap != null && bip353AddressMap.isNotEmpty) {
        final address = bip353AddressMap['address'];
        if (address != null && address.isNotEmpty) {
          result[cur] = address;
        }
      }
    }
    if (result.isNotEmpty) {
      return ParsedAddress(
        parsedAddressByCurrencyMap: result,
        addressSource: AddressSource.bip353,
        handle: text,
      );
    }

    //
    // if (bip353AddressMap != null && bip353AddressMap.isNotEmpty) {
    //   final chosenAddress =
    //   await Bip353Record.pickBip353AddressChoice(text, bip353AddressMap); //TODO fix context
    //   if (chosenAddress != null) {
    //     return ParsedAddress.fetchBip353AddressAddress(address: chosenAddress, name: text);
    //   }
    // }
    return null;
  }

  Future<ParsedAddress?> _lookupEns(
      String text, List<CryptoCurrency> currency, WalletBase wallet) async {
    final Map<CryptoCurrency, String> result = {};

    for (final cur in currency) {
      final address = await EnsRecord.fetchEnsAddress(text, wallet: wallet);
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
      String text, List<CryptoCurrency> currency, WalletBase _) async {
    final formattedName = OpenaliasRecord.formatDomainName(text);
    final txtRecord = await OpenaliasRecord.lookupOpenAliasRecord(formattedName);
    final Map<CryptoCurrency, String> result = {};

    for (final cur in currency) {
      if (txtRecord == null) continue;
      final record = await OpenaliasRecord.fetchAddressAndName(
          formattedName: formattedName, ticker: cur.title.toLowerCase(), txtRecord: txtRecord);
      if (record.address.isNotEmpty) {
        result[cur] = record.address;
      }
    }

    if (result.isNotEmpty) {
      return ParsedAddress(
        parsedAddressByCurrencyMap: result,
        addressSource: AddressSource.openAlias,
        handle: text,
      );
    }

    return null;
  }

  Future<ParsedAddress?> _lookupsNostr(
      String text, List<CryptoCurrency> currency, WalletBase _) async {
    //TODO implement Nostr lookup logic
    // final nostrProfile = await NostrProfileHandler.queryProfile(context, text);
    // if (nostrProfile?.relays != null) {
    //   final nostrUserData =
    //   await NostrProfileHandler.processRelays(context, nostrProfile!, text);
    //
    //   if (nostrUserData != null) {
    //     String? addressFromBio = extractAddressByType(raw: nostrUserData.about, type: currency);
    //     if (addressFromBio != null && addressFromBio.isNotEmpty) {
    //       return ParsedAddress.nostrAddress(
    //           address: addressFromBio,
    //           name: text,
    //           profileImageUrl: nostrUserData.picture,
    //           profileName: nostrUserData.name);
    //     }
    //   }
    // }
    return null;
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
