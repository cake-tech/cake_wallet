import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:cw_core/amount/money.dart';
import 'package:cw_core/erc20_token.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_evm/evm_chain_transaction_model.dart';
import "package:cw_evm/history/evm_history_provider.dart";
import "package:cw_evm/utils/evm_chain_utils.dart";
import "package:cw_evm/utils/network_chain_utils.dart";
import 'package:cw_evm/evm_chain_transaction_priority.dart';
import 'package:cw_evm/evm_erc20_balance.dart';
import 'package:cw_evm/pending_evm_chain_transaction.dart';
import 'package:cw_evm/.secrets.g.dart' as secrets;
import 'package:flutter/foundation.dart';
import 'package:hex/hex.dart' as hex;
import "package:web3dart/crypto.dart";
import 'package:web3dart/web3dart.dart';

import '../contract/erc20.dart';

class EVMChainClient {
  EVMChainClient({
    required int chainId,
    required this.feeType,
    this.historyProvider,
  }) : _chainId = chainId;

  late final client = ProxyWrapper().getHttpIOClient();
  Web3Client? _client;
  final int _chainId;
  final FeeType feeType;
  final EvmHistoryProvider? historyProvider;

  int get chainId => _chainId;

  Future<List<EVMChainTransactionModel>> fetchTransactions(String address,
      {String? contractAddress}) async {
    final provider = historyProvider;
    if (provider == null) {
      return [];
    }

    if (contractAddress != null) {
      return provider.tokenTransfers(chainId, address, contractAddress);
    }

    return provider.transactions(chainId, address);
  }

  Future<List<EVMChainTransactionModel>> fetchInternalTransactions(String address) async =>
      await historyProvider?.internalTransactions(chainId, address) ?? [];

  Uint8List prepareSignedTransactionForSending(
    Uint8List signedTransaction, {
    required bool isType2,
  }) =>
      isType2 ? prependTransactionType(0x02, signedTransaction) : signedTransaction;

  bool connect(Node node) {
    try {
      Uri? rpcUri;
      bool isModifiedNodeUri = false;

      if (node.uriRaw.contains('nownodes.io')) {
        isModifiedNodeUri = true;
        String nowNodeApiKey = secrets.nowNodesApiKey;

        if (nowNodeApiKey.isEmpty) {
          printV('NowNodes API key is empty, cannot connect to ${node.uriRaw}');
          return false;
        }

        rpcUri = Uri.https(node.uriRaw, '/$nowNodeApiKey');
      }

      _client = Web3Client(isModifiedNodeUri ? rpcUri!.toString() : node.uri.toString(), client);

      return true;
    } catch (e) {
      printV('Error connecting to node ${node.uriRaw}: ${e.toString()}');
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
    } catch (e) {
      printV('Error getting gas unit price: ${e.toString()}');
      rethrow;
    }
  }

  Future<int?> getGasBaseFee() async {
    try {
      final blockInfo = await _client!.getBlockInformation(isContainFullObj: false);
      final baseFee = blockInfo.baseFeePerGas;

      return baseFee?.getInWei.toInt();
    } catch (e) {
      printV('Error getting gas base fee: ${e.toString()}');
      return null;
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

  bool? _hasL1FeeContract;

  static final _l1FeeContract = DeployedContract(
    ContractAbi.fromJson(
      '[{"inputs":[{"name":"_unsignedTxSize","type":"uint256"}],"name":"getL1FeeUpperBound",'
          '"outputs":[{"name":"","type":"uint256"}],"stateMutability":"view","type":"function"}]',
      "L1FeeContract",
    ),
    EthereumAddress.fromHex("0x420000000000000000000000000000000000000F"),
  );

  Future<BigInt> getL1Fee({
    required EthereumAddress toAddress,
    required EtherAmount value,
    required int gasUnits,
    required int maxFeePerGas,
    String? contractAddress,
    Uint8List? data,
  }) async {
    try {
      _hasL1FeeContract ??= (await _client!.getCode(_l1FeeContract.address)).isNotEmpty;
      if (!_hasL1FeeContract!) {
        return BigInt.zero;
      }

      final callData = contractAddress == null
          ? data
          : data ??
              DeployedContract(ethereumContractAbi, EthereumAddress.fromHex(contractAddress))
                  .function("transfer")
                  .encodeCall([toAddress, value.getInWei]);
      final unsignedTransaction = Transaction(
        to: contractAddress == null ? toAddress : EthereumAddress.fromHex(contractAddress),
        value: contractAddress == null ? value : EtherAmount.zero(),
        data: callData ?? Uint8List(0),
        nonce: 0,
        maxGas: gasUnits,
        maxFeePerGas: EtherAmount.fromInt(EtherUnit.wei, maxFeePerGas),
        maxPriorityFeePerGas: EtherAmount.zero(),
      ).getUnsignedSerialized(chainId: chainId);

      final result = await _client!.call(
        contract: _l1FeeContract,
        function: _l1FeeContract.function("getL1FeeUpperBound"),
        params: [BigInt.from(unsignedTransaction.length)],
      );
      return result.first as BigInt;
    } catch (e) {
      printV("L1 fee lookup failed on chain $chainId: $e");
      return BigInt.zero;
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
    required Money amount,
    required Money gasFee,
    required int estimatedGasUnits,
    required GasParamsHandler gasParams,
    required String feeCurrency,
    String? contractAddress,
    String? data,
    bool useBlinkProtection = true,
  }) async {
    final isNativeToken = contractAddress == null;

    // Get nonce with "pending" block tag to include pending transactions
    // This prevents "Nonce too low" errors when sending multiple transactions quickly
    final nonce = await _client!.getTransactionCount(
      privateKey.address,
      atBlock: const BlockNum.pending(),
    );

    final Transaction transaction = createTransaction(
      from: privateKey.address,
      to: EthereumAddress.fromHex(toAddress),
      amount: isNativeToken ? EtherAmount.inWei(amount.amount) : EtherAmount.zero(),
      data: data != null ? hexToBytes(data) : null,
      maxGas: estimatedGasUnits,
      gasParams: gasParams,
      nonce: nonce,
    );

    Uint8List signedTransaction;

    if (isNativeToken) {
      signedTransaction = await _client!.signTransaction(privateKey, transaction, chainId: chainId);
    } else {
      final erc20 = ERC20(
        client: _client!,
        address: EthereumAddress.fromHex(contractAddress),
        chainId: chainId,
      );

      signedTransaction = await erc20.transfer(
        EthereumAddress.fromHex(toAddress),
        amount.amount,
        credentials: privateKey,
        transaction: transaction,
      );
    }

    final preparedTx =
        prepareSignedTransactionForSending(signedTransaction, isType2: transaction.isEIP1559);

    return PendingEVMChainTransaction(
      signedTransaction: preparedTx,
      amount: amount,
      fee: gasFee,
      nonce: nonce,
      sendTransaction: () async =>
          await sendTransaction(preparedTx, useBlinkProtection: useBlinkProtection),
    );
  }

  Future<PendingEVMChainTransaction> signApprovalTransaction({
    required Credentials privateKey,
    required String spender,
    required Money amount,
    required Money gasFee,
    required int estimatedGasUnits,
    required GasParamsHandler gasParams,
    required String contractAddress,
    bool useBlinkProtection = true,
  }) async {
    final nonce = await _client!.getTransactionCount(
      privateKey.address,
      atBlock: const BlockNum.pending(),
    );

    final Transaction transaction = createTransaction(
      from: privateKey.address,
      to: EthereumAddress.fromHex(contractAddress),
      amount: EtherAmount.zero(),
      maxGas: estimatedGasUnits,
      gasParams: gasParams,
      nonce: nonce,
    );

    final erc20 = ERC20(
      client: _client!,
      address: EthereumAddress.fromHex(contractAddress),
      chainId: chainId,
    );

    final signedTransaction = await erc20.approve(
      EthereumAddress.fromHex(spender),
      amount.amount,
      credentials: privateKey,
      transaction: transaction,
    );

    final preparedTx =
        prepareSignedTransactionForSending(signedTransaction, isType2: transaction.isEIP1559);

    return PendingEVMChainTransaction(
      signedTransaction: preparedTx,
      amount: amount,
      fee: gasFee,
      nonce: nonce,
      sendTransaction: () => sendTransaction(preparedTx, useBlinkProtection: useBlinkProtection),
      isInfiniteApproval: amount.amount.toRadixString(16) ==
          'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff',
    );
  }

  // web3dart signs type-2 whenever a max fee field is set, so the legacy body sets only gasPrice
  Transaction createTransaction({
    required EthereumAddress from,
    required EthereumAddress to,
    required EtherAmount amount,
    required GasParamsHandler gasParams,
    Uint8List? data,
    int? maxGas,
    int? nonce,
  }) {
    final isLegacy = switch (feeType) {
      FeeType.legacy => true,
      FeeType.eip1559 => false,
      FeeType.eip1559OrLegacy => !gasParams.hasEip1559Fees,
    };

    if (isLegacy) {
      return Transaction(
        from: from,
        to: to,
        value: amount,
        data: data,
        maxGas: maxGas,
        gasPrice: EtherAmount.fromInt(EtherUnit.wei, gasParams.maxFeePerGas),
        nonce: nonce,
      );
    }

    return Transaction(
      from: from,
      to: to,
      value: amount,
      data: data,
      maxGas: maxGas,
      maxFeePerGas: EtherAmount.fromInt(EtherUnit.wei, gasParams.maxFeePerGas),
      maxPriorityFeePerGas: EtherAmount.fromInt(EtherUnit.wei, gasParams.priorityFeeWei ?? 0),
      nonce: nonce,
    );
  }

  Future<int?> fetchPriorityFeeFromNode(EVMChainTransactionPriority priority, int? baseFee) async {
    if (baseFee == null) {
      return 0;
    }

    try {
      final history = await _client!.getFeeHistory(
        _feeHistoryBlockCount,
        atBlock: const BlockNum.current(),
        rewardPercentiles: _feeHistoryPercentiles,
      );

      final rewards = history["reward"];
      if (rewards is List) {
        final medianReward = priorityFeeFromFeeHistory(
          rewards
              .whereType<List<dynamic>>()
              .map((row) => row.whereType<BigInt>().toList())
              .toList(),
          priority,
        );
        final tip = medianReward == null ? null : boundedPriorityFee(medianReward, baseFee);

        if (tip != null) {
          return tip;
        }

        printV("eth_feeHistory on chain $chainId gave no usable tip: $medianReward");
      }
    } catch (e) {
      printV("eth_feeHistory failed on chain $chainId: $e");
    }

    try {
      final maxPriorityFee = await _client!.makeRPCCall<String>("eth_maxPriorityFeePerGas");
      final tip = boundedPriorityFee(hexToInt(maxPriorityFee), baseFee);
      if (tip != null) {
        return tip;
      }

      printV("eth_maxPriorityFeePerGas on chain $chainId is out of bounds: $maxPriorityFee");
    } catch (e) {
      printV("eth_maxPriorityFeePerGas failed on chain $chainId: $e");
    }

    return null;
  }

  Future<TransactionReceipt?> getTransactionReceipt(String hash) =>
      _client!.getTransactionReceipt(hash);

  Future<TransactionInformation?> getTransactionByHash(String hash) =>
      _client!.getTransactionByHash(hash);

  Future<int> getBlockNumber() => _client!.getBlockNumber();

  Future<int> getConfirmedTransactionCount(EthereumAddress address) =>
      _client!.getTransactionCount(address, atBlock: const BlockNum.current());

  String _blinkUrl(String apiKey) => 'https://eth.blinklabs.xyz/v1/$apiKey';

  Future<String> sendTransaction(
    Uint8List prepared, {
    bool useBlinkProtection = false,
  }) async {
    if (useBlinkProtection && secrets.blinkApiKey.isNotEmpty) {
      final blinkClient = Web3Client(_blinkUrl(secrets.blinkApiKey), client);
      try {
        return await blinkClient.sendRawTransaction(prepared);
      } catch (e) {
        printV('Blink failed, retrying without Blink: $e');
        return await _client!.sendRawTransaction(prepared);
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
      EthereumAddress userAddress, Erc20Token token) async {
    try {
      final erc20 =
          ERC20(address: EthereumAddress.fromHex(token.contractAddress), client: _client!);
      final balance = await erc20.balanceOf(userAddress);

      return EVMChainERC20Balance(Money(balance, token));
    } on RangeError catch (_) {
      throw Exception('Invalid token contract for this network.');
    } catch (e) {
      if (e.toString().contains("hostUnreachable")) {
        return EVMChainERC20Balance(Money.zero(token));
      }
      throw Exception('Could not fetch balances: ${e.toString()}');
    }
  }

  Future<Erc20Token?> getErc20Token(String contractAddress) async {
    try {
      final token = await getErc20TokenFromMoralis(contractAddress);

      if (token == null || token.name.isEmpty || token.symbol.isEmpty) {
        return await getErcTokenInfoFromNode(contractAddress);
      }

      return token;
    } catch (e) {
      try {
        return await getErcTokenInfoFromNode(contractAddress);
      } catch (e) {
        return null;
      }
    }
  }

  Future<Erc20Token?> getErc20TokenFromMoralis(String contractAddress) async {
    if (secrets.moralisApiKey.isEmpty) {
      printV('Moralis API key is empty, cannot fetch token info');
      return null;
    }
    final uri = Uri.https(
      'deep-index.moralis.io',
      '/api/v2.2/erc20/metadata',
      {
        "chain": EVMChainUtils.hexChainId(chainId),
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

  Future<Erc20Token?> getErcTokenInfoFromNode(String contractAddress) async {
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

  Future<List<MoralisWalletTokenBalance>> fetchWalletTokensFromMoralis(String address) async {
    try {
      if (secrets.moralisApiKey.isEmpty) {
        printV('Moralis API key is empty, cannot fetch wallet tokens');
        return [];
      }

      const maxPages = 3;
      String? cursor;
      int pageCount = 0;
      final List<MoralisWalletTokenBalance> tokens = [];

      do {
        final params = <String, String>{
          "chain": EVMChainUtils.hexChainId(chainId),
          if (cursor != null && cursor.isNotEmpty) "cursor": cursor,
        };

        final uri = Uri.https(
          'deep-index.moralis.io',
          '/api/v2.2/wallets/$address/tokens',
          params,
        );

        final response = await client.get(
          uri,
          headers: {
            "Accept": "application/json",
            "X-API-Key": secrets.moralisApiKey,
          },
        );

        if (response.statusCode < 200 || response.statusCode >= 300) {
          printV('Moralis API returned invalid status code: ${response.statusCode}');
          return tokens;
        }

        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) return tokens;

        final result = decoded['result'];
        if (result is! List) return tokens;

        for (final item in result) {
          if (item is! Map<String, dynamic>) continue;
          final tokenData = item;

          final nativeRaw = tokenData['native_token'];
          final nativeToken =
              nativeRaw is bool ? nativeRaw : (nativeRaw?.toString().toLowerCase() == 'true');
          if (nativeToken) continue;

          final balanceStr = tokenData['balance'] as String? ?? '0';
          final balanceWei = BigInt.tryParse(balanceStr) ?? BigInt.zero;
          if (balanceWei == BigInt.zero) continue;

          final contractAddress = (tokenData['token_address'] as String? ?? '').toLowerCase();
          final name = (tokenData['name'] as String? ?? '').toString();
          final symbol = (tokenData['symbol'] as String? ?? '').toString();
          final symbolFiltered = symbol.replaceFirst(RegExp('^\\\$'), '');

          final decimalsRaw = tokenData['decimals'];
          final decimals =
              decimalsRaw is int ? decimalsRaw : int.tryParse(decimalsRaw.toString()) ?? 18;

          final logo = tokenData['logo'] as String?;
          final thumbnail = tokenData['thumbnail'] as String?;
          final iconUrl = logo ?? thumbnail;

          final possibleSpamRaw = tokenData['possible_spam'];
          final possibleSpam = possibleSpamRaw is bool
              ? possibleSpamRaw
              : (possibleSpamRaw?.toString().toLowerCase() == 'true');

          final verifiedContractRaw = tokenData['verified_contract'];
          final verifiedContract = verifiedContractRaw is bool
              ? verifiedContractRaw
              : (verifiedContractRaw?.toString().toLowerCase() == 'true');

          final usdPriceRaw = tokenData['usd_price'];
          final double? usdPrice = usdPriceRaw is num
              ? usdPriceRaw.toDouble()
              : (usdPriceRaw is String ? double.tryParse(usdPriceRaw) : null);

          final usdValueRaw = tokenData['usd_value'];
          final double? usdValue = usdValueRaw is num
              ? usdValueRaw.toDouble()
              : (usdValueRaw is String ? double.tryParse(usdValueRaw) : null);

          final securityRaw = tokenData['security_score'];
          final int? securityScore = securityRaw is int
              ? securityRaw
              : (securityRaw is num
                  ? securityRaw.toInt()
                  : (securityRaw is String ? int.tryParse(securityRaw) : null));

          tokens.add(
            MoralisWalletTokenBalance(
              contractAddress: contractAddress,
              name: name,
              symbol: symbolFiltered,
              decimals: decimals,
              iconUrl: iconUrl,
              balanceWei: balanceWei,
              possibleSpam: possibleSpam,
              verifiedContract: verifiedContract,
              usdPrice: usdPrice,
              usdValue: usdValue,
              securityScore: securityScore,
            ),
          );
        }

        final nextCursor = decoded['cursor'];
        cursor = nextCursor is String && nextCursor.isNotEmpty ? nextCursor : null;
        pageCount++;
      } while (cursor != null && pageCount < maxPages);

      return tokens;
    } catch (e, stackTrace) {
      printV('Error fetching wallet tokens from Moralis: ${e.toString()}');
      printV('Stack trace: ${stackTrace.toString()}');
      return [];
    }
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

const _feeHistoryBlockCount = 10;
const _feeHistoryPercentiles = [25.0, 50.0, 75.0];

BigInt? priorityFeeFromFeeHistory(
  List<List<BigInt>> rewards,
  EVMChainTransactionPriority priority,
) {
  final column = switch (priority) {
    EVMChainTransactionPriority.slow => 0,
    EVMChainTransactionPriority.fast => 2,
    _ => 1,
  };

  final values = rewards.where((row) => row.length > column).map((row) => row[column]).toList()
    ..sort();
  if (values.isEmpty) {
    return null;
  }

  final middle = values.length ~/ 2;
  if (values.length.isOdd) {
    return values[middle];
  }

  return (values[middle - 1] + values[middle]) ~/ BigInt.two;
}

final _maxPriorityFeeBaseFeeMultiple = BigInt.from(10);
final _maxPriorityFeeFloorWei = BigInt.from(100000000000);

/// Returns the node's tip in wei, null when it is negative or above the bound
int? boundedPriorityFee(BigInt tip, int baseFee) {
  final baseFeeMultiple = BigInt.from(baseFee) * _maxPriorityFeeBaseFeeMultiple;
  final bound =
      baseFeeMultiple > _maxPriorityFeeFloorWei ? baseFeeMultiple : _maxPriorityFeeFloorWei;

  if (tip.isNegative || tip > bound || !tip.isValidInt) {
    return null;
  }

  return tip.toInt();
}

class GasParamsHandler {
  final int estimatedGasUnits;
  final int estimatedGasFee;
  final int maxFeePerGas;
  final int? priorityFeeWei;
  final bool hasBaseFee;

  GasParamsHandler({
    required this.estimatedGasUnits,
    required this.estimatedGasFee,
    required this.maxFeePerGas,
    required this.priorityFeeWei,
    required this.hasBaseFee,
  });

  bool get hasEip1559Fees => hasBaseFee && priorityFeeWei != null;

  static GasParamsHandler zero() => GasParamsHandler(
        estimatedGasUnits: 0,
        estimatedGasFee: 0,
        maxFeePerGas: 0,
        priorityFeeWei: 0,
        hasBaseFee: false,
      );
}

class MoralisWalletTokenBalance {
  final String contractAddress;
  final String name;
  final String symbol;
  final int decimals;
  final String? iconUrl;
  final BigInt balanceWei;
  final bool possibleSpam;
  final bool verifiedContract;
  final double? usdPrice;
  final double? usdValue;
  final int? securityScore;

  MoralisWalletTokenBalance({
    required this.contractAddress,
    required this.name,
    required this.symbol,
    required this.decimals,
    this.iconUrl,
    required this.balanceWei,
    required this.possibleSpam,
    required this.verifiedContract,
    this.usdPrice,
    this.usdValue,
    this.securityScore,
  });
}
