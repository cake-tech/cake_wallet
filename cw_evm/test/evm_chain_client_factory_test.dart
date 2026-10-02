import "dart:io";

import "package:cw_core/evm_network.dart";
import "package:cw_core/utils/proxy_wrapper.dart";
import "package:cw_core/utils/tor/disabled.dart";
import "package:cw_evm/evm_chain_client_factory.dart";
import "package:cw_evm/evm_chain_registry.dart";
import "package:cw_evm/utils/network_chain_utils.dart";
import "package:flutter_test/flutter_test.dart";

// Every HttpClient connects to the local server, whatever host the URI names
class _LocalServerOverrides extends HttpOverrides {
  _LocalServerOverrides(this.port);

  final int port;

  @override
  HttpClient createHttpClient(SecurityContext? context) => super.createHttpClient(context)
    ..connectionFactory =
        (uri, proxyHost, proxyPort) => Socket.startConnect(InternetAddress.loopbackIPv4, port);
}

void main() {
  const wallet = "0x52908400098527886e0f7030069857d2e4169ee7";
  const tokenContract = "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913";

  // Rootstock: on Blockscout, not on Etherscan's list nor Moralis's
  const blockscoutOnlyChainId = 30;
  // X Layer: on none of the three
  const uncoveredChainId = 196;

  final registry = EvmChainRegistry();
  late HttpServer server;
  final requests = <Uri>[];

  EvmNetwork addedNetwork(int chainId, String symbol) => EvmNetwork(
        chainId: chainId,
        name: "Chain $chainId",
        symbol: symbol,
        decimals: 18,
        tag: symbol,
        rpcUrl: "https://rpc.chain-$chainId.example",
        isEnabled: true,
      );

  setUpAll(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requests.add(request.uri);
      request.response.write("{}");
      await request.response.close();
    });

    CakeTor.instance = CakeTorDisabled();
    HttpOverrides.global = _LocalServerOverrides(server.port);
  });

  tearDownAll(() async {
    HttpOverrides.global = null;
    await server.close(force: true);
  });

  setUp(() {
    requests.clear();
    registry.registerAddedNetwork(addedNetwork(blockscoutOnlyChainId, "RBTC"));
    registry.registerAddedNetwork(addedNetwork(uncoveredChainId, "OKB"));
  });

  tearDown(registry.unregisterAllAddedNetworks);

  group("EVMChainClientFactory history provider order", () {
    test("a chain only Blockscout covers gets Blockscout, with or without keys", () {
      final client = EVMChainClientFactory.createClient(blockscoutOnlyChainId);

      expect(client.historyProvider!.name, "Blockscout");
    });

    test("the client takes its fee type from the registry", () {
      expect(EVMChainClientFactory.createClient(1).feeType, FeeType.eip1559);
      expect(EVMChainClientFactory.createClient(137).feeType, FeeType.legacy);
      expect(
        EVMChainClientFactory.createClient(uncoveredChainId).feeType,
        FeeType.eip1559OrLegacy,
      );
    });

    test("an unregistered chain throws instead of getting a client", () {
      registry.unregisterAddedNetwork(uncoveredChainId);

      expect(() => EVMChainClientFactory.createClient(uncoveredChainId), throwsException);
    });
  });

  group("EVMChainClientFactory sent-only fallback", () {
    test("a chain no provider covers gets a client with no history provider", () {
      expect(EVMChainClientFactory.createClient(uncoveredChainId).historyProvider, isNull);
    });

    test("its client returns empty history without asking any API", () async {
      final client = EVMChainClientFactory.createClient(uncoveredChainId);

      expect(await client.fetchTransactions(wallet), isEmpty);
      expect(await client.fetchTransactions(wallet, contractAddress: tokenContract), isEmpty);
      expect(await client.fetchInternalTransactions(wallet), isEmpty);
      expect(requests, isEmpty);
    });

    test("a chain no Etherscan-shaped provider covers has no source code lookup", () {
      expect(
        EVMChainClientFactory.contractSourceCodeUri(uncoveredChainId, tokenContract),
        isNull,
      );
    });

    test("Blockscout serves the source code lookup for a chain Etherscan does not list", () {
      final uri =
          EVMChainClientFactory.contractSourceCodeUri(blockscoutOnlyChainId, tokenContract)!;

      expect(uri.host, "rootstock.blockscout.com");
      expect(uri.queryParameters["action"], "getsourcecode");
      expect(uri.queryParameters["address"], tokenContract);
    });
  });
}
