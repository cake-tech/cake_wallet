import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cw_core/crypto_currency.dart';
import 'package:cw_ethereum/erc20_balance.dart';
import 'package:cw_core/erc20_token.dart';
import 'package:cw_ethereum/ethereum_transaction_model.dart';
import 'package:cw_ethereum/pending_ethereum_transaction.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web3dart/contracts/erc20.dart';
import 'package:cw_core/node.dart';
import 'package:cw_ethereum/ethereum_transaction_priority.dart';
import 'package:cw_ethereum/.secrets.g.dart' as secrets;

class EthereumClient {
  Web3Client? _client;
  StreamSubscription<Transfer>? subscription;

  bool connect(Node node) {
    try {
      _client = Web3Client(node.uri.toString(), Client());

      return true;
    } catch (e) {
      return false;
    }
  }

  void setListeners(EthereumAddress userAddress, Function(FilterEvent) onNewTransaction) async {
    // final String abi = await rootBundle.loadString("assets/abi_json/erc20_abi.json");
    // final contractAbi = ContractAbi.fromJson(abi, "ERC20");
    //
    // final contract = DeployedContract(
    //   contractAbi,
    //   EthereumAddress.fromHex("0xf451659CF5688e31a31fC3316efbcC2339A490Fb"),
    // );
    //
    // final transferEvent = contract.event('Transfer');
    // // listen for the Transfer event when it's emitted by the contract above
    // final subscription = _client!
    //     .events(FilterOptions.events(contract: contract, event: transferEvent))
    //     .take(1)
    //     .listen((event) {
    //   final decoded = transferEvent.decodeResults(event.topics ?? [], event.data ?? '');
    //
    //   final from = decoded[0] as EthereumAddress;
    //   final to = decoded[1] as EthereumAddress;
    //   final value = decoded[2] as BigInt;
    //
    //   print('$from sent $value MetaCoins to $to');
    // });

    // final eventFilter = FilterOptions(address: userAddress);
    //
    // _client!.events(eventFilter).listen((event) {
    //     print('Address ${event.address} data ${event.data} tx hash ${event.transactionHash}!');
    //     onNewTransaction(event);
    // });

    // final erc20 = Erc20(client: _client!, address: userAddress);
    //
    // subscription = erc20.transferEvents().take(1).listen((event) {
    //   print('${event.from} sent ${event.value} MetaCoins to ${event.to}!');
    //   onNewTransaction(event);
    // });
  }

  Future<EtherAmount> getBalance(EthereumAddress address) async =>
      await _client!.getBalance(address);

  Future<int> getGasUnitPrice() async {
    final gasPrice = await _client!.getGasPrice();
    return gasPrice.getInWei.toInt();
  }

  Future<List<int>> getEstimatedGasForPriorities() async {
    // TODO: there is no difference, find out why
    // [53000, 53000, 53000]
    final result = await Future.wait(EthereumTransactionPriority.all.map(
      (priority) => _client!.estimateGas(
          // maxPriorityFeePerGas: EtherAmount.fromUnitAndValue(EtherUnit.gwei, priority.tip),
          // maxFeePerGas: EtherAmount.fromUnitAndValue(EtherUnit.gwei, priority.tip),
          ),
    ));

    return result.map((e) => e.toInt()).toList();
  }

  Future<PendingEthereumTransaction> signTransaction({
    required EthPrivateKey privateKey,
    required String toAddress,
    required String amount,
    required int gas,
    required EthereumTransactionPriority priority,
    required CryptoCurrency currency,
    String? contractAddress,
  }) async {
    assert(currency == CryptoCurrency.eth || contractAddress != null);

    bool _isEthereum = currency == CryptoCurrency.eth;

    final price = await _client!.getGasPrice();

    final Transaction transaction = Transaction(
      from: privateKey.address,
      to: EthereumAddress.fromHex(toAddress),
      maxGas: gas,
      gasPrice: price,
      value: _isEthereum ? EtherAmount.inWei(BigInt.parse(amount)) : EtherAmount.zero(),
    );

    final signedTransaction = await _client!.signTransaction(privateKey, transaction);

    final estimatedGas;
    final Function _sendTransaction;

    if (_isEthereum) {
      estimatedGas = BigInt.from(21000);
      _sendTransaction = () async => await sendTransaction(signedTransaction);
    } else {
      estimatedGas = BigInt.from(50000);

      final erc20 = Erc20(
        client: _client!,
        address: EthereumAddress.fromHex(contractAddress!),
      );

      final originalAmount = BigInt.parse(amount) / BigInt.from(pow(10, 18));
      final int exponent = (await erc20.decimals()).toInt();
      final _amount = BigInt.from(originalAmount * pow(10, exponent));

      _sendTransaction = () async {
        await erc20.transfer(
          EthereumAddress.fromHex(toAddress),
          _amount,
          credentials: privateKey,
        );
      };
    }

    return PendingEthereumTransaction(
      signedTransaction: signedTransaction,
      amount: amount,
      fee: estimatedGas * price.getInWei,
      sendTransaction: _sendTransaction,
    );
  }

  Future<String> sendTransaction(Uint8List signedTransaction) async =>
      await _client!.sendRawTransaction(signedTransaction);

  Future getTransactionDetails(String transactionHash) async {
    // Wait for the transaction receipt to become available
    TransactionReceipt? receipt;
    while (receipt == null) {
      receipt = await _client!.getTransactionReceipt(transactionHash);
      await Future.delayed(Duration(seconds: 1));
    }

    // Print the receipt information
    print('Transaction Hash: ${receipt.transactionHash}');
    print('Block Hash: ${receipt.blockHash}');
    print('Block Number: ${receipt.blockNumber}');
    print('Gas Used: ${receipt.gasUsed}');

    /*
      Transaction Hash: [112, 244, 4, 238, 89, 199, 171, 191, 210, 236, 110, 42, 185, 202, 220, 21, 27, 132, 123, 221, 137, 90, 77, 13, 23, 43, 12, 230, 93, 63, 221, 116]
I/flutter ( 4474): Block Hash: [149, 44, 250, 119, 111, 104, 82, 98, 17, 89, 30, 190, 25, 44, 218, 118, 127, 189, 241, 35, 213, 106, 25, 95, 195, 37, 55, 131, 185, 180, 246, 200]
I/flutter ( 4474): Block Number: 17120242
I/flutter ( 4474): Gas Used: 21000
       */

    // Wait for the transaction receipt to become available
    TransactionInformation? transactionInformation;
    while (transactionInformation == null) {
      print("********************************");
      transactionInformation = await _client!.getTransactionByHash(transactionHash);
      await Future.delayed(Duration(seconds: 1));
    }
    // Print the receipt information
    print('Transaction Hash: ${transactionInformation.hash}');
    print('Block Hash: ${transactionInformation.blockHash}');
    print('Block Number: ${transactionInformation.blockNumber}');
    print('Gas Used: ${transactionInformation.gas}');

    /*
      Transaction Hash: 0x70f404ee59c7abbfd2ec6e2ab9cadc151b847bdd895a4d0d172b0ce65d3fdd74
I/flutter ( 4474): Block Hash: 0x952cfa776f68526211591ebe192cda767fbdf123d56a195fc3253783b9b4f6c8
I/flutter ( 4474): Block Number: 17120242
I/flutter ( 4474): Gas Used: 53000
       */
  }

// Future<List<Transaction>> fetchTransactions(String address) async {
//   get(Uri.https(
//     "https://api.etherscan.io",
//     "api/",
//     {
//       "module": "account",
//       "action": "txlist",
//       "address": address,
//       "apikey": secrets.,
//     },
//   ));
// }

  Future<ERC20Balance> fetchERC20Balances(
      EthereumAddress userAddress, String contractAddress) async {
    final erc20 = Erc20(address: EthereumAddress.fromHex(contractAddress), client: _client!);
    final balance = await erc20.balanceOf(userAddress);

    int exponent = (await erc20.decimals()).toInt();

    return ERC20Balance(balance, exponent: exponent);
  }

  Future<Erc20Token?> getErc20Token(String contractAddress) async {
    try {
      final erc20 = Erc20(address: EthereumAddress.fromHex(contractAddress), client: _client!);
      final name = await erc20.name();
      final symbol = await erc20.symbol();
      final decimal = await erc20.decimals();

      return Erc20Token(
        name: name,
        symbol: symbol,
        contractAddress: contractAddress,
        decimal: decimal.toInt(),
      );
    } catch (e) {
      return null;
    }
  }

  void stop() {
    subscription?.cancel();
    _client?.dispose();
  }

  Future<List<EthereumTransactionModel>> fetchTransactions(String address,
      {String? contractAddress}) async {
    final client = Client();

    final response = await client.get(Uri.https("api.etherscan.io", "/api", {
      "module": "account",
      "action": contractAddress != null ? "tokentx" : "txlist",
      if (contractAddress != null) "contractaddress": contractAddress,
      "address": address,
      "apikey": secrets.etherScanApiKey,
    }));

    final _jsonResponse = json.decode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300 && _jsonResponse['status'] != 0) {
      return (_jsonResponse['result'] as List)
          .map((e) => EthereumTransactionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return [];
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
