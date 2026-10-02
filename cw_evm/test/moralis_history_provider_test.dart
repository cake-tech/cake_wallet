import "dart:convert";
import "dart:io";

import "package:cw_core/utils/proxy_wrapper.dart";
import "package:cw_core/utils/tor/disabled.dart";
import "package:cw_evm/history/moralis_history_provider.dart";
import "package:flutter_test/flutter_test.dart";

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
  const apiKey = "moralis-test-key";
  const wallet = "0x52908400098527886e0f7030069857d2e4169ee7";
  const counterparty = "0x8617e340b3d01fa5f11f306f4090fd50e238070d";
  const unrelated = "0x1111111111111111111111111111111111111111";
  const tokenContract = "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913";

  late HttpServer server;
  final requests = <Uri>[];
  final hosts = <String?>[];
  final apiKeyHeaders = <String?>[];
  int statusCode = 200;
  String body = "";

  Map<String, Object?> transactionRow({
    required String hash,
    required String value,
    String receiptStatus = "1",
  }) =>
      {
        "hash": hash,
        "block_timestamp": "2026-09-20T10:00:00.000Z",
        "from_address": wallet,
        "to_address": counterparty,
        "value": value,
        "receipt_gas_used": "21000",
        "gas_price": "1500000000",
        "block_number": "20000000",
        "receipt_status": receiptStatus,
        "input": "0x",
      };

  setUpAll(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requests.add(request.uri);
      hosts.add(request.headers.host);
      apiKeyHeaders.add(request.headers.value("X-API-Key"));
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
    apiKeyHeaders.clear();
    statusCode = 200;
    body = "";
  });

  group("MoralisHistoryProvider.covers", () {
    test("needs the API key", () {
      expect(MoralisHistoryProvider(apiKey: "").covers(25), isFalse);
      expect(MoralisHistoryProvider(apiKey: apiKey).covers(25), isTrue);
    });

    test("is limited to the chains Moralis supports", () {
      // X Layer is not one of them
      expect(MoralisHistoryProvider(apiKey: apiKey).covers(196), isFalse);
    });
  });

  group("MoralisHistoryProvider.transactions", () {
    test("asks the wallet path with the hex chain ID and the key header", () async {
      body = jsonEncode({"result": []});

      await MoralisHistoryProvider(apiKey: apiKey).transactions(baseChainId, wallet);

      expect(hosts.single, "deep-index.moralis.io");
      expect(requests.single.path, "/api/v2.2/$wallet");
      expect(requests.single.queryParameters, {"chain": "0x2105"});
      expect(apiKeyHeaders.single, apiKey);
    });

    test("maps a row to a transaction model", () async {
      body = jsonEncode({
        "result": [transactionRow(hash: "0xsent", value: "250000000000000")],
      });

      final transactions =
          await MoralisHistoryProvider(apiKey: apiKey).transactions(baseChainId, wallet);

      final transaction = transactions.single;
      expect(transaction.hash, "0xsent");
      expect(transaction.from, wallet);
      expect(transaction.to, counterparty);
      expect(transaction.amount, BigInt.parse("250000000000000"));
      expect(transaction.gasUsed, 21000);
      expect(transaction.gasPrice, BigInt.from(1500000000));
      expect(transaction.blockNumber, 20000000);
      // The history list formats this date as is, so it must be local like the other providers'
      expect(transaction.date, DateTime.utc(2026, 9, 20, 10).toLocal());
      expect(transaction.date.isUtc, isFalse);
      expect(transaction.confirmations, 1);
      expect(transaction.isError, isFalse);
      expect(transaction.tokenSymbol, "ETH");
      expect(transaction.chainId, baseChainId);
    });

    test("drops zero-value rows and marks a failed receipt as an error", () async {
      body = jsonEncode({
        "result": [
          transactionRow(hash: "0xzero", value: "0"),
          transactionRow(hash: "0xfailed", value: "9", receiptStatus: "0"),
        ],
      });

      final transactions =
          await MoralisHistoryProvider(apiKey: apiKey).transactions(baseChainId, wallet);

      expect(transactions.single.hash, "0xfailed");
      expect(transactions.single.isError, isTrue);
    });

    test("an empty result page gives no transactions", () async {
      body = jsonEncode({"cursor": null, "result": []});

      final transactions =
          await MoralisHistoryProvider(apiKey: apiKey).transactions(baseChainId, wallet);

      expect(transactions, isEmpty);
    });

    test("a non-2xx answer gives no transactions even with rows in it", () async {
      statusCode = 401;
      body = jsonEncode({
        "result": [transactionRow(hash: "0xsent", value: "9")],
      });

      final transactions =
          await MoralisHistoryProvider(apiKey: apiKey).transactions(baseChainId, wallet);

      expect(transactions, isEmpty);
    });

    test("a body that is not JSON gives no transactions instead of throwing", () async {
      body = "<html>502 Bad Gateway</html>";

      final transactions =
          await MoralisHistoryProvider(apiKey: apiKey).transactions(baseChainId, wallet);

      expect(transactions, isEmpty);
    });

    test("a JSON body that is not an object, or a result that is not a list, gives nothing",
        () async {
      final provider = MoralisHistoryProvider(apiKey: apiKey);

      body = jsonEncode([transactionRow(hash: "0xsent", value: "9")]);
      expect(await provider.transactions(baseChainId, wallet), isEmpty);

      body = jsonEncode({"result": "Invalid address"});
      expect(await provider.transactions(baseChainId, wallet), isEmpty);
    });

    test("a row missing its timestamp is skipped and the other rows are kept", () async {
      body = jsonEncode({
        "result": [
          transactionRow(hash: "0xsent", value: "9"),
          {...transactionRow(hash: "0xbroken", value: "9"), "block_timestamp": null},
          transactionRow(hash: "0xreceived", value: "3"),
        ],
      });

      final transactions =
          await MoralisHistoryProvider(apiKey: apiKey).transactions(baseChainId, wallet);

      expect(transactions.map((transaction) => transaction.hash), ["0xsent", "0xreceived"]);
    });
  });

  group("MoralisHistoryProvider.tokenTransfers", () {
    test("asks the erc20 transfers path for the contract and maps the token fields", () async {
      body = jsonEncode({
        "result": [
          {
            "transaction_hash": "0xtoken",
            "address": tokenContract,
            "block_timestamp": "2026-09-20T10:00:00.000Z",
            "block_number": "20000001",
            "from_address": counterparty,
            "to_address": wallet,
            "value": "7000000",
            "token_symbol": "USDC",
            "token_decimals": "6",
          },
          {
            "transaction_hash": "0xzerotoken",
            "address": tokenContract,
            "block_timestamp": "2026-09-20T10:00:00.000Z",
            "value": "0",
          },
        ],
      });

      final transfers = await MoralisHistoryProvider(apiKey: apiKey)
          .tokenTransfers(baseChainId, wallet, tokenContract);

      expect(requests.single.path, "/api/v2.2/$wallet/erc20/transfers");
      expect(requests.single.queryParameters, {
        "chain": "0x2105",
        "contract_addresses[0]": tokenContract,
      });
      final transfer = transfers.single;
      expect(transfer.hash, "0xtoken");
      expect(transfer.contractAddress, tokenContract);
      expect(transfer.from, counterparty);
      expect(transfer.to, wallet);
      expect(transfer.amount, BigInt.from(7000000));
      expect(transfer.tokenSymbol, "USDC");
      expect(transfer.tokenDecimal, 6);
      expect(transfer.blockNumber, 20000001);
    });

    test("a row that fails to parse is skipped and the other rows are kept", () async {
      body = jsonEncode({
        "result": [
          {
            "transaction_hash": "0xbadtimestamp",
            "address": tokenContract,
            "block_timestamp": 1758362400,
            "value": "1",
          },
          {
            "transaction_hash": "0xtoken",
            "address": tokenContract,
            "block_timestamp": "2026-09-20T10:00:00.000Z",
            "value": "7000000",
          },
          {
            "transaction_hash": "0xbadvalue",
            "address": tokenContract,
            "block_timestamp": "2026-09-20T10:00:00.000Z",
            "value": "not a number",
          },
        ],
      });

      final transfers = await MoralisHistoryProvider(apiKey: apiKey)
          .tokenTransfers(baseChainId, wallet, tokenContract);

      expect(transfers.map((transfer) => transfer.hash), ["0xtoken"]);
    });
  });

  group("MoralisHistoryProvider.internalTransactions", () {
    test("keeps the wallet's non-zero internal calls and marks an errored one", () async {
      body = jsonEncode({
        "result": [
          {
            ...transactionRow(hash: "0xouter", value: "0"),
            "internal_transactions": [
              {
                "transaction_hash": "0xinternalin",
                "from": counterparty,
                "to": wallet.toUpperCase().replaceFirst("0X", "0x"),
                "value": "42",
                "gas_used": "2300",
                "block_number": "20000002",
                "error": null,
              },
              {
                "transaction_hash": "0xinternalerror",
                "from": wallet,
                "to": counterparty,
                "value": "5",
                "error": "Reverted",
              },
              {
                "transaction_hash": "0xinternalzero",
                "from": counterparty,
                "to": wallet,
                "value": "0",
              },
              {
                "transaction_hash": "0xinternalunrelated",
                "from": counterparty,
                "to": unrelated,
                "value": "99",
              },
            ],
          },
          transactionRow(hash: "0xnointernals", value: "1"),
        ],
      });

      final internals =
          await MoralisHistoryProvider(apiKey: apiKey).internalTransactions(baseChainId, wallet);

      expect(requests.single.queryParameters, {
        "chain": "0x2105",
        "include": "internal_transactions",
      });
      expect(internals.map((internal) => internal.hash), ["0xinternalin", "0xinternalerror"]);
      expect(internals.first.amount, BigInt.from(42));
      expect(internals.first.gasUsed, 2300);
      expect(internals.first.isError, isFalse);
      expect(internals.last.isError, isTrue);
      expect(internals.first.tokenSymbol, "ETH");
    });

    test("a malformed answer gives no internal transactions", () async {
      body = "not json";

      expect(
        await MoralisHistoryProvider(apiKey: apiKey).internalTransactions(baseChainId, wallet),
        isEmpty,
      );
    });

    test("an internal call that fails to parse is skipped and the other calls are kept", () async {
      body = jsonEncode({
        "result": [
          {
            ...transactionRow(hash: "0xnotimestamp", value: "0"),
            "block_timestamp": null,
            "internal_transactions": [
              {
                "transaction_hash": "0xinternalnotimestamp",
                "from": counterparty,
                "to": wallet,
                "value": "8",
              },
            ],
          },
          {
            ...transactionRow(hash: "0xouter", value: "0"),
            "internal_transactions": [
              {
                "transaction_hash": "0xinternalbadvalue",
                "from": counterparty,
                "to": wallet,
                "value": "not a number",
              },
              {
                "transaction_hash": "0xinternalin",
                "from": counterparty,
                "to": wallet,
                "value": "42",
              },
            ],
          },
        ],
      });

      final internals =
          await MoralisHistoryProvider(apiKey: apiKey).internalTransactions(baseChainId, wallet);

      expect(internals.map((internal) => internal.hash), ["0xinternalin"]);
    });
  });
}
