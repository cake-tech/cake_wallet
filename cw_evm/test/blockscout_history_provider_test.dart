import "dart:convert";
import "dart:io";

import "package:cw_core/utils/proxy_wrapper.dart";
import "package:cw_core/utils/tor/disabled.dart";
import "package:cw_evm/history/blockscout_history_provider.dart";
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
  const baseChainId = 8453;
  const wallet = "0x52908400098527886e0f7030069857d2e4169ee7";
  const counterparty = "0x8617e340b3d01fa5f11f306f4090fd50e238070d";
  const tokenContract = "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913";

  late HttpServer server;
  final requests = <Uri>[];
  final hosts = <String?>[];
  int statusCode = 200;
  String body = "";

  Map<String, String> txRow({
    required String hash,
    required String from,
    required String to,
    required String value,
  }) =>
      {
        "timeStamp": "1727000000",
        "hash": hash,
        "from": from,
        "to": to,
        "value": value,
        "gasUsed": "21000",
        "gasPrice": "1500000000",
        "contractAddress": "",
        "confirmations": "12",
        "blockNumber": "20000000",
        "isError": "0",
        "input": "0x",
      };

  setUpAll(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requests.add(request.uri);
      hosts.add(request.headers.host);
      request.response.statusCode = statusCode;
      request.response.write(body);
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
    hosts.clear();
    statusCode = 200;
    body = "";
  });

  group("BlockscoutHistoryProvider.covers", () {
    test("covers the chains in its host map with no API key", () {
      final provider = BlockscoutHistoryProvider();

      expect(provider.apiKey, isEmpty);
      expect(provider.covers(baseChainId), isTrue);
      // Ink, which Etherscan does not list
      expect(provider.covers(57073), isTrue);
    });

    test("does not cover a chain outside its host map", () {
      // X Layer has no Blockscout instance
      expect(BlockscoutHistoryProvider().covers(196), isFalse);
    });
  });

  group("BlockscoutHistoryProvider.transactions", () {
    test("asks the chain's own host with the Etherscan query shape and no key", () async {
      body = jsonEncode({"status": "1", "message": "OK", "result": []});

      await BlockscoutHistoryProvider().transactions(baseChainId, wallet);

      expect(hosts.single, "base.blockscout.com");
      expect(requests.single.path, "/api");
      expect(requests.single.queryParameters, {
        "module": "account",
        "action": "txlist",
        "address": wallet,
      });
    });

    test("maps a txlist row to a transaction model", () async {
      body = jsonEncode({
        "status": "1",
        "message": "OK",
        "result": [txRow(hash: "0xsent", from: wallet, to: counterparty, value: "250000000000000")],
      });

      final transactions = await BlockscoutHistoryProvider().transactions(baseChainId, wallet);

      final transaction = transactions.single;
      expect(transaction.hash, "0xsent");
      expect(transaction.from, wallet);
      expect(transaction.to, counterparty);
      expect(transaction.amount, BigInt.parse("250000000000000"));
      expect(transaction.gasUsed, 21000);
      expect(transaction.gasPrice, BigInt.from(1500000000));
      expect(transaction.confirmations, 12);
      expect(transaction.blockNumber, 20000000);
      expect(transaction.date, DateTime.fromMillisecondsSinceEpoch(1727000000 * 1000));
      expect(transaction.isError, isFalse);
      expect(transaction.tokenSymbol, "ETH");
      expect(transaction.chainId, baseChainId);
    });

    test("drops outgoing zero-value rows and incoming dust, keeps outgoing dust", () async {
      body = jsonEncode({
        "status": "1",
        "message": "OK",
        "result": [
          txRow(hash: "0xzero", from: wallet, to: counterparty, value: "0"),
          txRow(hash: "0xincomingdust", from: counterparty, to: wallet, value: "9999999999999"),
          txRow(hash: "0xoutgoingdust", from: wallet, to: counterparty, value: "5"),
          txRow(hash: "0xincoming", from: counterparty, to: wallet, value: "10000000000000"),
        ],
      });

      final transactions = await BlockscoutHistoryProvider().transactions(baseChainId, wallet);

      expect(transactions.map((transaction) => transaction.hash), ["0xoutgoingdust", "0xincoming"]);
    });

    test("an empty result page gives no transactions", () async {
      body = jsonEncode({"status": "1", "message": "OK", "result": []});

      expect(await BlockscoutHistoryProvider().transactions(baseChainId, wallet), isEmpty);
    });

    test("a result given as a message instead of a list gives no transactions", () async {
      body = jsonEncode({"status": "0", "message": "NOTOK", "result": "Max rate limit reached"});

      expect(await BlockscoutHistoryProvider().transactions(baseChainId, wallet), isEmpty);
    });

    test("a body that is not JSON gives no transactions instead of throwing", () async {
      body = "<html>502 Bad Gateway</html>";

      expect(await BlockscoutHistoryProvider().transactions(baseChainId, wallet), isEmpty);
    });

    test("a non-2xx answer gives no transactions even with rows in it", () async {
      statusCode = 500;
      body = jsonEncode({
        "status": "1",
        "message": "OK",
        "result": [txRow(hash: "0xsent", from: wallet, to: counterparty, value: "250000000000000")],
      });

      expect(await BlockscoutHistoryProvider().transactions(baseChainId, wallet), isEmpty);
    });
  });

  group("BlockscoutHistoryProvider.tokenTransfers", () {
    test("asks tokentx for the contract and keeps the row's token symbol", () async {
      body = jsonEncode({
        "status": "1",
        "message": "OK",
        "result": [
          {
            ...txRow(hash: "0xtoken", from: counterparty, to: wallet, value: "7"),
            "contractAddress": tokenContract,
            "tokenSymbol": "USDC",
            "tokenDecimal": "6",
          },
        ],
      });

      final transfers =
          await BlockscoutHistoryProvider().tokenTransfers(baseChainId, wallet, tokenContract);

      expect(requests.single.queryParameters["action"], "tokentx");
      expect(requests.single.queryParameters["contractaddress"], tokenContract);
      // The dust filter is for native transfers only
      expect(transfers.single.hash, "0xtoken");
      expect(transfers.single.tokenSymbol, "USDC");
      expect(transfers.single.tokenDecimal, 6);
      expect(transfers.single.contractAddress, tokenContract);
    });
  });

  group("BlockscoutHistoryProvider.internalTransactions", () {
    test("asks txlistinternal and maps its rows", () async {
      body = jsonEncode({
        "status": "1",
        "message": "OK",
        "result": [txRow(hash: "0xinternal", from: counterparty, to: wallet, value: "42")],
      });

      final internals = await BlockscoutHistoryProvider().internalTransactions(baseChainId, wallet);

      expect(requests.single.queryParameters["action"], "txlistinternal");
      expect(internals.single.hash, "0xinternal");
      expect(internals.single.amount, BigInt.from(42));
    });

    test("a malformed answer gives no internal transactions", () async {
      body = "not json";

      expect(await BlockscoutHistoryProvider().internalTransactions(baseChainId, wallet), isEmpty);
    });
  });
}
