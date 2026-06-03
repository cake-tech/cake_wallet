import 'dart:convert';

import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';

const unstoppableDomains = [
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

Future<String> fetchUnstoppableDomainAddress(String domain, String ticker) async {
  var address = '';

  try {
    final uri = Uri.parse("https://api.unstoppabledomains.com/profile/public/${Uri.encodeQueryComponent(domain)}?fields=records");
    final response = await ProxyWrapper().get(clearnetUri: uri);
    
    final jsonParsed = json.decode(response.body) as Map<String, dynamic>;
    if (jsonParsed["records"] == null) {
      throw Exception(".records response from $uri is empty");
    };
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