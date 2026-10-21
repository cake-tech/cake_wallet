import "dart:convert";
import "dart:io";

import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/utils/proxy_wrapper.dart";
import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "package:flutter/widgets.dart" show StringCharacters;
import "package:path_provider/path_provider.dart";

/// The longest network name the manual form accepts, feed names are cut to it
const maxNetworkNameLength = 32;

class ChainListEntry {
  const ChainListEntry({
    required this.chainId,
    required this.name,
    required this.shortName,
    required this.symbol,
    required this.decimals,
    required this.rpcUrls,
    this.explorerUrl,
    this.iconUrl,
    this.tvl,
  });

  factory ChainListEntry.fromJson(Map<String, dynamic> json) => ChainListEntry(
        chainId: json["chainId"] as int,
        name: json["name"] as String,
        shortName: json["shortName"] as String? ?? "",
        symbol: json["symbol"] as String,
        decimals: json["decimals"] as int? ?? 18,
        rpcUrls: (json["rpc"] as List<dynamic>).map(_tryRpcUrl).whereType<String>().toList(),
        explorerUrl: json["explorer"] as String?,
        iconUrl: json["icon"] as String?,
        tvl: _tryTvl(json["tvl"]),
      );

  final int chainId;
  final String name;
  final String shortName;
  final String symbol;
  final int decimals;

  final List<String> rpcUrls;
  final String? explorerUrl;

  final String? iconUrl;

  /// ChainList's total value locked in USD, null when the feed has none, as for the bundled list
  final double? tvl;

  Map<String, dynamic> toJson() => {
        "chainId": chainId,
        "name": name,
        "shortName": shortName,
        "symbol": symbol,
        "decimals": decimals,
        "rpc": rpcUrls,
        "explorer": explorerUrl,
        "icon": iconUrl,
        "tvl": tvl,
      };
}

class ChainListSnapshot {
  const ChainListSnapshot({required this.entries, required this.fetchedAt});

  final List<ChainListEntry> entries;
  final DateTime fetchedAt;
}

class ChainListService {
  static const _popularNetworksAssetPath = "assets/evm_networks/popular.json";
  static const _cacheFileName = "chainlist_mainnets.json";
  static final _feedUri = Uri.parse("https://chainlist.org/rpcs.json");

  Future<List<ChainListEntry>> loadPopularNetworks() async {
    final raw = jsonDecode(await rootBundle.loadString(_popularNetworksAssetPath)) as List<dynamic>;
    return raw.map((entry) => ChainListEntry.fromJson(entry as Map<String, dynamic>)).toList();
  }

  Future<ChainListSnapshot?> readCache() async {
    try {
      final file = await _cacheFile();
      if (!file.existsSync()) {
        return null;
      }

      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return ChainListSnapshot(
        entries: (json["entries"] as List<dynamic>).map(_tryCachedEntry).nonNulls.toList(),
        fetchedAt: DateTime.fromMillisecondsSinceEpoch(json["fetchedAt"] as int),
      );
    } catch (e) {
      printV("Failed to read the ChainList cache: $e");
      return null;
    }
  }

  Future<ChainListSnapshot> fetch() async {
    final response =
        await ProxyWrapper().get(clearnetUri: _feedUri).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception("ChainList answered ${response.statusCode}");
    }

    final entries = await compute(parseChainListFeed, response.body);
    if (entries.isEmpty) {
      throw Exception("ChainList returned no mainnets");
    }

    final snapshot = ChainListSnapshot(entries: entries, fetchedAt: DateTime.now());
    await _writeCache(snapshot);
    return snapshot;
  }

  Future<void> _writeCache(ChainListSnapshot snapshot) async {
    try {
      final file = await _cacheFile();
      await file.writeAsString(
        jsonEncode({
          "fetchedAt": snapshot.fetchedAt.millisecondsSinceEpoch,
          "entries": snapshot.entries.map((entry) => entry.toJson()).toList(),
        }),
      );
    } catch (e) {
      printV("Failed to write the ChainList cache: $e");
    }
  }

  Future<File> _cacheFile() async {
    final dir = await getApplicationCacheDirectory();
    return File("${dir.path}/$_cacheFileName");
  }
}

List<ChainListEntry> parseChainListFeed(String body) {
  final feed = jsonDecode(body) as List<dynamic>;
  final entries = <int, ChainListEntry>{};

  for (final item in feed) {
    if (item is! Map<String, dynamic>) {
      continue;
    }

    final entry = _tryEntryFromFeed(item);
    if (entry != null) {
      entries.putIfAbsent(entry.chainId, () => entry);
    }
  }

  return entries.values.toList();
}

ChainListEntry? _tryEntryFromFeed(Map<String, dynamic> item) {
  if (item["isTestnet"] == true || item["testnet"] == true) {
    return null;
  }

  final chainId = item["chainId"];
  final name = item["name"];
  final currency = item["nativeCurrency"];
  if (chainId is! int || chainId <= 0 || name is! String || currency is! Map<String, dynamic>) {
    return null;
  }

  final symbol = currency["symbol"];
  final decimals = currency["decimals"];
  final trimmedName = name.trim();
  if (symbol is! String ||
      symbol.trim().isEmpty ||
      decimals is! int ||
      decimals < 0 ||
      decimals > 36 ||
      trimmedName.isEmpty) {
    return null;
  }

  final rpcs = item["rpc"];
  if (rpcs is! List<dynamic>) {
    return null;
  }

  final untrackedRpcUrls = <String>[];
  final trackedRpcUrls = <String>[];
  for (final rpc in rpcs) {
    final url = _tryRpcUrl(rpc);
    if (url == null || !url.startsWith("https://") || url.contains(r"${")) {
      continue;
    }

    if (rpc is Map<String, dynamic> && rpc["tracking"] == "none") {
      untrackedRpcUrls.add(url);
    } else {
      trackedRpcUrls.add(url);
    }
  }

  final rpcUrls = [...untrackedRpcUrls, ...trackedRpcUrls];
  if (rpcUrls.isEmpty) {
    return null;
  }

  final explorers = item["explorers"];
  final explorer = explorers is List<dynamic> && explorers.isNotEmpty ? explorers.first : null;
  final explorerUrl = explorer is Map<String, dynamic> ? explorer["url"] : null;

  final slug = item["chainSlug"] ?? item["icon"];
  final shortName = item["shortName"];

  return ChainListEntry(
    chainId: chainId,
    name: trimmedName.characters.take(maxNetworkNameLength).toString().trimRight(),
    shortName: shortName is String ? shortName : "",
    symbol: symbol,
    decimals: decimals,
    rpcUrls: rpcUrls,
    explorerUrl: explorerUrl is String && explorerUrl.startsWith("https://") ? explorerUrl : null,
    iconUrl: slug is String && slug.isNotEmpty
        ? "https://icons.llamao.fi/icons/chains/rsz_${Uri.encodeComponent(slug)}.jpg"
        : null,
    tvl: _tryTvl(item["tvl"]),
  );
}

double? _tryTvl(Object? tvl) => tvl is num ? tvl.toDouble() : null;

String? _tryRpcUrl(Object? rpc) {
  final url = rpc is Map<String, dynamic> ? rpc["url"] : rpc;
  return url is String ? url : null;
}

ChainListEntry? _tryCachedEntry(Object? entry) {
  if (entry is! Map<String, dynamic>) {
    return null;
  }

  try {
    final parsed = ChainListEntry.fromJson(entry);
    return parsed.rpcUrls.isEmpty ? null : parsed;
  } catch (e) {
    printV("Skipped a ChainList cache entry: $e");
    return null;
  }
}
