import "dart:convert";
import "dart:io";

import "package:cake_wallet/new-ui/services/chain_list_service.dart";
import "package:cw_core/utils/proxy_wrapper.dart";
import "package:cw_core/utils/tor/disabled.dart";
import "package:flutter_test/flutter_test.dart";
import "package:path_provider_platform_interface/path_provider_platform_interface.dart";

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this.root);

  final String root;

  @override
  Future<String?> getApplicationCachePath() async => root;
}

class _LocalServerOverrides extends HttpOverrides {
  _LocalServerOverrides(this.port);

  final int port;

  @override
  HttpClient createHttpClient(SecurityContext? context) => super.createHttpClient(context)
    ..connectionFactory =
        (uri, proxyHost, proxyPort) => Socket.startConnect(InternetAddress.loopbackIPv4, port);
}

Map<String, dynamic> _feedItem({
  Object? chainId = 57073,
  Object? name = "Ink",
  Object? nativeCurrency = const {"symbol": "ETH", "decimals": 18},
  List<Object?> rpc = const ["https://rpc-gel.inkonchain.com"],
  Object? explorers,
  Object? chainSlug,
  Object? icon,
  Object? shortName = "ink",
  Object? tvl,
  bool isTestnet = false,
}) =>
    {
      "chainId": chainId,
      "name": name,
      "shortName": shortName,
      "nativeCurrency": nativeCurrency,
      "rpc": rpc,
      if (explorers != null) "explorers": explorers,
      if (chainSlug != null) "chainSlug": chainSlug,
      if (icon != null) "icon": icon,
      if (tvl != null) "tvl": tvl,
      if (isTestnet) "isTestnet": true,
    };

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  const trackedRpc = "https://tracked.example";
  const untrackedRpc = "https://untracked.example";
  const plainRpc = "https://plain.example";

  late Directory cacheRoot;
  late File cacheFile;
  late HttpServer server;
  late List<String> requestedUrls;
  late int feedStatus;
  late String feedBody;

  setUpAll(() async {
    cacheRoot = Directory.systemTemp.createTempSync("chain_list_service");
    cacheFile = File("${cacheRoot.path}/chainlist_mainnets.json");
    PathProviderPlatform.instance = _FakePathProviderPlatform(cacheRoot.path);

    CakeTor.instance = CakeTorDisabled();

    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requestedUrls.add("${request.headers.host}${request.uri}");
      request.response
        ..statusCode = feedStatus
        ..write(feedBody);
      await request.response.close();
    });
    HttpOverrides.global = _LocalServerOverrides(server.port);
  });

  tearDownAll(() async {
    HttpOverrides.global = null;
    await server.close(force: true);
    cacheRoot.deleteSync(recursive: true);
  });

  setUp(() {
    requestedUrls = [];
    feedStatus = HttpStatus.ok;
    feedBody = "[]";
    if (cacheFile.existsSync()) {
      cacheFile.deleteSync();
    }
  });

  group("parseChainListFeed", () {
    test("maps a feed item into an entry", () {
      final entries = parseChainListFeed(
        jsonEncode([
          _feedItem(
            explorers: [
              {"name": "blockscout", "url": "https://explorer.inkonchain.com"},
            ],
            chainSlug: "ink",
          ),
        ]),
      );

      final entry = entries.single;
      expect(entry.chainId, 57073);
      expect(entry.name, "Ink");
      expect(entry.shortName, "ink");
      expect(entry.symbol, "ETH");
      expect(entry.decimals, 18);
      expect(entry.rpcUrls, ["https://rpc-gel.inkonchain.com"]);
      expect(entry.explorerUrl, "https://explorer.inkonchain.com");
      expect(entry.iconUrl, "https://icons.llamao.fi/icons/chains/rsz_ink.jpg");
    });

    test("keeps a non-18 decimals value from the feed", () {
      final entries = parseChainListFeed(
        jsonEncode([
          _feedItem(nativeCurrency: {"symbol": "XDAI6", "decimals": 6}),
        ]),
      );

      expect(entries.single.decimals, 6);
    });

    test("drops testnets, whichever flag the feed uses", () {
      final entries = parseChainListFeed(
        jsonEncode([
          _feedItem(chainId: 763373, isTestnet: true),
          {..._feedItem(chainId: 11155111), "testnet": true},
          _feedItem(chainId: 57073),
        ]),
      );

      expect(entries.map((entry) => entry.chainId), [57073]);
    });

    test("drops items without a positive int chain ID, a name or a native currency", () {
      final entries = parseChainListFeed(
        jsonEncode([
          _feedItem(chainId: "57073"),
          _feedItem(chainId: 0),
          _feedItem(chainId: -5),
          _feedItem(chainId: null),
          _feedItem(chainId: 1001, name: null),
          _feedItem(chainId: 1002, name: 42),
          _feedItem(chainId: 1003, nativeCurrency: null),
          _feedItem(chainId: 1004, nativeCurrency: "ETH"),
          _feedItem(chainId: 1005, nativeCurrency: {"symbol": 5, "decimals": 18}),
          _feedItem(chainId: 1006, nativeCurrency: {"symbol": "ETH", "decimals": "18"}),
          _feedItem(chainId: 1007, nativeCurrency: {"symbol": "ETH"}),
          _feedItem(chainId: 196),
        ]),
      );

      expect(entries.map((entry) => entry.chainId), [196]);
    });

    test("drops decimals outside 0 to 36 and a blank symbol, keeping both edges", () {
      final entries = parseChainListFeed(
        jsonEncode([
          _feedItem(chainId: 2001, nativeCurrency: {"symbol": "LOW", "decimals": -1}),
          _feedItem(chainId: 2002, nativeCurrency: {"symbol": "HIGH", "decimals": 37}),
          _feedItem(chainId: 2003, nativeCurrency: {"symbol": "", "decimals": 18}),
          _feedItem(chainId: 2004, nativeCurrency: {"symbol": "   ", "decimals": 18}),
          _feedItem(chainId: 2005, nativeCurrency: {"symbol": "ZERO", "decimals": 0}),
          _feedItem(chainId: 2006, nativeCurrency: {"symbol": "MAX", "decimals": 36}),
        ]),
      );

      expect(entries.map((entry) => entry.chainId), [2005, 2006]);
    });

    test("trims the name, cuts it to the form's 32 characters and drops a blank one", () {
      final entries = parseChainListFeed(
        jsonEncode([
          _feedItem(chainId: 3001, name: "  Padded Chain  "),
          _feedItem(chainId: 3002, name: "A Network Name That Runs Well Past Thirty Two"),
          _feedItem(chainId: 3003, name: "   "),
        ]),
      );

      expect(entries.map((entry) => entry.name), [
        "Padded Chain",
        "A Network Name That Runs Well Pa",
      ]);
      expect(entries[1].name.length, maxNetworkNameLength);
    });

    test("an emoji at the 32nd character is kept whole, never split into half a pair", () {
      final entries = parseChainListFeed(
        jsonEncode([
          _feedItem(chainId: 3004, name: "${"x" * 31}\u{1F680} Mainnet"),
        ]),
      );

      expect(entries.single.name, "${"x" * 31}\u{1F680}");
      expect(entries.single.name.length, 33);
    });

    test("skips feed items that are not objects", () {
      final entries = parseChainListFeed(jsonEncode([42, "chain", null, _feedItem()]));

      expect(entries.map((entry) => entry.chainId), [57073]);
    });

    test("keeps only https RPCs without key templates, and drops an item left with none", () {
      final entries = parseChainListFeed(
        jsonEncode([
          _feedItem(
            chainId: 25,
            rpc: [
              "http://plain.example",
              "wss://socket.example",
              r"https://mainnet.infura.io/v3/${INFURA_API_KEY}",
              {"url": "https://kept.example", "tracking": "yes"},
              {"tracking": "none"},
              7,
            ],
          ),
          _feedItem(chainId: 26, rpc: ["http://only-plain.example"]),
          _feedItem(chainId: 27, rpc: []),
          {..._feedItem(chainId: 28), "rpc": null},
        ]),
      );

      expect(entries.map((entry) => entry.chainId), [25]);
      expect(entries.single.rpcUrls, ["https://kept.example"]);
    });

    test("an item whose rpc is not a list is dropped, the rest of the feed stays", () {
      final entries = parseChainListFeed(
        jsonEncode([
          {..._feedItem(chainId: 30), "rpc": "https://string.example"},
          {
            ..._feedItem(chainId: 31),
            "rpc": {"url": "https://map.example"},
          },
          _feedItem(chainId: 196),
        ]),
      );

      expect(entries.map((entry) => entry.chainId), [196]);
    });

    test("an explorer that is not https is dropped, the entry stays", () {
      final entries = parseChainListFeed(
        jsonEncode([
          _feedItem(
            explorers: [
              {"name": "plain", "url": "http://explorer.example"},
            ],
          ),
        ]),
      );

      expect(entries.single.explorerUrl, isNull);
    });

    test("a shortName or explorer url that is not a string reads as absent, the entry stays", () {
      final entries = parseChainListFeed(
        jsonEncode([
          _feedItem(
            chainId: 57073,
            shortName: 42,
            explorers: [
              {"name": "odd", "url": 7},
            ],
          ),
          _feedItem(chainId: 196),
        ]),
      );

      expect(entries.map((entry) => entry.chainId), [57073, 196]);
      expect(entries.first.shortName, "");
      expect(entries.first.explorerUrl, isNull);
    });

    test("without a slug the icon field names the icon, with neither there is no icon", () {
      final entries = parseChainListFeed(
        jsonEncode([
          _feedItem(chainId: 25, icon: "cronos"),
          _feedItem(chainId: 196, chainSlug: "", icon: null),
        ]),
      );

      expect(entries.first.iconUrl, "https://icons.llamao.fi/icons/chains/rsz_cronos.jpg");
      expect(entries.last.iconUrl, isNull);
    });

    test("reads tvl as a number, and a missing, null or non-number tvl as null", () {
      final entries = parseChainListFeed(
        jsonEncode([
          _feedItem(chainId: 4001, tvl: 12345),
          _feedItem(chainId: 4002, tvl: 0.5),
          _feedItem(chainId: 4003),
          {..._feedItem(chainId: 4004), "tvl": null},
          _feedItem(chainId: 4005, tvl: "12345"),
        ]),
      );

      expect(entries.map((entry) => entry.tvl), [12345.0, 0.5, null, null, null]);
    });

    test("the first item for a chain ID wins", () {
      final entries = parseChainListFeed(
        jsonEncode([
          _feedItem(name: "Ink"),
          _feedItem(name: "Ink Copy"),
        ]),
      );

      expect(entries.map((entry) => entry.name), ["Ink"]);
    });

    test("a feed that is not a list throws", () {
      expect(() => parseChainListFeed(jsonEncode({"chains": []})), throwsA(isA<TypeError>()));
      expect(() => parseChainListFeed("<html>"), throwsFormatException);
    });
  });

  group("fetch and the cache", () {
    test("fetches the feed from chainlist.org and saves what it parsed", () async {
      feedBody = jsonEncode([
        _feedItem(chainId: 57073, name: "Ink"),
        _feedItem(chainId: 25, name: "Cronos"),
        _feedItem(chainId: 11155111, isTestnet: true),
      ]);
      final before = DateTime.now();

      final snapshot = await ChainListService().fetch();

      expect(requestedUrls, ["chainlist.org/rpcs.json"]);
      expect(snapshot.entries.map((entry) => entry.chainId), [57073, 25]);
      expect(snapshot.fetchedAt.isBefore(before), isFalse);
      expect(cacheFile.existsSync(), isTrue);
    });

    test("the saved copy reads back with the same entries and date", () async {
      feedBody = jsonEncode([
        _feedItem(
          chainId: 57073,
          rpc: [
            {"url": trackedRpc, "tracking": "yes"},
            plainRpc,
            {"url": untrackedRpc, "tracking": "none"},
          ],
          explorers: [
            {"url": "https://explorer.inkonchain.com"},
          ],
          chainSlug: "ink",
        ),
      ]);
      final fetched = await ChainListService().fetch();

      final cached = await ChainListService().readCache();

      expect(cached, isNotNull);
      expect(
        cached!.fetchedAt.millisecondsSinceEpoch,
        fetched.fetchedAt.millisecondsSinceEpoch,
      );
      final entry = cached.entries.single;
      expect(entry.rpcUrls, [untrackedRpc, trackedRpc, plainRpc]);
      expect(entry.explorerUrl, "https://explorer.inkonchain.com");
      expect(entry.iconUrl, "https://icons.llamao.fi/icons/chains/rsz_ink.jpg");
      expect(entry.shortName, "ink");
      expect(entry.symbol, "ETH");
    });

    test("tvl survives the saved copy, and a network without one reads back as null", () async {
      feedBody = jsonEncode([
        _feedItem(chainId: 57073, tvl: 98765.25),
        _feedItem(chainId: 25),
      ]);
      await ChainListService().fetch();

      final cached = await ChainListService().readCache();

      expect(cached!.entries.map((entry) => entry.tvl), [98765.25, null]);
    });

    test("a failed fetch throws and leaves the saved copy as it was", () async {
      feedBody = jsonEncode([_feedItem(chainId: 57073)]);
      final saved = await ChainListService().fetch();
      feedStatus = HttpStatus.serviceUnavailable;
      feedBody = jsonEncode([_feedItem(chainId: 25)]);

      await expectLater(ChainListService().fetch(), throwsException);

      final cached = await ChainListService().readCache();
      expect(cached!.entries.map((entry) => entry.chainId), [57073]);
      expect(cached.fetchedAt.millisecondsSinceEpoch, saved.fetchedAt.millisecondsSinceEpoch);
    });

    test("a feed with no mainnets throws and saves nothing", () async {
      feedBody = jsonEncode([_feedItem(chainId: 11155111, isTestnet: true)]);

      await expectLater(ChainListService().fetch(), throwsException);

      expect(cacheFile.existsSync(), isFalse);
      expect(await ChainListService().readCache(), isNull);
    });

    test("a body that is not JSON throws and saves nothing", () async {
      feedBody = "<html>rate limited</html>";

      await expectLater(ChainListService().fetch(), throwsA(anything));

      expect(cacheFile.existsSync(), isFalse);
    });

    test("with no saved copy the cache reads as null", () async {
      expect(await ChainListService().readCache(), isNull);
    });

    test("a broken saved copy reads as null instead of throwing", () async {
      cacheFile.writeAsStringSync("{\"fetchedAt\": \"yesterday\", \"entries\": 3}");

      expect(await ChainListService().readCache(), isNull);
    });

    test("a bad or RPC-less entry in the saved copy is skipped, the others still read", () async {
      final good = const ChainListEntry(
        chainId: 57073,
        name: "Ink",
        shortName: "ink",
        symbol: "ETH",
        decimals: 18,
        rpcUrls: ["https://rpc-gel.inkonchain.com"],
      ).toJson();
      cacheFile.writeAsStringSync(
        jsonEncode({
          "fetchedAt": 1700000000000,
          "entries": [
            {...good, "chainId": 30, "rpc": "https://string.example"},
            {
              ...good,
              "chainId": 31,
              "rpc": {"url": "https://map.example"},
            },
            42,
            {...good, "chainId": 32, "rpc": <String>[]},
            good,
          ],
        }),
      );

      final cached = await ChainListService().readCache();

      expect(cached!.entries.map((entry) => entry.chainId), [57073]);
      expect(cached.fetchedAt.millisecondsSinceEpoch, 1700000000000);
    });

    test("a truncated saved copy reads as null", () async {
      cacheFile.writeAsStringSync("{\"fetchedAt\": 1700000000000, \"entries\": [");

      expect(await ChainListService().readCache(), isNull);
    });
  });

  group("loadPopularNetworks", () {
    test("reads the bundled list offline, with no request", () async {
      final entries = await ChainListService().loadPopularNetworks();

      expect(requestedUrls, isEmpty);
      expect(entries, hasLength(8));
      expect(entries.every((entry) => entry.iconUrl!.startsWith("assets/")), isTrue);
      expect(entries.every((entry) => entry.tvl == null), isTrue);
    });

    test("keeps each network's RPCs in the order they were written", () async {
      final entries = await ChainListService().loadPopularNetworks();

      final hyperEvm = entries.singleWhere((entry) => entry.chainId == 999);
      expect(hyperEvm.rpcUrls, [
        "https://rpc.hyperliquid.xyz/evm",
        "https://hyperliquid-rpc.publicnode.com",
      ]);
      expect(hyperEvm.shortName, "hyper_evm");
    });
  });

  group("ChainListEntry.fromJson", () {
    test("a bundled entry keeps a tracked first RPC first", () {
      final entry = ChainListEntry.fromJson({
        "chainId": 999,
        "name": "HyperEVM",
        "symbol": "HYPE",
        "decimals": 18,
        "rpc": [
          {"url": trackedRpc, "tracking": "yes"},
          {"url": untrackedRpc, "tracking": "none"},
        ],
      });

      expect(entry.rpcUrls, [trackedRpc, untrackedRpc]);
    });

    test("a saved tvl that is not a number reads as null", () {
      final entry = ChainListEntry.fromJson({
        "chainId": 57073,
        "name": "Ink",
        "symbol": "ETH",
        "rpc": [plainRpc],
        "tvl": "98765",
      });

      expect(entry.tvl, isNull);
    });
  });
}
