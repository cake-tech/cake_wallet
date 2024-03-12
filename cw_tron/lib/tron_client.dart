import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/node.dart';
import 'package:cw_tron/pending_tron_transaction.dart';
import 'package:cw_tron/tron_abi.dart';
import 'package:cw_tron/tron_balance.dart';
import 'package:cw_tron/tron_http_provider.dart';
import 'package:cw_tron/tron_token.dart';
import 'package:cw_tron/tron_transaction_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import '.secrets.g.dart' as secrets;
import 'package:on_chain/on_chain.dart';

class TronClient {
  final httpClient = Client();
  TronProvider? _provider;

  int get chainId => 1;

  Future<List<TronTransactionModel>> fetchTransactions(String address,
      {String? contractAddress}) async {
    try {
      final response = await httpClient.get(
        Uri.https(
          "api.trongrid.io",
          "/v1/accounts/$address/transactions",
          {
            "only_confirmed": "true",
            "limit": "200",
          },
        ),
        headers: {
          'Content-Type': 'application/json',
          'TRON-PRO-API-KEY': secrets.tronGridApiKey,
        },
      );
      final jsonResponse = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          jsonResponse['status'] != false) {
        return (jsonResponse['data'] as List).map((e) {
          return TronTransactionModel.fromJson(e as Map<String, dynamic>);
        }).toList();
      }

      return [];
    } catch (e, s) {
      print('Error getting tx: ${e.toString()}\n ${s.toString()}');
      return [];
    }
  }

  Future<List<TronTRC20TransactionModel>> fetchTrc20ExcludedTransactions(String address) async {
    try {
      final response = await httpClient.get(
        Uri.https(
          "api.trongrid.io",
          "/v1/accounts/$address/transactions/trc20",
          {
            "only_confirmed": "true",
            "limit": "200",
          },
        ),
        headers: {
          'Content-Type': 'application/json',
          'TRON-PRO-API-KEY': secrets.tronGridApiKey,
        },
      );
      final jsonResponse = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          jsonResponse['status'] != false) {
        return (jsonResponse['data'] as List).map((e) {
          return TronTRC20TransactionModel.fromJson(e as Map<String, dynamic>);
        }).toList();
      }

      return [];
    } catch (e, s) {
      print('Error getting trc20 tx: ${e.toString()}\n ${s.toString()}');
      return [];
    }
  }

  bool connect(Node node) {
    try {
      final formattedUrl = '${node.isSSL ? 'https' : 'http'}://${node.uriRaw}';
      _provider = TronProvider(TronHTTPProvider(url: formattedUrl));

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<BigInt> getBalance(TronAddress address) async {
    try {
      final accountDetails = await _provider!.request(TronRequestGetAccount(address: address));

      return accountDetails?.balance ?? BigInt.zero;
    } catch (_) {
      return BigInt.zero;
    }
  }

  Future<int> getFeeLimit(
    TransactionRaw rawTransaction,
    TronAddress address,
    TronAddress receiverAddress, {
    int energyUsed = 0,
  }) async {
    try {
      // Fetch current Tron chain parameters using TronRequestGetChainParameters.
      final chainParams = await _provider!.request(TronRequestGetChainParameters());

      final bandWidthInSun = chainParams.getTransactionFee!;
      log('BandWidth In Sun: $bandWidthInSun');

      final energyInSun = chainParams.getEnergyFee!;
      log('Energy In Sun: $energyInSun');

      log(
        'Create Account Fee In System Contract for Chain: ${chainParams.getCreateNewAccountFeeInSystemContract!}',
      );
      log('Create Account Fee for Chain: ${chainParams.getCreateAccountFee}');

      final fakeTransaction = Transaction(
        rawData: rawTransaction,
        signature: [Uint8List(65)],
      );

      // Calculate the total size of the fake transaction, considering the required network overhead.
      final transactionSize = fakeTransaction.length + 64;

      // Assign the calculated size to the variable representing the required bandwidth.
      int neededBandWidth = transactionSize;
      log('Initial Needed Bandwidth: $neededBandWidth');

      // We do not require energy for this operation. Energy is reserved for smart contracts
      int neededEnergy = energyUsed;
      log('Initial Needed Energy: $neededEnergy');

      // We require account resources to assess the available bandwidth and energy
      final accountResource =
          await _provider!.request(TronRequestGetAccountResource(address: address));

      neededEnergy -= accountResource.howManyEnergy.toInt();
      log('Account resource energy: ${accountResource.howManyEnergy.toInt()}');
      log('Needed Energy after deducting from account resource energy: $neededEnergy');

      // Now, we need to deduct the bandwidth from the account's available bandwidth.
      final BigInt accountBandWidth = accountResource.howManyBandwIth;
      log('Account resource bandwidth: ${accountResource.howManyBandwIth.toInt()}');

      // If we have sufficient total bandwidth in our account, we set the total bandwidth requirement to zero.
      if (accountBandWidth >= BigInt.from(neededBandWidth)) {
        log('Account has more bandwidth than required');
        // neededBandWidth = 0;
      }

      if (neededEnergy < 0) {
        neededEnergy = 0;
      }

      final energyBurn = neededEnergy * energyInSun.toInt();
      log('Energy Burn: $energyBurn');

      final bandWidthBurn = neededBandWidth * bandWidthInSun;
      log('Bandwidth Burn: $bandWidthBurn');

      int totalBurn = energyBurn + bandWidthBurn;
      log('Total Burn: $totalBurn');

      /// If there is a note (memo), calculate the memo fee.
      if (rawTransaction.data != null) {
        totalBurn += chainParams.getMemoFee!;
      }

      // Check if the receiver account is active
      final receiverAccountInfo =
          await _provider!.request(TronRequestGetAccount(address: receiverAddress));

      /// In this scenario, we calculate the required resources for creating a new account.
      if (receiverAccountInfo == null) {
        totalBurn += chainParams.getCreateNewAccountFeeInSystemContract!;

        totalBurn += (chainParams.getCreateAccountFee! * bandWidthInSun);
      }

      log('Final total burn: $totalBurn');

      return totalBurn;
    } catch (_) {
      return 0;
    }
  }

  Future<PendingTronTransaction> signTransaction({
    required TronPrivateKey ownerPrivKey,
    required String toAddress,
    required String amount,
    required CryptoCurrency currency,
    required BigInt tronBalance,
  }) async {
    // Get the owner tron address from the key
    final ownerAddress = ownerPrivKey.publicKey().toAddress();

    // Define the receiving Tron address for the transaction.
    final receiverAddress = TronAddress(toAddress);

    bool isNativeTransaction = currency == CryptoCurrency.trx;

    TransactionRaw rawTransaction;
    if (isNativeTransaction) {
      rawTransaction = await _signNativeTransaction(
        ownerAddress,
        receiverAddress,
        amount,
        tronBalance,
      );
    } else {
      final tokenAddress = (currency as TronToken).contractAddress;

      rawTransaction = await _signTrcTokenTransaction(
        ownerAddress,
        receiverAddress,
        amount,
        tokenAddress,
        tronBalance,
      );
    }

    log('Raw transaction id: ${rawTransaction.txID}');

    final signature = ownerPrivKey.sign(rawTransaction.toBuffer());

    sendTx() async => await sendTransaction(
          rawTransaction: rawTransaction,
          signature: signature,
        );

    return PendingTronTransaction(
      signedTransaction: signature,
      amount: TronHelper.fromSun(BigInt.parse(amount)),
      fee: TronHelper.fromSun(rawTransaction.feeLimit ?? BigInt.zero),
      sendTransaction: sendTx,
    );
  }

  Future<TransactionRaw> _signNativeTransaction(
    TronAddress ownerAddress,
    TronAddress receiverAddress,
    String amount,
    BigInt tronBalance,
  ) async {
    // Fetch the latest Tron block using the TronRequestGetNowBlock API.
    final block = await _provider!.request(TronRequestGetNowBlock());

    // create transfer contract
    final contract = TransferContract(
      amount: TronHelper.toSun(amount),
      ownerAddress: ownerAddress,
      toAddress: receiverAddress,
    );

    // Prepare the contract parameter for the transaction.
    final parameter = Any(typeUrl: contract.typeURL, value: contract);

    // Create a TransactionContract object with the contract type and parameter.
    final transactionContract =
        TransactionContract(type: contract.contractType, parameter: parameter);

    // Set the transaction expiration time (maximum 24 hours)
    final expireTime = DateTime.now().toUtc().add(const Duration(hours: 24));

    // Create a raw transaction
    TransactionRaw rawTransaction = TransactionRaw(
      refBlockBytes: block.blockHeader.rawData.refBlockBytes,
      refBlockHash: block.blockHeader.rawData.refBlockHash,
      expiration: BigInt.from(expireTime.millisecondsSinceEpoch),
      contract: [transactionContract],
      timestamp: block.blockHeader.rawData.timestamp,
    );

    final feeLimit = await getFeeLimit(rawTransaction, ownerAddress, receiverAddress);

    log('Fee Limit: $feeLimit');

    final tronBalanceInt = tronBalance.toInt();
    log('Tron balance: $tronBalanceInt');

    if (feeLimit > tronBalanceInt) {
      throw Exception(
        'You don\'t have enough TRX to cover the transaction fee for this transaction. Kindly top up.',
      );
    }
    rawTransaction = rawTransaction.copyWith(
      feeLimit: BigInt.from(feeLimit),
    );

    return rawTransaction;
  }

  Future<TransactionRaw> _signTrcTokenTransaction(
    TronAddress ownerAddress,
    TronAddress receiverAddress,
    String amount,
    String contractAddress,
    BigInt tronBalance,
  ) async {
    final contract = ContractABI.fromJson(trc20Abi, isTron: true);

    final function = contract.functionFromName("transfer");

    /// address /// amount
    final transferparams = [
      receiverAddress,
      TronHelper.toSun(amount),
    ];

    final contractAddr = TronAddress(contractAddress);

    final request = await _provider!.request(
      TronRequestTriggerConstantContract(
        ownerAddress: ownerAddress,
        contractAddress: contractAddr,
        data: function.encodeHex(transferparams),
      ),
    );

    if (!request.isSuccess) {
      print("Tron TRC20 error: ${request.error} \n ${request.respose}");
    }

    print('Energy Used: ${request.energyUsed}');

    final feeLimit = await getFeeLimit(
      request.transactionRaw!,
      ownerAddress,
      receiverAddress,
      energyUsed: request.energyUsed ?? 0,
    );

    log('Fee: $feeLimit');
    final tronBalanceInt = tronBalance.toInt();
    log('Tron balance: $tronBalanceInt');

    if (feeLimit > tronBalanceInt) {
      throw Exception(
        'You don\'t have enough TRX to cover the transaction fee for this transaction. Kindly top up.',
      );
    }

    /// get transactionRaw from response and make sure set fee limit
    final rawTransaction = request.transactionRaw!.copyWith(
      feeLimit: BigInt.from(feeLimit),
    );

    return rawTransaction;
  }

  Future<String> sendTransaction({
    required TransactionRaw rawTransaction,
    required List<int> signature,
  }) async {
    try {
      final transaction = Transaction(rawData: rawTransaction, signature: [signature]);

      final raw = BytesUtils.toHexString(transaction.toBuffer());

      final txBroadcastResult = await _provider!.request(TronRequestBroadcastHex(transaction: raw));

      if (txBroadcastResult.isSuccess) {
        return txBroadcastResult.txId!;
      } else {
        throw Exception(txBroadcastResult.error);
      }
    } catch (e) {
      print('Send block Exception: ${e.toString()}');
      throw Exception(e);
    }
  }

  Future<TronBalance> fetchTronTokenBalances(String userAddress, String contractAddress) async {
    try {
      final ownerAddress = TronAddress(userAddress);

      final tokenAddress = TronAddress(contractAddress);

      final contract = ContractABI.fromJson(trc20Abi, isTron: true);

      final function = contract.functionFromName("balanceOf");

      final request = await _provider!.request(
        TronRequestTriggerConstantContract.fromMethod(
          ownerAddress: ownerAddress,
          contractAddress: tokenAddress,
          function: function,
          params: [ownerAddress],
        ),
      );

      final outputResult = request.outputResult?.first ?? BigInt.zero;

      return TronBalance(outputResult);
    } catch (_) {
      return TronBalance(BigInt.zero);
    }
  }

  Future<TronToken?> getTronToken(String contractAddress, String userAddress) async {
    try {
      final tokenAddress = TronAddress(contractAddress);

      final ownerAddress = TronAddress(userAddress);

      final contract = ContractABI.fromJson(trc20Abi, isTron: true);

      final name =
          (await getTokenDetail(contract, "name", ownerAddress, tokenAddress) as String?) ?? '';

      final symbol =
          (await getTokenDetail(contract, "symbol", ownerAddress, tokenAddress) as String?) ?? '';

      final decimal =
          (await getTokenDetail(contract, "decimals", ownerAddress, tokenAddress) as BigInt?) ??
              BigInt.zero;

      return TronToken(
        name: name,
        symbol: symbol,
        contractAddress: contractAddress,
        decimal: decimal.toInt(),
      );
    } catch (e) {
      return null;
    }
  }

  Future<dynamic> getTokenDetail(ContractABI contract, String functionName,
      TronAddress ownerAddress, TronAddress tokenAddress) async {
    final function = contract.functionFromName(functionName);

    try {
      final request = await _provider!.request(
        TronRequestTriggerConstantContract.fromMethod(
          ownerAddress: ownerAddress,
          contractAddress: tokenAddress,
          function: function,
          params: [],
        ),
      );

      final outputResult = request.outputResult?.first;

      return outputResult;
    } catch (_) {
      print('Erorr fetching detail: ${_.toString()}');

      return null;
    }
  }
}
