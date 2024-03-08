import 'dart:async';
import 'dart:convert';

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
import 'package:on_chain/on_chain.dart';

class TronClient {
  final httpClient = Client();
  TronProvider? _provider;

  int get chainId => 137;

  Future<List<TronTransactionModel>> fetchTransactions(String address,
      {String? contractAddress}) async {
    try {
      final response = await httpClient.get(Uri.https("api.polygonscan.com", "/api", {
        "module": "account",
        "action": contractAddress != null ? "tokentx" : "txlist",
        if (contractAddress != null) "contractaddress": contractAddress,
        "address": address,
        "apikey": 'secrets.polygonScanApiKey',
      }));

      final jsonResponse = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300 && jsonResponse['status'] != 0) {
        return (jsonResponse['result'] as List)
            .map(
              (e) => TronTransactionModel.fromJson(e as Map<String, dynamic>, 'MATIC'),
            )
            .toList();
      }

      return [];
    } catch (e) {
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
      print('BandWidth In Sun: $bandWidthInSun');

      final energyInSun = chainParams.getEnergyFee!;
      print('Energy In Sun: $energyInSun');

      print(
        'Create Account Fee In System Contract for Chain: ${chainParams.getCreateNewAccountFeeInSystemContract!}',
      );
      print('Create Account Fee for Chain: ${chainParams.getCreateAccountFee}');

      final fakeTransaction = Transaction(
        rawData: rawTransaction,
        signature: [Uint8List(65)],
      );

      // Calculate the total size of the fake transaction, considering the required network overhead.
      final transactionSize = fakeTransaction.length + 64;

      // Assign the calculated size to the variable representing the required bandwidth.
      int neededBandWidth = transactionSize;
      print('Initial Needed Bandwidth: $neededBandWidth');

      // We do not require energy for this operation. Energy is reserved for smart contracts
      int neededEnergy = energyUsed;
      print('Initial Needed Energy: $neededEnergy');

      // We require account resources to assess the available bandwidth and energy
      final accountResource =
          await _provider!.request(TronRequestGetAccountResource(address: address));

      neededEnergy -= accountResource.howManyEnergy.toInt();
      print('Account resource energy: ${accountResource.howManyEnergy.toInt()}');
      print('Needed Energy after deducting from account resource energy: $neededEnergy');

      // Now, we need to deduct the bandwidth from the account's available bandwidth.
      final BigInt accountBandWidth = accountResource.howManyBandwIth;
      print('Account resource bandwidth: ${accountResource.howManyBandwIth.toInt()}');

      // If we have sufficient total bandwidth in our account, we set the total bandwidth requirement to zero.
      if (accountBandWidth >= BigInt.from(neededBandWidth)) {
        print('Account has more bandwidth than required');
        neededBandWidth = 0;
      }

      if (neededEnergy < 0) {
        neededEnergy = 0;
      }

      final energyBurn = neededEnergy * energyInSun.toInt();
      print('Energy Burn: $energyBurn');

      final bandWidthBurn = neededBandWidth * bandWidthInSun;
      print('Bandwidth Burn: $bandWidthBurn');

      int totalBurn = energyBurn + bandWidthBurn;
      print('Total Burn: $totalBurn');

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

      print('Final total burn: $totalBurn');

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
      );
    } else {
      final tokenAddress = (currency as TronToken).contractAddress;

      rawTransaction = await _signTrcTokenTransaction(
        ownerAddress,
        receiverAddress,
        amount,
        tokenAddress,
      );
    }

    print('Raw transaction id: ${rawTransaction.txID}');

    final signature = ownerPrivKey.sign(rawTransaction.toBuffer());

    sendTx() async => await sendTransaction(
          rawTransaction: rawTransaction,
          signature: signature,
        );

    return PendingTronTransaction(
      signedTransaction: signature,
      amount: amount,
      //TODO: We need the fee!
      fee: '',
      sendTransaction: sendTx,
    );
  }

  Future<TransactionRaw> _signNativeTransaction(
    TronAddress ownerAddress,
    TronAddress receiverAddress,
    String amount,
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

    print('Native transaction Fee Limit: $feeLimit');

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

    print('TRC20 Transaction Fee Limit: $feeLimit');

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
          (await _getTokenDetail(contract, "name", ownerAddress, tokenAddress) as String?) ?? '';

      final symbol =
          (await _getTokenDetail(contract, "symbol", ownerAddress, tokenAddress) as String?) ?? '';

      final decimal =
          (await _getTokenDetail(contract, "decimals", ownerAddress, tokenAddress) as BigInt?) ??
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

  Future<dynamic> _getTokenDetail(ContractABI contract, String functionName,
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
