import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/erc20_token.dart';
import 'package:cw_nano/nano_balance.dart';
import 'package:cw_nano/nano_transaction_model.dart';
import 'package:cw_nano/nano_util.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:nanodart/nanodart.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web3dart/contracts/erc20.dart';
import 'package:cw_core/node.dart';

class NanoClient {
  // bit of a hack since we need access to a node in a weird location:
  static const String BACKUP_NODE_URI = "rpc.nano.to";
  static const String DEFAULT_REPRESENTATIVE =
      "nano_38713x95zyjsqzx6nm1dsom1jmm668owkeb9913ax6nfgj15az3nu8xkx579";

  StreamSubscription<Transfer>? subscription;
  Node? _node;

  bool connect(Node node) {
    try {
      _node = node;
      return true;
    } catch (e) {
      return false;
    }
  }

  void setListeners(EthereumAddress userAddress, Function(FilterEvent) onNewTransaction) async {}

  Future<NanoBalance> getBalance(String address) async {
    // this is the preferred rpc call but the test node isn't returning this one:
    final response = await http.post(
      _node!.uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(
        {
          "action": "account_balance",
          "account": address,
        },
      ),
    );
    final data = await jsonDecode(response.body);
    final String currentBalance = data["balance"] as String;
    final String receivableBalance = data["receivable"] as String;
    final BigInt cur = BigInt.parse(currentBalance);
    final BigInt rec = BigInt.parse(receivableBalance);
    return NanoBalance(currentBalance: cur, receivableBalance: rec);
  }

  Future<String> requestWork(String hash) async {
    return http
        .post(
      Uri.parse("https://rpc.nano.to"), // TODO: make a setting
      headers: {'Content-type': 'application/json'},
      body: json.encode(
        {
          "action": "work_generate",
          "hash": hash,
        },
      ),
    )
        .then((http.Response response) {
      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded = json.decode(response.body) as Map<String, dynamic>;
        if (decoded.containsKey("error")) {
          throw Exception("Received error ${decoded["error"]}");
        }
        return decoded["work"] as String;
      } else {
        throw Exception("Received error ${response.statusCode}");
      }
    });
  }

  Future<String> send({
    required String privateKey,
    required String amountRaw,
    required String destinationAddress,
  }) async {
    final Map<String, String> sendBlock = await constructSendBlock(
      privateKey: privateKey,
      amountRaw: amountRaw,
      destinationAddress: destinationAddress,
    );

    return await processBlock(sendBlock, "send");
  }

  Future<String> processBlock(Map<String, String> block, String subtype) async {
    final headers = {"Content-Type": "application/json"};
    final processBody = jsonEncode({
      "action": "process",
      "json_block": "true",
      "subtype": subtype,
      "block": block,
    });

    final processResponse = await http.post(
      _node!.uri,
      headers: headers,
      body: processBody,
    );

    final Map<String, dynamic> decoded = json.decode(processResponse.body) as Map<String, dynamic>;
    if (decoded.containsKey("error")) {
      throw Exception("Received error ${decoded["error"]}");
    }

    // return the hash of the transaction:
    return decoded["hash"].toString();
  }

  Future<Map<String, String>> constructSendBlock({
    required String privateKey,
    required String amountRaw,
    required String destinationAddress,
    BigInt? balanceAfterTx,
    String? previousHash,
  }) async {
    try {
      // our address:
      final String publicAddress = NanoUtil.privateKeyToAddress(privateKey);

      // first get the current account balance:
      if (balanceAfterTx == null) {
        final BigInt currentBalance = (await getBalance(publicAddress)).currentBalance;
        final BigInt txAmount = BigInt.parse(amountRaw);
        balanceAfterTx = currentBalance - txAmount;
      }

      // get the account info (we need the frontier and representative):
      final headers = {"Content-Type": "application/json"};
      final infoBody = jsonEncode({
        "action": "account_info",
        "representative": "true",
        "account": publicAddress,
      });
      final infoResponse = await http.post(
        _node!.uri,
        headers: headers,
        body: infoBody,
      );

      String frontier = jsonDecode(infoResponse.body)["frontier"].toString();
      // override if provided:
      if (previousHash != null) {
        frontier = previousHash;
      }
      final String representative = jsonDecode(infoResponse.body)["representative"].toString();
      // link = destination address:
      final String link = NanoAccounts.extractPublicKey(destinationAddress);
      final String linkAsAccount = destinationAddress;

      // construct the send block:
      Map<String, String> sendBlock = {
        "type": "state",
        "account": publicAddress,
        "previous": frontier,
        "representative": representative,
        "balance": balanceAfterTx.toString(),
        "link": link,
      };

      // sign the send block:
      final String hash = NanoBlocks.computeStateHash(
        NanoAccountType.NANO,
        sendBlock["account"]!,
        sendBlock["previous"]!,
        sendBlock["representative"]!,
        BigInt.parse(sendBlock["balance"]!),
        sendBlock["link"]!,
      );
      final String signature = NanoSignatures.signBlock(hash, privateKey);

      // get PoW for the send block:
      final String work = await requestWork(frontier);

      sendBlock["link_as_account"] = linkAsAccount;
      sendBlock["signature"] = signature;
      sendBlock["work"] = work;

      // ready to post send block:
      return sendBlock;
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  Future<void> receiveBlock({
    required String blockHash,
    required String source,
    required String amountRaw,
    required String destinationAddress,
    required String privateKey,
  }) async {
    bool openBlock = false;

    final headers = {
      "Content-Type": "application/json",
    };

    // first check if the account is open:
    // get the account info (we need the frontier and representative):
    final infoBody = jsonEncode({
      "action": "account_info",
      "representative": "true",
      "account": destinationAddress,
    });
    final infoResponse = await http.post(
      _node!.uri,
      headers: headers,
      body: infoBody,
    );
    final infoData = jsonDecode(infoResponse.body);

    if (infoData["error"] != null) {
      // account is not open yet, we need to create an open block:
      openBlock = true;
    }

    // first get the account balance:
    final balanceBody = jsonEncode({
      "action": "account_balance",
      "account": destinationAddress,
    });

    final balanceResponse = await http.post(
      _node!.uri,
      headers: headers,
      body: balanceBody,
    );

    final balanceData = jsonDecode(balanceResponse.body);
    final BigInt currentBalance = BigInt.parse(balanceData["balance"].toString());
    final BigInt txAmount = BigInt.parse(amountRaw);
    final BigInt balanceAfterTx = currentBalance + txAmount;

    String frontier = infoData["frontier"].toString();
    String representative = infoData["representative"].toString();

    if (openBlock) {
      // we don't have a representative set yet:
      representative = DEFAULT_REPRESENTATIVE;
    }

    // link = send block hash:
    final String link = blockHash;
    // this "linkAsAccount" is meaningless:
    final String linkAsAccount = NanoAccounts.createAccount(NanoAccountType.NANO, blockHash);

    // construct the receive block:
    Map<String, String> receiveBlock = {
      "type": "state",
      "account": destinationAddress,
      "previous":
          openBlock ? "0000000000000000000000000000000000000000000000000000000000000000" : frontier,
      "representative": representative,
      "balance": balanceAfterTx.toString(),
      "link": link,
      "link_as_account": linkAsAccount,
    };

    // sign the receive block:
    final String hash = NanoBlocks.computeStateHash(
      NanoAccountType.NANO,
      receiveBlock["account"]!,
      receiveBlock["previous"]!,
      receiveBlock["representative"]!,
      BigInt.parse(receiveBlock["balance"]!),
      receiveBlock["link"]!,
    );
    final String signature = NanoSignatures.signBlock(hash, privateKey);

    // get PoW for the receive block:
    String? work;
    if (openBlock) {
      work = await requestWork(NanoAccounts.extractPublicKey(destinationAddress));
    } else {
      work = await requestWork(frontier);
    }
    receiveBlock["link_as_account"] = linkAsAccount;
    receiveBlock["signature"] = signature;
    receiveBlock["work"] = work;

    // process the receive block:

    final processBody = jsonEncode({
      "action": "process",
      "json_block": "true",
      "subtype": "receive",
      "block": receiveBlock,
    });
    final processResponse = await http.post(
      _node!.uri,
      headers: headers,
      body: processBody,
    );

    final Map<String, dynamic> decoded = json.decode(processResponse.body) as Map<String, dynamic>;
    if (decoded.containsKey("error")) {
      throw Exception("Received error ${decoded["error"]}");
    }
  }

  // returns the number of blocks received:
  Future<int> confirmAllReceivable({
    required String destinationAddress,
    required String privateKey,
  }) async {
    final receivableResponse = await http.post(_node!.uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "receivable",
          "source": "true",
          "account": destinationAddress,
          "count": "-1",
        }));

    final receivableData = await jsonDecode(receivableResponse.body);
    if (receivableData["blocks"] == "") {
      return 0;
    }
    final blocks = receivableData["blocks"] as Map<String, dynamic>;
    // confirm all receivable blocks:
    for (final blockHash in blocks.keys) {
      final block = blocks[blockHash];
      final String amountRaw = block["amount"] as String;
      final String source = block["source"] as String;
      await receiveBlock(
        blockHash: blockHash,
        source: source,
        amountRaw: amountRaw,
        privateKey: privateKey,
        destinationAddress: destinationAddress,
      );
      // a bit of a hack:
      await Future<void>.delayed(const Duration(seconds: 2));
    }

    return blocks.keys.length;
  }

  Future<dynamic> getTransactionDetails(String transactionHash) async {
    throw UnimplementedError();
  }

  void stop() {
    subscription?.cancel();
  }

  Future<List<NanoTransactionModel>> fetchTransactions(String address) async {
    try {
      final response = await http.post(_node!.uri,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "action": "account_history",
            "account": address,
            "count": "250", // TODO: pick a number
            // "raw": true,
          }));
      final data = await jsonDecode(response.body);
      final transactions = data["history"] is List ? data["history"] as List<dynamic> : [];

      // Map the transactions list to NanoTransactionModel using the factory
      // reversed so that the DateTime is correct when local_timestamp is absent
      return transactions.reversed
          .map<NanoTransactionModel>((transaction) => NanoTransactionModel.fromJson(transaction))
          .toList();
    } catch (e) {
      print(e);
      return [];
    }
  }
}
