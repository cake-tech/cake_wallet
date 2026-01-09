import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/erc20_token.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_evm/evm_chain_transaction_model.dart';
import 'package:cw_evm/evm_chain_transaction_priority.dart';
import 'package:cw_evm/evm_erc20_balance.dart';
import 'package:cw_evm/pending_evm_chain_transaction.dart';
import 'package:cw_evm/.secrets.g.dart' as secrets;
import 'package:cw_evm/utils/evm_chain_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:hex/hex.dart' as hex;
import 'package:web3dart/web3dart.dart';

import '../contract/erc20.dart';

class EVMChainClient {
  late final client = ProxyWrapper().getHttpIOClient();
  Web3Client? _client;
  final int _chainId;

  EVMChainClient({required int chainId}) : _chainId = chainId;

  //! Can be overridden by child classes

  int get chainId => _chainId;

  Future<List<EVMChainTransactionModel>> fetchTransactions(String address,
      {String? contractAddress}) async {
    try {
      /// when adding new chains, make sure they are supported by the same api through https://docs.etherscan.io/supported-chains
      final response = await client.get(Uri.https("api.etherscan.io", "/v2/api", {
        "chainid": "$chainId",
        "module": "account",
        "action": contractAddress != null ? "tokentx" : "txlist",
        if (contractAddress != null) "contractaddress": contractAddress,
        "address": address,
        "apikey": secrets.etherScanApiKey,
      }));

      final jsonResponse = json.decode(response.body) as Map<String, dynamic>;

      if (jsonResponse['result'] is String) {
        log(jsonResponse['result']);
        return [];
      }

      if (response.statusCode >= 200 && response.statusCode < 300 && jsonResponse['status'] != 0) {
        final res = (jsonResponse['result'] as List);
        res.removeWhere((e) => e['value'] == '0');

        final symbol = EVMChainUtils.getFeeCurrency(chainId);

        return res
            .map(
              (e) => EVMChainTransactionModel.fromJson(e as Map<String, dynamic>, symbol, chainId),
            )
            .toList();
      }

      return [];
    } catch (e) {
      log(e.toString());
      return [];
    }
  }

  Future<List<EVMChainTransactionModel>> fetchInternalTransactions(String address) async {
    try {
      final response = await client.get(Uri.https("api.etherscan.io", "/v2/api", {
        "chainid": "$chainId",
        "module": "account",
        "action": "txlistinternal",
        "address": address,
        "apikey": secrets.etherScanApiKey,
      }));

      final jsonResponse = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300 && jsonResponse['status'] != 0) {
        final symbol = EVMChainUtils.getFeeCurrency(chainId);

        return (jsonResponse['result'] as List)
            .map((e) =>
                EVMChainTransactionModel.fromJson(e as Map<String, dynamic>, symbol, chainId))
            .toList();
      }

      return [];
    } catch (e) {
      log(e.toString());
      return [];
    }
  }

  Uint8List prepareSignedTransactionForSending(Uint8List signedTransaction) => signedTransaction;

  //! Common methods across all child classes

  bool connect(Node node) {
    try {
      Uri? rpcUri;
      bool isModifiedNodeUri = false;

      if (node.uriRaw.contains('nownodes.io')) {
        isModifiedNodeUri = true;
        String nowNodeApiKey = secrets.nowNodesApiKey;

        rpcUri = Uri.https(node.uriRaw, '/$nowNodeApiKey');
      }

      _client = Web3Client(isModifiedNodeUri ? rpcUri!.toString() : node.uri.toString(), client);

      return true;
    } catch (e) {
      return false;
    }
  }

  void setListeners(EthereumAddress userAddress, Function() onNewTransaction) async {
    // _client?.pendingTransactions().listen((transactionHash) async {
    //   final transaction = await _client!.getTransactionByHash(transactionHash);
    //
    //   if (transaction.from.hex == userAddress || transaction.to?.hex == userAddress) {
    //     onNewTransaction();
    //   }
    // });
  }

  Future<EtherAmount> getBalance(EthereumAddress address) async {
    try {
      return await _client!.getBalance(address);
    } catch (_) {
      rethrow;
    }
  }

  Future<int> getGasUnitPrice() async {
    try {
      final gasPrice = await _client!.getGasPrice();

      return gasPrice.getInWei.toInt();
    } catch (_) {
      return 0;
    }
  }

  Future<int?> getGasBaseFee() async {
    try {
      final blockInfo = await _client!.getBlockInformation(isContainFullObj: false);
      final baseFee = blockInfo.baseFeePerGas;

      return baseFee?.getInWei.toInt();
    } catch (_) {
      return 0;
    }
  }

  Future<int> getEstimatedGasUnitsForTransaction({
    required EthereumAddress toAddress,
    required EthereumAddress senderAddress,
    required EtherAmount value,
    String? contractAddress,
    EtherAmount? gasPrice,
    EtherAmount? maxFeePerGas,
    Uint8List? data,
  }) async {
    try {
      if (contractAddress == null) {
        final estimatedGas = await _client!.estimateGas(
          sender: senderAddress,
          to: toAddress,
          value: value,
          data: data,
        );

        return estimatedGas.toInt();
      } else {
        final contract = DeployedContract(
          ethereumContractAbi,
          EthereumAddress.fromHex(contractAddress),
        );

        final transfer = contract.function('transfer');

        // Estimate gas units
        final gasEstimate = await _client!.estimateGas(
          sender: senderAddress,
          to: EthereumAddress.fromHex(contractAddress),
          data: data ??
              transfer.encodeCall([
                toAddress,
                value.getInWei,
              ]),
        );

        return gasEstimate.toInt();
      }
    } catch (_) {
      return 0;
    }
  }

  Uint8List getEncodedDataForApprovalTransaction({
    required EthereumAddress toAddress,
    required EtherAmount value,
    required EthereumAddress contractAddress,
  }) {
    final contract = DeployedContract(ethereumContractAbi, contractAddress);

    final approve = contract.function('approve');

    return approve.encodeCall([
      toAddress,
      value.getInWei,
    ]);
  }

  Future<PendingEVMChainTransaction> signTransaction({
    required Credentials privateKey,
    required String toAddress,
    required BigInt amount,
    required BigInt gasFee,
    required int estimatedGasUnits,
    required int maxFeePerGas,
    required EVMChainTransactionPriority? priority,
    required CryptoCurrency currency,
    required String feeCurrency,
    required int exponent,
    String? contractAddress,
    String? data,
    int? gasPrice,
    bool useBlinkProtection = true,
  }) async {
    assert(currency == CryptoCurrency.eth ||
        currency == CryptoCurrency.maticpoly ||
        currency == CryptoCurrency.baseEth ||
        currency == CryptoCurrency.arbEth ||
        contractAddress != null);

    bool isNativeToken = currency == CryptoCurrency.eth ||
        currency == CryptoCurrency.maticpoly ||
        currency == CryptoCurrency.baseEth ||
        currency == CryptoCurrency.arbEth;

    // Get nonce with "pending" block tag to include pending transactions
    // This prevents "Nonce too low" errors when sending multiple transactions quickly
    final nonce = await _client!.getTransactionCount(
      privateKey.address,
      atBlock: const BlockNum.pending(),
    );

    final Transaction transaction = createTransaction(
      from: privateKey.address,
      to: EthereumAddress.fromHex(toAddress),
      maxPriorityFeePerGas:
          priority != null ? EtherAmount.fromInt(EtherUnit.gwei, priority.tip) : null,
      amount: isNativeToken ? EtherAmount.inWei(amount) : EtherAmount.zero(),
      data: data != null ? hexToBytes(data) : null,
      maxGas: estimatedGasUnits,
      maxFeePerGas: EtherAmount.fromInt(EtherUnit.wei, maxFeePerGas),
      gasPrice: gasPrice != null ? EtherAmount.fromInt(EtherUnit.wei, gasPrice) : null,
      nonce: nonce,
    );

    Uint8List signedTransaction;

    final Function _sendTransaction;

    if (isNativeToken) {
      signedTransaction = await _client!.signTransaction(privateKey, transaction, chainId: chainId);
    } else {
      final erc20 = ERC20(
        client: _client!,
        address: EthereumAddress.fromHex(contractAddress!),
        chainId: chainId,
      );

      signedTransaction = await erc20.transfer(
        EthereumAddress.fromHex(toAddress),
        amount,
        credentials: privateKey,
        transaction: transaction,
      );
    }

    _sendTransaction = () async =>
        await sendTransaction(signedTransaction, useBlinkProtection: useBlinkProtection);

    return PendingEVMChainTransaction(
      signedTransaction: prepareSignedTransactionForSending(signedTransaction),
      amount: amount.toString(),
      fee: gasFee,
      feeCurrency: feeCurrency,
      sendTransaction: _sendTransaction,
      exponent: exponent,
    );
  }

  Future<PendingEVMChainTransaction> signApprovalTransaction({
    required Credentials privateKey,
    required String spender,
    required BigInt amount,
    required BigInt gasFee,
    required String feeCurrency,
    required int estimatedGasUnits,
    required int maxFeePerGas,
    required EVMChainTransactionPriority? priority,
    required int exponent,
    required String contractAddress,
    int? gasPrice,
    bool useBlinkProtection = true,
  }) async {
    final nonce = await _client!.getTransactionCount(
      privateKey.address,
      atBlock: const BlockNum.pending(),
    );

    final Transaction transaction = createTransaction(
      from: privateKey.address,
      to: EthereumAddress.fromHex(contractAddress),
      maxPriorityFeePerGas:
          priority != null ? EtherAmount.fromInt(EtherUnit.gwei, priority.tip) : null,
      amount: EtherAmount.zero(),
      maxGas: estimatedGasUnits,
      maxFeePerGas: EtherAmount.fromInt(EtherUnit.wei, maxFeePerGas),
      gasPrice: gasPrice != null ? EtherAmount.fromInt(EtherUnit.wei, gasPrice) : null,
      nonce: nonce,
    );

    final erc20 = ERC20(
      client: _client!,
      address: EthereumAddress.fromHex(contractAddress),
      chainId: chainId,
    );

    final signedTransaction = await erc20.approve(
      EthereumAddress.fromHex(spender),
      amount,
      credentials: privateKey,
      transaction: transaction,
    );

    return PendingEVMChainTransaction(
      signedTransaction: prepareSignedTransactionForSending(signedTransaction),
      amount: amount.toString(),
      fee: gasFee,
      feeCurrency: feeCurrency,
      sendTransaction: () =>
          sendTransaction(signedTransaction, useBlinkProtection: useBlinkProtection),
      exponent: exponent,
      isInfiniteApproval: amount.toRadixString(16) ==
          'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff',
    );
  }

  Transaction createTransaction({
    required EthereumAddress from,
    required EthereumAddress to,
    required EtherAmount amount,
    EtherAmount? maxPriorityFeePerGas,
    EtherAmount? gasPrice,
    EtherAmount? maxFeePerGas,
    Uint8List? data,
    int? maxGas,
    int? nonce,
  }) {
    return Transaction(
      from: from,
      to: to,
      maxPriorityFeePerGas: maxPriorityFeePerGas,
      value: amount,
      data: data,
      maxGas: maxGas,
      gasPrice: gasPrice,
      maxFeePerGas: maxFeePerGas,
      nonce: nonce,
    );
  }

  String _blinkUrl(String apiKey) => 'https://eth.blinklabs.xyz/v1/$apiKey';

  Future<String> sendTransaction(
    Uint8List signedTransaction, {
    bool useBlinkProtection = false,
  }) async {
    final prepared = prepareSignedTransactionForSending(signedTransaction);

    if (useBlinkProtection && secrets.blinkApiKey.isNotEmpty) {
      final blinkClient = Web3Client(_blinkUrl(secrets.blinkApiKey), client);
      try {
        return await blinkClient.sendRawTransaction(prepared);
      } finally {
        await blinkClient.dispose();
      }
    }

    return await _client!.sendRawTransaction(prepared);
  }

  Future getTransactionDetails(String transactionHash) async {
    // Wait for the transaction receipt to become available
    TransactionReceipt? receipt;
    while (receipt == null) {
      receipt = await _client!.getTransactionReceipt(transactionHash);
      await Future.delayed(const Duration(seconds: 1));
    }

    // Print the receipt information
    log('Transaction Hash: ${receipt.transactionHash}');
    log('Block Hash: ${receipt.blockHash}');
    log('Block Number: ${receipt.blockNumber}');
    log('Gas Used: ${receipt.gasUsed}');

    /*
      Transaction Hash: [112, 244, 4, 238, 89, 199, 171, 191, 210, 236, 110, 42, 185, 202, 220, 21, 27, 132, 123, 221, 137, 90, 77, 13, 23, 43, 12, 230, 93, 63, 221, 116]
      I/flutter ( 4474): Block Hash: [149, 44, 250, 119, 111, 104, 82, 98, 17, 89, 30, 190, 25, 44, 218, 118, 127, 189, 241, 35, 213, 106, 25, 95, 195, 37, 55, 131, 185, 180, 246, 200]
      I/flutter ( 4474): Block Number: 17120242
      I/flutter ( 4474): Gas Used: 21000
    */

    // Wait for the transaction receipt to become available
    TransactionInformation? transactionInformation;
    while (transactionInformation == null) {
      log("********************************");
      transactionInformation = await _client!.getTransactionByHash(transactionHash);
      await Future.delayed(const Duration(seconds: 1));
    }
    // Print the receipt information
    log('Transaction Hash: ${transactionInformation.hash}');
    log('Block Hash: ${transactionInformation.blockHash}');
    log('Block Number: ${transactionInformation.blockNumber}');
    log('Gas Used: ${transactionInformation.gas}');

    /*
      Transaction Hash: 0x70f404ee59c7abbfd2ec6e2ab9cadc151b847bdd895a4d0d172b0ce65d3fdd74
      I/flutter ( 4474): Block Hash: 0x952cfa776f68526211591ebe192cda767fbdf123d56a195fc3253783b9b4f6c8
      I/flutter ( 4474): Block Number: 17120242
      I/flutter ( 4474): Gas Used: 53000
    */
  }

  Future<EVMChainERC20Balance> fetchERC20Balances(
      EthereumAddress userAddress, String contractAddress) async {
    try {
      final erc20 = ERC20(address: EthereumAddress.fromHex(contractAddress), client: _client!);
      final balance = await erc20.balanceOf(userAddress);

      int exponent = (await erc20.decimals()).toInt();

      return EVMChainERC20Balance(balance, exponent: exponent);
    } on RangeError catch (_) {
      throw Exception('Invalid token contract for this network.');
    } catch (e) {
      throw Exception('Could not fetch balances: ${e.toString()}');
    }
  }

  Future<Erc20Token?> getErc20Token(String contractAddress, String chainName) async {
    try {
      final token = await getErcTokenInfoFromNode(contractAddress, chainName);

      if (token == null || token.name.isEmpty || token.symbol.isEmpty) {
        return await getErc20TokenFromMoralis(contractAddress, chainName);
      }

      return token;
    } catch (e) {
      try {
        return await getErc20TokenFromMoralis(contractAddress, chainName);
      } catch (e) {
        return null;
      }
    }
  }

  Future<Erc20Token?> getErc20TokenFromMoralis(String contractAddress, String chainName) async {
    final uri = Uri.https(
      'deep-index.moralis.io',
      '/api/v2.2/erc20/metadata',
      {
        "chain": chainName,
        "addresses": contractAddress,
      },
    );

    final response = await client.get(
      uri,
      headers: {
        "Accept": "application/json",
        "X-API-Key": secrets.moralisApiKey,
      },
    );

    final decodedResponse = jsonDecode(response.body)[0] as Map<String, dynamic>;

    final symbol = (decodedResponse['symbol'] ?? '') as String;
    String filteredSymbol = symbol.replaceFirst(RegExp('^\\\$'), '');

    final name = (decodedResponse['name'] ?? '').toString();
    final decimal = decodedResponse['decimals'] ?? '0';
    final iconPath = decodedResponse['logo'] ?? '';

    return Erc20Token(
      name: name,
      symbol: filteredSymbol,
      contractAddress: contractAddress,
      decimal: int.tryParse(decimal) ?? 0,
      iconPath: iconPath,
    );
  }

  Future<Erc20Token?> getErcTokenInfoFromNode(String contractAddress, String chainName) async {
    final erc20 = ERC20(address: EthereumAddress.fromHex(contractAddress), client: _client!);
    final name = await erc20.name();
    final symbol = await erc20.symbol();
    final decimal = await erc20.decimals();

    return Erc20Token(
      name: name,
      symbol: symbol,
      contractAddress: contractAddress,
      decimal: decimal.toInt(),
    );
  }

  Uint8List hexToBytes(String hexString) {
    return Uint8List.fromList(
        hex.HEX.decode(hexString.startsWith('0x') ? hexString.substring(2) : hexString));
  }

  void stop() {
    _client?.dispose();
  }

  Web3Client? getWeb3Client() {
    return _client;
  }

// Future<int> _getDecimalPlacesForContract(DeployedContract contract) async {
//     final String abi = await rootBundle.loadString("assets/abi_json/erc20_abi.json");
//     final contractAbi = ContractAbi.fromJson(abi, "ERC20");
//
//     final contract = DeployedContract(
//       contractAbi,
//       EthereumAddress.fromHex(_erc20Currencies[erc20Currency]!),
//     );
//     final decimalsFunction = contract.function('decimals');
//     final decimals = await _client!.call(
//       contract: contract,
//       function: decimalsFunction,
//       params: [],
//     );
//
//     int exponent = int.parse(decimals.first.toString());
//     return exponent;
//   }
}
