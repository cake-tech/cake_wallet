import 'dart:convert';

import 'package:cake_wallet/core/address_resolver/address_lookup_provider.dart';
import 'package:cake_wallet/core/address_resolver/address_sources.dart';
import 'package:cake_wallet/core/address_resolver/openalias/openalias_record.dart';
import 'package:cake_wallet/core/address_resolver/parsed_address.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/wallet_base.dart';

class UnstoppableAddressProvider extends AddressLookupProvider {
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
    "base",
    "arbitrum",
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
    "zone",
    "pizza"
  ];

  @override
  AddressSource get source => AddressSource.unstoppableDomains;

  @override
  List<CryptoCurrency> get supportedCurrencies => [CryptoCurrency.xmr, CryptoCurrency.btc];

  @override
  bool isEnabled(SettingsStore settingsStore) => settingsStore.lookupsUnstoppableDomains;

  @override
  bool canHandle(String query) {
    // Unstoppable Domains handle example: name.crypto
    final formattedName = OpenaliasRecord.formatDomainName(query);
    final domainParts = formattedName.split('.');
    final name = domainParts.last;
    return domainParts.length > 1 &&
        domainParts.first.isNotEmpty &&
        name.isNotEmpty &&
        unstoppableDomains.any((domain) => name.trim() == domain);
  }

  @override
  Future<List<ParsedAddress>> resolve({
    required String query,
    required List<CryptoCurrency> currencies,
    required WalletBase wallet,
  }) async {
    try {
      final formattedName = OpenaliasRecord.formatDomainName(query);
      final result = <CryptoCurrency, String>{};

      for (final currency in currencies) {
        final address = await fetchUnstoppableDomainAddress(
          formattedName,
          currency.title,
        );

        if (address.isNotEmpty) {
          result[currency] = address;
        }
      }

      if (result.isEmpty) return [];

      return [
        ParsedAddress(
          parsedAddressByCurrencyMap: result,
          profileName: formattedName,
          addressSource: AddressSource.unstoppableDomains,
          handle: formattedName,
        ),
      ];
    } catch (e) {
      printV('[address resolver] Error resolving Unstoppable Domain: $e');
      return [];
    }
  }

  static Future<String> fetchUnstoppableDomainAddress(String domain, String ticker) async {
    var address = '';

    try {
      final uri = Uri.parse(
          "https://api.unstoppabledomains.com/profile/public/${Uri.encodeQueryComponent(domain)}?fields=records");
      final response = await ProxyWrapper().get(clearnetUri: uri);

      final jsonParsed = json.decode(response.body) as Map<String, dynamic>;
      if (jsonParsed["records"] == null) {
        throw Exception(".records response from $uri is empty");
      }
      ;
      final records = jsonParsed["records"] as Map<String, dynamic>;
      final key = "crypto.${ticker.toUpperCase()}.address";
      if (records[key] == null) {
        throw Exception(".records.${key} response from $uri is empty");
      }

      return records[key] as String? ?? '';
    } catch (e) {
      printV('Unstoppable domain error: ${e.toString()}');
      address = '';
    }

    return address;
  }
}
