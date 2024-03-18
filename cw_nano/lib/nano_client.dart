import 'dart:async';
import 'dart:convert';

import 'package:cw_core/nano_account_info_response.dart';
import 'package:cw_nano/nano_balance.dart';
import 'package:cw_nano/nano_transaction_model.dart';
import 'package:http/http.dart' as http;
import 'package:nanodart/nanodart.dart';
import 'package:cw_core/node.dart';
import 'package:nanoutil/nanoutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NanoClient {
  static const Map<String, String> CAKE_HEADERS = {
    "Content-Type": "application/json",
    "nano-app": "cake-wallet"
  };

  NanoClient() {
    SharedPreferences.getInstance().then((value) => prefs = value);
  }

  late SharedPreferences prefs;
  Node? _node;
  Node? _powNode;
  static const String _defaultDefaultRepresentative =
      "nano_38713x95zyjsqzx6nm1dsom1jmm668owkeb9913ax6nfgj15az3nu8xkx579";

  String getRepFromPrefs() {
    // from preferences_key.dart "defaultNanoRep" key:
    return prefs.getString("default_nano_representative") ?? _defaultDefaultRepresentative;
  }

  bool connect(Node node) {
    try {
      _node = node;
      return true;
    } catch (e) {
      return false;
    }
  }

  bool connectPow(Node node) {
    try {
      _powNode = node;
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<NanoBalance> getBalance(String address) async {
    final response = await http.post(
      _node!.uri,
      headers: CAKE_HEADERS,
      body: jsonEncode(
        {
          "action": "account_balance",
          "account": address,
        },
      ),
    );
    final data = await jsonDecode(response.body);
    if (response.statusCode != 200 ||
        data["error"] != null ||
        data["balance"] == null ||
        data["receivable"] == null) {
      throw Exception(
          "Error while trying to get balance! ${data["error"] != null ? data["error"] : ""}");
    }
    final String currentBalance = data["balance"] as String;
    final String receivableBalance = data["receivable"] as String;
    final BigInt cur = BigInt.parse(currentBalance);
    final BigInt rec = BigInt.parse(receivableBalance);
    return NanoBalance(currentBalance: cur, receivableBalance: rec);
  }

  Future<AccountInfoResponse?> getAccountInfo(String address) async {
    try {
      final response = await http.post(
        _node!.uri,
        headers: CAKE_HEADERS,
        body: jsonEncode(
          {
            "action": "account_info",
            "representative": "true",
            "account": address,
          },
        ),
      );
      final data = await jsonDecode(response.body);
      return AccountInfoResponse.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      print("error while getting account info");
      return null;
    }
  }

  Future<String> changeRep({
    required String privateKey,
    required String repAddress,
    required String ourAddress,
  }) async {
    AccountInfoResponse? accountInfo = await getAccountInfo(ourAddress);

    if (accountInfo == null) {
      throw Exception(
          "error while getting account info, you can't change the rep of an unopened account");
    }

    // construct the change block:
    Map<String, String> changeBlock = {
      "type": "state",
      "account": ourAddress,
      "previous": accountInfo.frontier,
      "representative": repAddress,
      "balance": accountInfo.balance,
      "link": "0000000000000000000000000000000000000000000000000000000000000000",
      "link_as_account": "nano_1111111111111111111111111111111111111111111111111111hifc8npp",
    };

    // sign the change block:
    final String hash = NanoBlocks.computeStateHash(
      NanoAccountType.NANO,
      changeBlock["account"]!,
      changeBlock["previous"]!,
      changeBlock["representative"]!,
      BigInt.parse(changeBlock["balance"]!),
      changeBlock["link"]!,
    );
    final String signature = NanoSignatures.signBlock(hash, privateKey);

    // get PoW for the send block:
    final String work = await requestWork(accountInfo.frontier);

    changeBlock["signature"] = signature;
    changeBlock["work"] = work;

    try {
      return await processBlock(changeBlock, "change");
    } catch (e) {
      throw Exception("error while changing representative: $e");
    }
  }

  Future<String> requestWork(String hash) async {
    final response = await http.post(
      _powNode!.uri,
      headers: CAKE_HEADERS,
      body: json.encode(
        {
          "action": "work_generate",
          "hash": hash,
        },
      ),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> decoded = json.decode(response.body) as Map<String, dynamic>;
      if (decoded.containsKey("error")) {
        throw Exception("Received error ${decoded["error"]}");
      }
      return decoded["work"] as String;
    } else {
      throw Exception("Received work error ${response.body}");
    }
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
    final processBody = jsonEncode({
      "action": "process",
      "json_block": "true",
      "subtype": subtype,
      "block": block,
    });

    final processResponse = await http.post(
      _node!.uri,
      headers: CAKE_HEADERS,
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
    // our address:
    final String publicAddress = NanoDerivations.privateKeyToAddress(privateKey);

    // first get the current account balance:
    if (balanceAfterTx == null) {
      final BigInt currentBalance = (await getBalance(publicAddress)).currentBalance;
      final BigInt txAmount = BigInt.parse(amountRaw);
      balanceAfterTx = currentBalance - txAmount;
    }

    // get the account info (we need the frontier and representative):
    AccountInfoResponse? infoResponse = await getAccountInfo(publicAddress);
    if (infoResponse == null) {
      throw Exception(
          "error while getting account info! (we probably don't have an open account yet)");
    }

    String frontier = infoResponse.frontier;
    // override if provided:
    if (previousHash != null) {
      frontier = previousHash;
    }
    final String representative = infoResponse.representative;
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
  }

  Future<void> receiveBlock({
    required String blockHash,
    required String source,
    required String amountRaw,
    required String destinationAddress,
    required String privateKey,
  }) async {
    bool openBlock = false;

    // first check if the account is open:
    // get the account info (we need the frontier and representative):
    AccountInfoResponse? infoData = await getAccountInfo(destinationAddress);
    String? frontier;
    String? representative;

    if (infoData == null) {
      // account is not open yet, we need to create an open block:
      openBlock = true;
      // we don't have a representative set yet:
      representative = await getRepFromPrefs();
      // we don't have a frontier yet:
      frontier = "0000000000000000000000000000000000000000000000000000000000000000";
    } else {
      frontier = infoData.frontier;
      representative = infoData.representative;
    }

    // first get the account balance:
    final BigInt currentBalance = (await getBalance(destinationAddress)).currentBalance;
    final BigInt txAmount = BigInt.parse(amountRaw);
    final BigInt balanceAfterTx = currentBalance + txAmount;

    // link = send block hash:
    final String link = blockHash;
    // this "linkAsAccount" is meaningless:
    final String linkAsAccount = NanoAccounts.createAccount(NanoAccountType.NANO, blockHash);

    // construct the receive block:
    Map<String, String> receiveBlock = {
      "type": "state",
      "account": destinationAddress,
      "previous": frontier,
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
      headers: CAKE_HEADERS,
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
        headers: CAKE_HEADERS,
        body: jsonEncode({
          "action": "receivable",
          "account": destinationAddress,
          "count": "-1",
          "source": true,
        }));

    final receivableData = await jsonDecode(receivableResponse.body);
    if (receivableData["blocks"] == "" || receivableData["blocks"] == null) {
      return 0;
    }

    dynamic blocks;
    if (receivableData["blocks"] is List<dynamic>) {
      var listBlocks = receivableData["blocks"] as List<dynamic>;
      if (listBlocks.isEmpty) {
        return 0;
      }
      blocks = {for (var block in listBlocks) block['hash']: block};
    } else {
      blocks = receivableData["blocks"] as Map<String, dynamic>;
    }

    blocks = blocks as Map<String, dynamic>;

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

  void stop() {}

  Future<List<NanoTransactionModel>> fetchTransactions(String address) async {
    try {
      final response = await http.post(_node!.uri,
          headers: CAKE_HEADERS,
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
