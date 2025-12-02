import 'dart:async';
import 'dart:convert';

import 'package:cw_core/nano_account_info_response.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_nano/nano_block_info_response.dart';
import 'package:cw_core/n2_node.dart';
import 'package:cw_nano/nano_balance.dart';
import 'package:cw_nano/nano_transaction_model.dart';
import 'package:cw_core/node.dart';
import 'package:nanoutil/nanoutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cw_nano/.secrets.g.dart' as nano_secrets;

class NanoClient {
  static const Map<String, String> CAKE_HEADERS = {
    "Content-Type": "application/json",
    "nano-app": "cake-wallet"
  };

  static const String N2_REPS_ENDPOINT = "https://rpc.nano.to";

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

  Map<String, String> getHeaders(String host) {
    final headers = Map<String, String>.from(CAKE_HEADERS);
    if (host == "rpc.nano.to") {
      headers["key"] = nano_secrets.nano2ApiKey;
    }
    if (host == "nano.nownodes.io") {
      headers["api-key"] = nano_secrets.nanoNowNodesApiKey;
    }
    return headers;
  }

  Future<NanoBalance> getBalance(String address) async {
    final response = await ProxyWrapper().post(
      clearnetUri: _node!.uri,
      headers: getHeaders(_node!.uri.host),
      body: jsonEncode(
        {
          "action": "account_balance",
          "account": address,
        },
      ),
    );
    
    final data = jsonDecode(response.body) as Map<String, dynamic>;
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

  Future<AccountInfoResponse?> getAccountInfo(String address, {bool throwOnError = false}) async {
    try {
      final response = await ProxyWrapper().post(
        clearnetUri: _node!.uri,
        headers: getHeaders(_node!.uri.host),
        body: jsonEncode(
          {
            "action": "account_info",
            "representative": "true",
            "account": address,
          },
        ),
      );
      
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return AccountInfoResponse.fromJson(data);
    } catch (e) {
      printV("error while getting account info $e");
      if (throwOnError) {
        rethrow;
      }
      return null;
    }
  }

  Future<BlockContentsResponse?> getBlockContents(String block) async {
    try {
      final response = await ProxyWrapper().post(
        clearnetUri: _node!.uri,
        headers: getHeaders(_node!.uri.host),
        body: jsonEncode(
          {
            "action": "block_info",
            "json_block": "true",
            "hash": block,
          },
        ),
      );
      
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return BlockContentsResponse.fromJson(data["contents"] as Map<String, dynamic>);
    } catch (e) {
      printV("error while getting block info $e");
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
    final String hash = NanoSignatures.computeStateHash(
      NanoBasedCurrency.NANO,
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
    final response = await ProxyWrapper().post(
      clearnetUri: _powNode!.uri,
      headers: getHeaders(_powNode!.uri.host),
      body: json.encode(
        {
          "action": "work_generate",
          "hash": hash,
        },
      ),
    );
    
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
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

    final processResponse = await ProxyWrapper().post(
      clearnetUri: _node!.uri,
      headers: getHeaders(_node!.uri.host),
      body: processBody,
    );

    final Map<String, dynamic> decoded = jsonDecode(processResponse.body) as Map<String, dynamic>;
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
    final String link = NanoDerivations.addressToPublicKey(destinationAddress);
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
    final String hash = NanoSignatures.computeStateHash(
      NanoBasedCurrency.NANO,
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

    if ((BigInt.tryParse(amountRaw) ?? BigInt.zero) <= BigInt.zero) {
      throw Exception("amountRaw must be greater than zero");
    }

    BlockContentsResponse? frontierContents;

    if (!openBlock) {
      // get the block info of the frontier block:
      frontierContents = await getBlockContents(frontier);

      if (frontierContents == null) {
        throw Exception("error while getting frontier block info");
      }

      final String frontierHash = NanoSignatures.computeStateHash(
        NanoBasedCurrency.NANO,
        frontierContents.account,
        frontierContents.previous,
        frontierContents.representative,
        BigInt.parse(frontierContents.balance),
        frontierContents.link,
      );

      bool valid = await NanoSignatures.verify(
        frontierHash,
        frontierContents.signature,
        destinationAddress,
      );

      if (!valid) {
        throw Exception(
            "Frontier block signature is invalid! Potentially malicious block detected!");
      }
    }

    // first get the account balance:
    late BigInt currentBalance;
    if (!openBlock) {
      currentBalance = BigInt.parse(frontierContents!.balance);
    } else {
      currentBalance = BigInt.zero;
    }
    final BigInt txAmount = BigInt.parse(amountRaw);
    final BigInt balanceAfterTx = currentBalance + txAmount;

    // link = send block hash:
    final String link = blockHash;
    // this "linkAsAccount" is meaningless:
    final String linkAsAccount =
        NanoDerivations.publicKeyToAddress(blockHash, currency: NanoBasedCurrency.NANO);

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
    final String hash = NanoSignatures.computeStateHash(
      NanoBasedCurrency.NANO,
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
      work = await requestWork(NanoDerivations.addressToPublicKey(destinationAddress));
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
    final processResponse = await ProxyWrapper().post(
      clearnetUri: _node!.uri,
      headers: getHeaders(_node!.uri.host),
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
    try {
      final receivableResponse = await ProxyWrapper().post(
        clearnetUri: _node!.uri,
        headers: getHeaders(_node!.uri.host),
        body: jsonEncode({
          "action": "receivable",
          "account": destinationAddress,
          "count": "-1",
          "source": true,
        }),
      );
      final receivableData = jsonDecode(receivableResponse.body) as Map<String, dynamic>;
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
        await receiveBlock(
          blockHash: blockHash,
          amountRaw: amountRaw,
          privateKey: privateKey,
          destinationAddress: destinationAddress,
        );
        // a bit of a hack:
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      return blocks.keys.length;
    } catch (_) {
      // we failed to confirm all receivable blocks for w/e reason (PoW / node outage / etc)
      return 0;
    }
  }

  void stop() {}

  Future<List<NanoTransactionModel>> fetchTransactions(String address) async {
    try {
      final response = await ProxyWrapper().post(
        clearnetUri: _node!.uri,
        headers: getHeaders(_node!.uri.host),
        body: jsonEncode({
          "action": "account_history",
          "account": address,
          "count": "100",
          // "raw": true,
        }),
      );
      
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final transactions = data["history"] is List ? data["history"] as List<dynamic> : [];

      // Map the transactions list to NanoTransactionModel using the factory
      // reversed so that the DateTime is correct when local_timestamp is absent
      return transactions.reversed
          .map<NanoTransactionModel>((transaction) => NanoTransactionModel.fromJson(transaction))
          .toList();
    } catch (e) {
      printV("error fetching transactions: $e");
      rethrow;
    }
  }

  Future<List<N2Node>> getN2Reps() async {
    final uri = Uri.parse(N2_REPS_ENDPOINT);
    final response = await ProxyWrapper().post(
      clearnetUri: uri,
      headers: getHeaders(uri.host),
      body: jsonEncode({"action": "reps"}),
    );
    try {
      
      final List<N2Node> nodes = (jsonDecode(response.body) as List<dynamic>)
          .map((dynamic e) => N2Node.fromJson(e as Map<String, dynamic>))
          .toList();
      return nodes;
    } catch (error) {
      return [];
    }
  }

  Future<int> getRepScore(String rep) async {
    final uri = Uri.parse(N2_REPS_ENDPOINT);
    final response = await ProxyWrapper().post(
      clearnetUri: uri,
      headers: getHeaders(uri.host),
      body: jsonEncode({
        "action": "rep_info",
        "account": rep,
      }),
    );
    try {
      
      final N2Node node = N2Node.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      return node.score ?? 100;
    } catch (error) {
      return 100;
    }
  }
}
