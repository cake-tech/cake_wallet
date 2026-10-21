import "dart:convert";
import "dart:io";

import "package:cw_core/node.dart";
import "package:cw_core/utils/proxy_wrapper.dart";
import "package:cw_core/utils/tor/disabled.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  // The server answers these as 0xa and 0x89
  const ownChainId = 10;
  const otherChainId = 137;

  late HttpServer server;
  late List<String> receivedPaths;
  late List<String> receivedBodies;

  Node evmNode(String path, {int? chainId = ownChainId}) => Node(
        uri: "127.0.0.1:${server.port}",
        path: path,
        type: WalletType.evm,
        chainId: chainId,
        useSSL: false,
      );

  setUpAll(() => CakeTor.instance = CakeTorDisabled());

  setUp(() async {
    receivedPaths = [];
    receivedBodies = [];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      receivedPaths.add(request.uri.path);
      final body = await utf8.decoder.bind(request).join();
      receivedBodies.add(body);
      final response = request.response;

      switch (request.uri.path) {
        case "/own-chain":
          response.write(jsonEncode({"jsonrpc": "2.0", "id": 1, "result": "0xa"}));
        case "/chain-id-only":
          final isChainId = jsonDecode(body)["method"] == "eth_chainId";
          response.write(
            jsonEncode(
              isChainId
                  ? {"jsonrpc": "2.0", "id": 1, "result": "0xa"}
                  : {
                      "jsonrpc": "2.0",
                      "id": 1,
                      "error": {"code": -32601, "message": "the method does not exist"},
                    },
            ),
          );
        case "/other-chain":
          response.write(jsonEncode({"jsonrpc": "2.0", "id": 1, "result": "0x89"}));
        case "/upper-case-hex":
          response.write(jsonEncode({"jsonrpc": "2.0", "id": 1, "result": "0X1A"}));
        case "/html":
          response.write("<html>Bad gateway</html>");
        case "/rpc-error":
          response.write(
            jsonEncode({
              "jsonrpc": "2.0",
              "id": 1,
              "error": {"code": -32601, "message": "Method not found"},
            }),
          );
        case "/numeric-result":
          response.write(jsonEncode({"jsonrpc": "2.0", "id": 1, "result": 10}));
        case "/bad-hex":
          response.write(jsonEncode({"jsonrpc": "2.0", "id": 1, "result": "0xzz"}));
        case "/server-error":
          response.statusCode = 500;
          response.write(jsonEncode({"jsonrpc": "2.0", "id": 1, "result": "0xa"}));
      }

      await response.close();
    });
  });

  tearDown(() async {
    await server.close(force: true);
  });

  group("Node.requestEvmChainId", () {
    test("posts eth_chainId and parses the hex answer", () async {
      expect(await evmNode("/own-chain").requestEvmChainId(), ownChainId);

      expect(receivedPaths, ["/own-chain"]);
      expect(
        jsonDecode(receivedBodies.single),
        {"jsonrpc": "2.0", "id": 1, "method": "eth_chainId", "params": <Object>[]},
      );
    });

    test("returns the chain another network's RPC answers with", () async {
      expect(await evmNode("/other-chain").requestEvmChainId(), otherChainId);
    });

    test("an upper-case 0X prefix still parses", () async {
      expect(await evmNode("/upper-case-hex").requestEvmChainId(), 26);
    });

    test("a body that is not JSON gives no answer", () async {
      expect(await evmNode("/html").requestEvmChainId(), isNull);
    });

    test("a JSON-RPC error with no result gives no answer", () async {
      expect(await evmNode("/rpc-error").requestEvmChainId(), isNull);
    });

    test("a result that is not a hex string gives no answer", () async {
      expect(await evmNode("/numeric-result").requestEvmChainId(), isNull);
      expect(await evmNode("/bad-hex").requestEvmChainId(), isNull);
    });

    test("a non-2xx status gives no answer even with a chain ID in the body", () async {
      expect(await evmNode("/server-error").requestEvmChainId(), isNull);
    });
  });

  group("Node.requestEthereumServer", () {
    test("is true only when the node answers its own chain", () async {
      expect(await evmNode("/own-chain").requestEthereumServer(), isTrue);
      expect(await evmNode("/other-chain").requestEthereumServer(), isFalse);
      expect(await evmNode("/html").requestEthereumServer(), isFalse);
    });

    test("is false when the node answers its chain but refuses eth_blockNumber", () async {
      expect(await evmNode("/chain-id-only").requestEthereumServer(), isFalse);
      expect(receivedBodies.map((body) => jsonDecode(body)["method"]), [
        "eth_chainId",
        "eth_blockNumber",
      ]);
    });

    test("is false without a chain ID and never asks the node", () async {
      expect(await evmNode("/own-chain", chainId: null).requestEthereumServer(), isFalse);
      expect(receivedPaths, isEmpty);
    });
  });

  group("Node.isOnAnotherChain", () {
    test("is true only for a definite answer from another chain", () async {
      expect(await evmNode("/other-chain").isOnAnotherChain(), isTrue);
      expect(await evmNode("/own-chain").isOnAnotherChain(), isFalse);
    });

    test("is false when the node gives no answer, so an unreachable node still saves", () async {
      expect(await evmNode("/html").isOnAnotherChain(), isFalse);
      expect(await evmNode("/server-error").isOnAnotherChain(), isFalse);
    });
  });

  group("Node.requestNode", () {
    test("checks an evm node by its chain ID", () async {
      expect(await evmNode("/own-chain").requestNode(), isTrue);
      expect(await evmNode("/other-chain").requestNode(), isFalse);
      expect(receivedBodies.map((body) => jsonDecode(body)["method"]), [
        "eth_chainId",
        "eth_blockNumber",
        "eth_chainId",
      ]);
    });
  });
}
