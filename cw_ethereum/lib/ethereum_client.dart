import 'dart:async';
import 'dart:math';

import 'package:cw_core/crypto_currency.dart';
import 'package:cw_ethereum/ethereum_balance.dart';
import 'package:cw_ethereum/pending_ethereum_transaction.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web3dart/contracts/erc20.dart';
import 'package:cw_core/node.dart';
import 'package:cw_ethereum/ethereum_transaction_priority.dart';

class EthereumClient {
  static const Map<CryptoCurrency, String> _erc20Currencies = {
    CryptoCurrency.usdc: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
    CryptoCurrency.usdterc20: "0xdac17f958d2ee523a2206206994597c13d831ec7",
    CryptoCurrency.shib: "0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE",
  };

  Map<CryptoCurrency, String> get erc20Currencies => _erc20Currencies;

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
    //     print("!!!!!!!!!!!!!!!!!!");
    //     print('Address ${event.address} data ${event.data} tx hash ${event.transactionHash}!');
    //     onNewTransaction(event);
    // });

    // final erc20 = Erc20(client: _client!, address: userAddress);
    //
    // subscription = erc20.transferEvents().take(1).listen((event) {
    //   print("!!!!!!!!!!!!!!!!!!");
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
  }) async {
    bool _isEthereum = currency == CryptoCurrency.eth;
    final estimatedGas = BigInt.from(_isEthereum ? 21000 : 50000);

    final price = await _client!.getGasPrice();

    final Transaction transaction = Transaction(
      from: privateKey.address,
      to: EthereumAddress.fromHex(toAddress),
      maxGas: gas,
      gasPrice: price,
      value: _isEthereum ? EtherAmount.inWei(BigInt.parse(amount)) : EtherAmount.zero(),
    );

    final signedTransaction = await _client!.signTransaction(privateKey, transaction);

    final Function _sendTransaction;

    if (_isEthereum) {
      _sendTransaction = () async => await sendTransaction(signedTransaction);
    } else {
      final erc20 = Erc20(
        client: _client!,
        address: EthereumAddress.fromHex(_erc20Currencies[currency]!),
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
      print("&&&&&&&&&&&&&&&&&&&&&&&&&&&&&");
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

  Future<Map<CryptoCurrency, ERC20Balance>> fetchERC20Balances(EthereumAddress userAddress) async {
    final Map<CryptoCurrency, ERC20Balance> erc20Balances = {};

    for (var currency in _erc20Currencies.keys) {
      final contractAddress = _erc20Currencies[currency]!;

      try {
        final erc20 = Erc20(address: EthereumAddress.fromHex(contractAddress), client: _client!);
        final balance = await erc20.balanceOf(userAddress);

        int exponent = (await erc20.decimals()).toInt();

        erc20Balances[currency] = ERC20Balance(balance, exponent: exponent);
      } catch (e) {
        continue;
      }
    }

    return erc20Balances;
  }

  void stop() {
    subscription?.cancel();
    _client?.dispose();
  }

// Future<bool> sendERC20Token(
//     EthereumAddress to, CryptoCurrency erc20Currency, BigInt amount) async {
//   if (_erc20Currencies[erc20Currency] == null) {
//     throw "Unsupported ERC20 token";
//   }
//
//   try {
//     final String abi = await rootBundle.loadString("assets/abi_json/erc20_abi.json");
//     final contractAbi = ContractAbi.fromJson(abi, "ERC20");
//
//     final contract = DeployedContract(
//       contractAbi,
//       EthereumAddress.fromHex(_erc20Currencies[erc20Currency]!),
//     );
//
//     final transferFunction = contract.function('transfer');
//     final success = await _client!.call(
//       contract: contract,
//       function: transferFunction,
//       params: [to, amount],
//     );
//
//     return success.first as bool;
//   } catch (e) {
//     return false;
//   }
// }
//
// Future<int> _getDecimalPlacesForContract(DeployedContract contract) async {
//   final decimalsFunction = contract.function('decimals');
//   final decimals = await _client!.call(
//     contract: contract,
//     function: decimalsFunction,
//     params: [],
//   );
//
//   int exponent = int.parse(decimals.first.toString());
//   return exponent;
// }
}
