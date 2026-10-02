import "dart:convert";
import "dart:io";

import "package:cake_wallet/entities/contact.dart";
import "package:cake_wallet/entities/preferences_key.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/new-ui/services/chain_list_service.dart";
import "package:cake_wallet/new-ui/services/evm_network_service.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/db/sqlite.dart";
import "package:cw_core/evm_network.dart";
import "package:cw_core/node.dart";
import "package:cw_core/utils/proxy_wrapper.dart";
import "package:cw_core/utils/tor/disabled.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hive/hive.dart";
import "package:mocktail/mocktail.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../helpers/test_db.dart";

class _MockSettingsStore extends Mock implements SettingsStore {}

class _MockContactBox extends Mock implements Box<Contact> {}

Future<void> main() async {
  final dataRoot = Directory("./test/data/evm_network_service");

  // Not built-in chains, each test uses its own so a leftover registration cannot pass a test
  const opChainId = 10;
  const inkChainId = 57073;
  const cronosChainId = 25;
  const otherChainId = 137;

  late HttpServer server;
  late List<String> requestedPaths;
  late _MockSettingsStore settingsStore;
  late _MockContactBox contacts;
  late SharedPreferences sharedPreferences;
  late EvmNetworkService service;

  // The path says what the fake RPC does: /answers/<chainId>/<label> or /dead/<label>
  String answering(int chainId, String label) =>
      "http://127.0.0.1:${server.port}/answers/$chainId/$label";
  String dead(String label) => "http://127.0.0.1:${server.port}/dead/$label";

  EvmNetwork network(
    int chainId, {
    required String rpcUrl,
    String? failoverUrl,
    String name = "Network",
    String symbol = "NET",
    String tag = "NET",
    bool isManual = false,
    bool isEnabled = false,
  }) =>
      EvmNetwork(
        chainId: chainId,
        name: name,
        symbol: symbol,
        decimals: 18,
        tag: tag,
        rpcUrl: rpcUrl,
        failoverUrl: failoverUrl,
        isManual: isManual,
        isEnabled: isEnabled,
      );

  Future<void> insertEvmWallet(String name, int chainId) => db!.insert("WalletInfo", {
        "id": "evm_$name",
        "name": name,
        "type": WalletType.evm.index,
        "isRecovery": 0,
        "restoreHeight": 0,
        "timestamp": 0,
        "dirPath": "",
        "path": "",
        "address": "",
        "showIntroCakePayCard": 0,
        "walletInfoDerivationInfoId": 0,
        "isNonSeedWallet": 0,
        "sortOrder": 0,
        "receiveInfoboxDismissed": 0,
        "showCombinedBalance": 1,
        "chainId": chainId,
      });

  Future<List<String>> getNodeUrls(int chainId) async =>
      (await Node.getAllForEvmChain(chainId)).map((node) => node.uri.toString()).toList();

  setUpAll(() async {
    await setUpTestDb(dataRoot);

    CakeTor.instance = CakeTorDisabled();

    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final segments = request.uri.pathSegments;
      final method = jsonDecode(await utf8.decoder.bind(request).join())["method"];

      // Each check asks eth_chainId first, so this records every RPC that was tried once
      if (method == "eth_chainId") {
        requestedPaths.add(request.uri.path);
      }

      if (segments.first == "answers" ||
          (segments.first == "chain-id-only" && method == "eth_chainId")) {
        final chainId = int.parse(segments[1]);
        request.response.write(
          jsonEncode({"jsonrpc": "2.0", "id": 1, "result": "0x${chainId.toRadixString(16)}"}),
        );
      } else if (segments.first == "chain-id-only") {
        request.response.write(
          jsonEncode({
            "jsonrpc": "2.0",
            "id": 1,
            "error": {"code": 35, "message": "chain is not available on free plan"},
          }),
        );
      } else {
        request.response.statusCode = HttpStatus.internalServerError;
      }

      await request.response.close();
    });
  });

  tearDownAll(() async {
    await server.close(force: true);
    if (dataRoot.existsSync()) {
      dataRoot.deleteSync(recursive: true);
    }
  });

  setUp(() async {
    requestedPaths = [];
    await db!.delete(EvmNetwork.tableName);
    await db!.delete(Node.tableName);
    await db!.delete("WalletInfo");
    await evm!.loadNetworks();

    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();

    settingsStore = _MockSettingsStore();
    when(() => settingsStore.loadEvmNetworks()).thenAnswer((_) async {});
    contacts = _MockContactBox();
    when(() => contacts.values).thenReturn(const []);

    service = EvmNetworkService(settingsStore, sharedPreferences, contacts);
  });

  group("checkRpc", () {
    test("passes when the RPC answers the expected chain", () async {
      final url = answering(opChainId, "rpc");

      await service.checkRpc(url, opChainId);

      expect(requestedPaths, ["/answers/$opChainId/rpc"]);
    });

    test("an RPC on another chain throws a mismatch naming both chains", () async {
      final url = answering(otherChainId, "rpc");

      await expectLater(
        service.checkRpc(url, opChainId),
        throwsA(
          isA<RpcChainIdMismatchException>()
              .having((e) => e.url, "url", url)
              .having((e) => e.answeredChainId, "answeredChainId", otherChainId)
              .having((e) => e.expectedChainId, "expectedChainId", opChainId),
        ),
      );
    });

    test("an RPC that does not answer throws no-answer, not a mismatch", () async {
      final url = dead("rpc");

      await expectLater(
        service.checkRpc(url, opChainId),
        throwsA(isA<RpcNoAnswerException>().having((e) => e.url, "url", url)),
      );
    });

    test("an RPC that answers its chain but refuses eth_blockNumber throws no-answer", () async {
      final url = "http://127.0.0.1:${server.port}/chain-id-only/$opChainId/rpc";

      await expectLater(
        service.checkRpc(url, opChainId),
        throwsA(isA<RpcNoAnswerException>().having((e) => e.url, "url", url)),
      );
    });
  });

  group("enable", () {
    test("checks the RPC and failover, then saves, writes nodes, registers and reloads", () async {
      final rpcUrl = answering(opChainId, "rpc");
      final failoverUrl = answering(opChainId, "failover");
      final before = DateTime.now().millisecondsSinceEpoch;

      final enabled = await service.enable(
        network(opChainId, rpcUrl: rpcUrl, failoverUrl: failoverUrl, name: "OP Mainnet"),
      );

      expect(requestedPaths, ["/answers/$opChainId/rpc", "/answers/$opChainId/failover"]);
      expect(enabled.isEnabled, isTrue);
      expect(enabled.enabledAt, greaterThanOrEqualTo(before));

      final saved = await EvmNetwork.get(opChainId);
      expect(saved!.isEnabled, isTrue);
      expect(saved.rpcUrl, rpcUrl);
      expect(await getNodeUrls(opChainId), unorderedEquals([rpcUrl, failoverUrl]));
      expect((await Node.getDefaultForEvmChain(opChainId))!.uri.toString(), rpcUrl);

      final chain = evm!.getChainInfoByChainId(opChainId);
      expect(chain!.source, ChainSource.chainlist);
      expect(chain.name, "OP Mainnet");
      verify(() => settingsStore.loadEvmNetworks()).called(1);
    });

    test("a failover on another chain refuses the enable and writes nothing", () async {
      final failoverUrl = answering(otherChainId, "failover");

      await expectLater(
        service.enable(
          network(opChainId, rpcUrl: answering(opChainId, "rpc"), failoverUrl: failoverUrl),
        ),
        throwsA(
          isA<RpcChainIdMismatchException>()
              .having((e) => e.url, "url", failoverUrl)
              .having((e) => e.answeredChainId, "answeredChainId", otherChainId),
        ),
      );

      expect(await EvmNetwork.get(opChainId), isNull);
      expect(await Node.getAllForEvmChain(opChainId), isEmpty);
      expect(evm!.getChainInfoByChainId(opChainId), isNull);
      verifyNever(() => settingsStore.loadEvmNetworks());
    });

    test("enabling saves the two candidates that answer as RPC, failover and node rows", () async {
      final firstAnswering = answering(inkChainId, "second");
      final secondAnswering = answering(inkChainId, "third");

      final enabled = await service.enable(
        network(inkChainId, rpcUrl: dead("first"), failoverUrl: firstAnswering),
        rpcCandidates: [dead("first"), firstAnswering, secondAnswering],
      );

      expect(enabled.rpcUrl, firstAnswering);
      expect(enabled.failoverUrl, secondAnswering);
      expect((await EvmNetwork.get(inkChainId))!.rpcUrl, firstAnswering);
      expect(await getNodeUrls(inkChainId), unorderedEquals([firstAnswering, secondAnswering]));
    });

    test("re-enabling on the same RPCs keeps the node rows the user may have added", () async {
      final rpcUrl = answering(opChainId, "rpc");
      final enabled = await service.enable(network(opChainId, rpcUrl: rpcUrl));
      await service.disable(enabled);
      final userNode = EvmNetwork.rpcNode(answering(opChainId, "user"), opChainId);
      await userNode.save();

      await service.enable(enabled);

      expect(
        await getNodeUrls(opChainId),
        unorderedEquals([rpcUrl, answering(opChainId, "user")]),
      );
    });

    test("a walk that moved off the stored RPCs replaces the old node rows", () async {
      final staleUrl = dead("stale");
      await EvmNetwork.rpcNode(staleUrl, inkChainId, isDefault: true).save();
      final answeringUrl = answering(inkChainId, "fresh");

      await service.enable(
        network(inkChainId, rpcUrl: staleUrl),
        rpcCandidates: [staleUrl, answeringUrl],
      );

      expect(await getNodeUrls(inkChainId), [answeringUrl]);
    });

    test("a walk that moved off the stored RPCs keeps the node rows the user added", () async {
      final staleUrl = dead("stale");
      await EvmNetwork.rpcNode(staleUrl, inkChainId, isDefault: true).save();
      final userUrl = answering(inkChainId, "user");
      await EvmNetwork.rpcNode(userUrl, inkChainId).save();
      final answeringUrl = answering(inkChainId, "fresh");

      await service.enable(
        network(inkChainId, rpcUrl: staleUrl),
        rpcCandidates: [staleUrl, answeringUrl],
      );

      expect(await getNodeUrls(inkChainId), unorderedEquals([answeringUrl, userUrl]));
    });

    test("a tag that is a built-in currency's gets the chain ID appended", () async {
      final enabled = await service.enable(
        network(opChainId, rpcUrl: answering(opChainId, "rpc"), symbol: "ETH", tag: "ETH"),
      );

      expect(enabled.tag, "ETH-$opChainId");
      expect((await EvmNetwork.get(opChainId))!.tag, "ETH-$opChainId");
    });
  });

  group("disable", () {
    test("is refused while a wallet uses the network, with the counts", () async {
      final enabled = await service.enable(network(opChainId, rpcUrl: answering(opChainId, "a")));
      await insertEvmWallet("op wallet", opChainId);
      await insertEvmWallet("second op wallet", opChainId);
      when(() => contacts.values).thenReturn([
        Contact(
          name: "friend",
          address: "0x1",
          type: EvmNativeCurrencies.getNativeCurrencyByChainId(opChainId),
        ),
      ]);

      await expectLater(
        service.disable(enabled),
        throwsA(
          isA<NetworkInUseException>()
              .having((e) => e.walletCount, "walletCount", 2)
              .having((e) => e.contactCount, "contactCount", 1),
        ),
      );
      expect((await EvmNetwork.get(opChainId))!.isEnabled, isTrue);
      expect(evm!.getChainInfoByChainId(opChainId), isNotNull);
    });

    test("keeps the row, its nodes and its currency but drops the chain", () async {
      final rpcUrl = answering(opChainId, "rpc");
      final enabled = await service.enable(network(opChainId, rpcUrl: rpcUrl));
      final currency = EvmNativeCurrencies.getNativeCurrencyByChainId(opChainId);

      final disabled = await service.disable(enabled);

      expect(disabled.isEnabled, isFalse);
      expect((await EvmNetwork.get(opChainId))!.isEnabled, isFalse);
      expect(await getNodeUrls(opChainId), [rpcUrl]);
      expect(evm!.getChainInfoByChainId(opChainId), isNull);
      expect(currency, isNotNull);
      expect(EvmNativeCurrencies.getNativeCurrencyByChainId(opChainId), same(currency));
      expect(
        CryptoCurrency.safeDeserialize(raw: EvmNativeCurrencies.addedNetworkRaw(opChainId)),
        same(currency),
      );
    });

    test("a wallet on another added chain does not block it", () async {
      final enabled = await service.enable(network(opChainId, rpcUrl: answering(opChainId, "a")));
      await insertEvmWallet("ink wallet", inkChainId);

      final disabled = await service.disable(enabled);

      expect(disabled.isEnabled, isFalse);
    });
  });

  group("save", () {
    test("adding checks the RPC and writes the row, nodes and registration", () async {
      final rpcUrl = answering(cronosChainId, "rpc");

      final saved = await service.save(
        network(cronosChainId, rpcUrl: rpcUrl, name: "Cronos", isManual: true, isEnabled: true),
      );

      expect(requestedPaths, ["/answers/$cronosChainId/rpc"]);
      expect(saved.isManual, isTrue);
      expect(await getNodeUrls(cronosChainId), [rpcUrl]);
      expect(evm!.getChainInfoByChainId(cronosChainId)!.source, ChainSource.manual);
      verify(() => settingsStore.loadEvmNetworks()).called(1);
    });

    test("adding with an RPC on another chain throws and writes nothing", () async {
      await expectLater(
        service.save(network(cronosChainId, rpcUrl: answering(otherChainId, "rpc"))),
        throwsA(isA<RpcChainIdMismatchException>()),
      );

      expect(await EvmNetwork.get(cronosChainId), isNull);
      expect(await Node.getAllForEvmChain(cronosChainId), isEmpty);
    });

    test("a rename with the same RPCs saves without an RPC check", () async {
      final rpcUrl = answering(cronosChainId, "rpc");
      final previous = await service.save(network(cronosChainId, rpcUrl: rpcUrl, isEnabled: true));
      requestedPaths.clear();

      await service.save(
        network(cronosChainId, rpcUrl: rpcUrl, name: "Renamed", isEnabled: true),
        previous: previous,
      );

      expect(requestedPaths, isEmpty);
      expect((await EvmNetwork.get(cronosChainId))!.name, "Renamed");
      expect(EvmNativeCurrencies.getNativeCurrencyByChainId(cronosChainId)!.fullName, "Renamed");
    });

    test("a changed failover is checked and replaces the node rows", () async {
      final rpcUrl = answering(cronosChainId, "rpc");
      final previous = await service.save(network(cronosChainId, rpcUrl: rpcUrl, isEnabled: true));
      requestedPaths.clear();
      final failoverUrl = answering(cronosChainId, "failover");

      await service.save(
        network(cronosChainId, rpcUrl: rpcUrl, failoverUrl: failoverUrl, isEnabled: true),
        previous: previous,
      );

      expect(requestedPaths, ["/answers/$cronosChainId/rpc", "/answers/$cronosChainId/failover"]);
      expect(await getNodeUrls(cronosChainId), unorderedEquals([rpcUrl, failoverUrl]));
    });

    test("a changed RPC on a network with wallets keeps the wallets' node rows", () async {
      final rpcUrl = answering(cronosChainId, "rpc");
      final previous = await service.save(network(cronosChainId, rpcUrl: rpcUrl, isEnabled: true));
      await insertEvmWallet("cronos wallet", cronosChainId);

      await service.save(
        network(cronosChainId, rpcUrl: answering(cronosChainId, "new"), isEnabled: true),
        previous: previous,
      );

      expect(await getNodeUrls(cronosChainId), [rpcUrl]);
      expect((await EvmNetwork.get(cronosChainId))!.rpcUrl, rpcUrl);
    });

    test("a network with wallets keeps its tag even when renamed onto a clash", () async {
      final rpcUrl = answering(cronosChainId, "rpc");
      final previous = await service.save(
        network(cronosChainId, rpcUrl: rpcUrl, tag: "MYCRO", isEnabled: true),
      );
      await insertEvmWallet("cronos wallet", cronosChainId);

      final saved = await service.save(
        network(cronosChainId, rpcUrl: rpcUrl, tag: "BSC", isEnabled: true),
        previous: previous,
      );

      expect(saved.tag, "MYCRO");
    });

    test("a tag equal to another saved network's symbol gets the chain ID appended", () async {
      await service.save(
        network(opChainId, rpcUrl: answering(opChainId, "rpc"), symbol: "OPX", tag: "OPNET"),
      );

      final saved = await service.save(
        network(cronosChainId, rpcUrl: answering(cronosChainId, "rpc"), tag: "opx"),
      );

      expect(saved.tag, "opx-$cronosChainId");
    });

    test("a chain ID change removes the old row, its nodes and its registration", () async {
      final oldRpcUrl = answering(cronosChainId, "old");
      final previous = await service.save(
        network(cronosChainId, rpcUrl: oldRpcUrl, isManual: true, isEnabled: true),
      );
      await sharedPreferences.setInt(PreferencesKey.currentEvmChainNodeIdKey(cronosChainId), 1);
      final newRpcUrl = answering(inkChainId, "new");

      await service.save(
        network(inkChainId, rpcUrl: newRpcUrl, isManual: true, isEnabled: true),
        previous: previous,
      );

      expect(await EvmNetwork.get(cronosChainId), isNull);
      expect(await Node.getAllForEvmChain(cronosChainId), isEmpty);
      expect(evm!.getChainInfoByChainId(cronosChainId), isNull);
      expect(EvmNativeCurrencies.getNativeCurrencyByChainId(cronosChainId), isNull);
      expect(
        sharedPreferences.getInt(PreferencesKey.currentEvmChainNodeIdKey(cronosChainId)),
        isNull,
      );
      expect(await getNodeUrls(inkChainId), [newRpcUrl]);
      expect(evm!.getChainInfoByChainId(inkChainId), isNotNull);
    });

    test("a chain ID change is refused while a wallet uses the old chain", () async {
      final previous = await service.save(
        network(cronosChainId, rpcUrl: answering(cronosChainId, "old"), isManual: true),
      );
      await insertEvmWallet("cronos wallet", cronosChainId);
      requestedPaths.clear();

      await expectLater(
        service.save(
          network(inkChainId, rpcUrl: answering(inkChainId, "new"), isManual: true),
          previous: previous,
        ),
        throwsA(
          isA<NetworkInUseException>()
              .having((e) => e.walletCount, "walletCount", 1)
              .having((e) => e.contactCount, "contactCount", 0),
        ),
      );

      expect(requestedPaths, isEmpty);
      expect(await EvmNetwork.get(cronosChainId), isNotNull);
      expect(await Node.getAllForEvmChain(cronosChainId), isNotEmpty);
      expect(await EvmNetwork.get(inkChainId), isNull);
    });

    test("a chain ID change is refused while a contact holds the old chain's currency", () async {
      final previous = await service.save(
        network(cronosChainId, rpcUrl: answering(cronosChainId, "old"), isManual: true),
      );
      when(() => contacts.values).thenReturn([
        Contact(
          name: "friend",
          address: "0x1",
          type: EvmNativeCurrencies.getNativeCurrencyByChainId(cronosChainId),
        ),
      ]);

      await expectLater(
        service.save(
          network(inkChainId, rpcUrl: answering(inkChainId, "new"), isManual: true),
          previous: previous,
        ),
        throwsA(
          isA<NetworkInUseException>()
              .having((e) => e.walletCount, "walletCount", 0)
              .having((e) => e.contactCount, "contactCount", 1),
        ),
      );

      expect(await EvmNetwork.get(cronosChainId), isNotNull);
      expect(await EvmNetwork.get(inkChainId), isNull);
    });

    test("a symbol change with no wallets rebuilds the cached currency", () async {
      final rpcUrl = answering(cronosChainId, "rpc");
      final previous = await service.save(
        network(cronosChainId, rpcUrl: rpcUrl, symbol: "OLD", tag: "SAMETAG", isEnabled: true),
      );
      final oldCurrency = EvmNativeCurrencies.getNativeCurrencyByChainId(cronosChainId);

      await service.save(
        network(cronosChainId, rpcUrl: rpcUrl, symbol: "NEW", tag: "SAMETAG", isEnabled: true),
        previous: previous,
      );

      final newCurrency = EvmNativeCurrencies.getNativeCurrencyByChainId(cronosChainId);
      expect(newCurrency, isNot(same(oldCurrency)));
      expect(newCurrency!.title, "NEW");
      expect(oldCurrency!.title, "OLD");
    });

    test("a rename that moves the tag with no wallets rebuilds the cached currency", () async {
      final rpcUrl = answering(cronosChainId, "rpc");
      final previous = await service.save(
        network(cronosChainId, rpcUrl: rpcUrl, name: "Old", tag: "OLDTAG", isEnabled: true),
      );
      final oldCurrency = EvmNativeCurrencies.getNativeCurrencyByChainId(cronosChainId);

      await service.save(
        network(cronosChainId, rpcUrl: rpcUrl, name: "New", tag: "NEWTAG", isEnabled: true),
        previous: previous,
      );

      final newCurrency = EvmNativeCurrencies.getNativeCurrencyByChainId(cronosChainId);
      expect((await EvmNetwork.get(cronosChainId))!.tag, "NEWTAG");
      expect(newCurrency, isNot(same(oldCurrency)));
      expect(newCurrency!.tag, "NEWTAG");
      expect(oldCurrency!.tag, "OLDTAG");
    });

    test("a rename on a network with wallets keeps the wallets' currency and tag", () async {
      final rpcUrl = answering(cronosChainId, "rpc");
      final previous = await service.save(
        network(
          cronosChainId,
          rpcUrl: rpcUrl,
          name: "Old",
          symbol: "OLD",
          tag: "OLDTAG",
          isEnabled: true,
        ),
      );
      final walletCurrency = EvmNativeCurrencies.getNativeCurrencyByChainId(cronosChainId);
      await insertEvmWallet("cronos wallet", cronosChainId);

      await service.save(
        network(
          cronosChainId,
          rpcUrl: rpcUrl,
          name: "New",
          symbol: "NEW",
          tag: "NEWTAG",
          isEnabled: true,
        ),
        previous: previous,
      );

      expect(EvmNativeCurrencies.getNativeCurrencyByChainId(cronosChainId), same(walletCurrency));
      expect(walletCurrency!.tag, "OLDTAG");
      expect(walletCurrency.title, "OLD");

      final saved = (await EvmNetwork.get(cronosChainId))!;
      expect(saved.name, "New");
      expect(saved.symbol, "OLD");
      expect(saved.tag, "OLDTAG");
    });
  });

  group("delete", () {
    test("is refused while a wallet uses the network", () async {
      final saved = await service.save(
        network(cronosChainId, rpcUrl: answering(cronosChainId, "rpc"), isManual: true),
      );
      await insertEvmWallet("cronos wallet", cronosChainId);

      await expectLater(
        service.delete(saved),
        throwsA(
          isA<NetworkInUseException>()
              .having((e) => e.walletCount, "walletCount", 1)
              .having((e) => e.contactCount, "contactCount", 0),
        ),
      );
      expect(await EvmNetwork.get(cronosChainId), isNotNull);
    });

    test("is refused while a contact holds the network's currency", () async {
      final saved = await service.save(
        network(cronosChainId, rpcUrl: answering(cronosChainId, "rpc"), isManual: true),
      );
      when(() => contacts.values).thenReturn([
        Contact(
          name: "friend",
          address: "0x1",
          type: EvmNativeCurrencies.getNativeCurrencyByChainId(cronosChainId),
        ),
      ]);

      await expectLater(
        service.delete(saved),
        throwsA(
          isA<NetworkInUseException>()
              .having((e) => e.walletCount, "walletCount", 0)
              .having((e) => e.contactCount, "contactCount", 1),
        ),
      );
      expect(await EvmNetwork.get(cronosChainId), isNotNull);
    });

    test("removes the row, nodes, current node preference, chain and currency", () async {
      final saved = await service.save(
        network(cronosChainId, rpcUrl: answering(cronosChainId, "rpc"), isManual: true),
      );
      await sharedPreferences.setInt(PreferencesKey.currentEvmChainNodeIdKey(cronosChainId), 7);
      clearInteractions(settingsStore);

      await service.delete(saved);

      expect(await EvmNetwork.get(cronosChainId), isNull);
      expect(await Node.getAllForEvmChain(cronosChainId), isEmpty);
      expect(
        sharedPreferences.getInt(PreferencesKey.currentEvmChainNodeIdKey(cronosChainId)),
        isNull,
      );
      expect(evm!.getChainInfoByChainId(cronosChainId), isNull);
      expect(EvmNativeCurrencies.getNativeCurrencyByChainId(cronosChainId), isNull);
      verify(() => settingsStore.loadEvmNetworks()).called(1);
    });
  });

  group("restoreNodesIfNone", () {
    test("a saved network with no node rows gets its RPC and failover back", () async {
      final rpcUrl = answering(opChainId, "rpc");
      final failoverUrl = answering(opChainId, "failover");
      await network(opChainId, rpcUrl: rpcUrl, failoverUrl: failoverUrl).save();

      await EvmNetwork.restoreNodesIfNone(opChainId);

      final nodes = await Node.getAllForEvmChain(opChainId);
      expect(nodes.map((node) => node.uri.toString()), unorderedEquals([rpcUrl, failoverUrl]));
      expect(nodes.singleWhere((node) => node.isDefault).uri.toString(), rpcUrl);
    });

    test("a network with any node row left is not touched", () async {
      final userUrl = answering(opChainId, "user");
      await network(opChainId, rpcUrl: answering(opChainId, "rpc")).save();
      await EvmNetwork.rpcNode(userUrl, opChainId).save();

      await EvmNetwork.restoreNodesIfNone(opChainId);

      expect(await getNodeUrls(opChainId), [userUrl]);
    });

    test("a chain without a saved row gets no nodes", () async {
      await EvmNetwork.restoreNodesIfNone(opChainId);

      expect(await getNodeUrls(opChainId), isEmpty);
    });
  });

  group("counts", () {
    test("walletCount counts evm wallets on that chain only", () async {
      await insertEvmWallet("op one", opChainId);
      await insertEvmWallet("op two", opChainId);
      await insertEvmWallet("ink", inkChainId);

      expect(await service.walletCount(opChainId), 2);
      expect(await service.walletCount(inkChainId), 1);
      expect(await service.walletCount(cronosChainId), 0);
    });

    test("contactCount counts contacts stored with the chain's added raw only", () {
      final opCurrency = AddedNetworkCurrency(
        network(opChainId, rpcUrl: "https://rpc.example"),
      );
      when(() => contacts.values).thenReturn([
        Contact(name: "a", address: "0x1", type: opCurrency),
        Contact(name: "b", address: "0x2", type: opCurrency),
        Contact(name: "c", address: "0x3", type: CryptoCurrency.eth),
      ]);

      expect(service.contactCount(opChainId), 2);
      expect(service.contactCount(inkChainId), 0);
    });
  });

  group("networkFromEntry and tagFromName", () {
    test("takes the first two RPCs and a tag from the short name", () {
      const entry = ChainListEntry(
        chainId: inkChainId,
        name: "Ink",
        shortName: "ink-mainnet",
        symbol: "ETH",
        decimals: 6,
        rpcUrls: ["https://one.example", "https://two.example", "https://three.example"],
        explorerUrl: "https://explorer.example",
        iconUrl: "https://icons.example/ink.jpg",
      );

      final built = service.networkFromEntry(entry);

      expect(built.rpcUrl, "https://one.example");
      expect(built.failoverUrl, "https://two.example");
      expect(built.tag, "INKMAINNET");
      expect(built.isEnabled, isFalse);
      expect(built.isManual, isFalse);
      expect(built.explorerUrl, "https://explorer.example");
      expect(built.decimals, 6);
      expect(built.iconUrl, "https://icons.example/ink.jpg");
      expect(built.name, "Ink");
    });

    test("with one RPC there is no failover, and no short name tags from the name", () {
      const entry = ChainListEntry(
        chainId: cronosChainId,
        name: "Cronos Mainnet",
        shortName: "",
        symbol: "CRO",
        decimals: 18,
        rpcUrls: ["https://one.example"],
      );

      final built = service.networkFromEntry(entry);

      expect(built.failoverUrl, isNull);
      expect(built.tag, "CRONOSMAIN");
    });

    test("tagFromName keeps upper-case letters and digits, at most ten", () {
      expect(EvmNetworkService.tagFromName("x-layer 196", 196), "XLAYER196");
      expect(EvmNetworkService.tagFromName("a very long network name", 7), "AVERYLONGN");
    });

    test("a name with no letters or digits gets a tag from its chain ID", () {
      expect(EvmNetworkService.tagFromName("!!", 4242), "EVM4242");
    });
  });
}
