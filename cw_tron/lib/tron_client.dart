import 'dart:async';
import 'dart:convert';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/node.dart';
import 'package:cw_tron/pending_tron_transaction.dart';
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

  Uint8List prepareSignedTransactionForSending(Uint8List signedTransaction) => signedTransaction;

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

  Future<int> getFee(
    TransactionRaw rawTransaction,
    TronAddress address,
    TronAddress receiverAddress,
  ) async {
    try {
      // Fetch current Tron chain parameters using TronRequestGetChainParameters.
      final chainParams = await _provider!.request(TronRequestGetChainParameters());

      final fakeTransaction = Transaction(
        rawData: rawTransaction,
        signature: [Uint8List(65)],
      );

      // Calculate the total size of the fake transaction, considering the required network overhead.
      final transactionSize = fakeTransaction.length + 64;

      // Assign the calculated size to the variable representing the required bandwidth.
      int requiredBandwidth = transactionSize;

      // We do not require energy for this operation. Energy is reserved for smart contracts
      int energyNeed = 0;

      // Occasionally, when sending a transaction to an inactive account,
      // the network mandates a certain bandwidth for burning,
      // and this cannot be mitigated through account bandwidth.
      int requiredBandwidthForBurn = 0;

      // We require account resources to assess the available bandwidth and energy
      final accountResource =
          await _provider!.request(TronRequestGetAccountResource(address: address));

      // Alright, with the owner's account resources in hand,
      // we proceed to retrieve the details of the receiver's
      // account to determine its activation status. In this context,
      // if accountIsActive is null, it signifies that the account is inactive.
      final accountIsActive =
          await _provider!.request(TronRequestGetAccount(address: receiverAddress));

      // Initialize the total burn variable
      int totalBurn = 0;

      int totalBurnInSun = 0;

      /// In this scenario, we calculate the required resources for creating a new account.
      if (accountIsActive == null) {
        requiredBandwidthForBurn += chainParams.getCreateNewAccountFeeInSystemContract!;
        totalBurn += chainParams.getCreateAccountFee!;
      }

      /// If there is a note (memo), calculate the memo fee.
      /// In this instance, we have a note: "https://github.com/mrtnetwork"
      if (rawTransaction.data != null) {
        totalBurn += chainParams.getMemoFee!;
      }

      // Now, we need to deduct the bandwidth from the account's available bandwidth.
      final BigInt accountBandWidth = accountResource.howManyBandwIth;

      // If we have sufficient total bandwidth in our account, we set the total bandwidth requirement to zero.
      if (accountBandWidth >= BigInt.from(requiredBandwidth)) {
        requiredBandwidth = 0;
      }

      // Now, we add to the total burn.
      if (requiredBandwidth > 0) {
        totalBurn += requiredBandwidth * chainParams.getTransactionFee!;
      }

      // Multiply the required bandwidth by the network transaction fee to obtain the current total burn in sun
      if (requiredBandwidthForBurn > 0) {
        totalBurnInSun += requiredBandwidthForBurn * chainParams.getTransactionFee!;
      }

      return totalBurnInSun;
    } catch (_) {
      return 0;
    }
  }

  Future<PendingTronTransaction> signTransaction({
    required TronPrivateKey ownerPrivKey,
    required String toAddress,
    required String amount,
    required int gas,
    required CryptoCurrency currency,
    required int exponent,
    String? contractAddress,
  }) async {
    assert(currency == CryptoCurrency.trx || contractAddress != null);

    // Get the owner tron address from the key
    final ownerAddress = ownerPrivKey.publicKey().toAddress();

    // Fetch the latest Tron block using the TronRequestGetNowBlock API.
    final block = await _provider!.request(TronRequestGetNowBlock());

    // Define the receiving Tron address for the transaction.
    final receiverAddress = TronAddress(toAddress);

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
      data: utf8.encode("https://github.com/mrtnetwork"), // Memo or additional data
      contract: [transactionContract],
      timestamp: block.blockHeader.rawData.timestamp,
    );

    final totalBurnInSun = await getFee(rawTransaction, ownerAddress, receiverAddress);

    /// Now that we have calculated the transaction fee,
    /// it is not necessary to set the fee limit for the transaction.
    /// Fee limits are only applicable when sending smart contract transactions.
    rawTransaction = rawTransaction.copyWith(feeLimit: BigInt.from(totalBurnInSun));

    final signature = ownerPrivKey.sign(rawTransaction.toBuffer());

    sendTx() async => await sendTransaction(
          rawTransaction: rawTransaction,
          signature: signature,
        );

    return PendingTronTransaction(
      signedTransaction: signature,
      amount: amount,
      fee: BigInt.zero,
      sendTransaction: sendTx,
      exponent: exponent,
    );
  }

  Future<String> sendTransaction({
    required TransactionRaw rawTransaction,
    required List<int> signature,
  }) async {
    final transaction = Transaction(rawData: rawTransaction, signature: [signature]);

    /// get raw data buffer
    final raw = BytesUtils.toHexString(transaction.toBuffer());

    final txBroadcastResult = await _provider!.request(TronRequestBroadcastHex(transaction: raw));

    if (txBroadcastResult.isSuccess) {
      return txBroadcastResult.txId!;
    } else {
      throw Exception(txBroadcastResult.error);
    }
  }

  Future<TronBalance> fetchTronTokenBalances(String userAddress, String contractAddress) async {
    return TronBalance(BigInt.zero);
  }

  Future<TronToken?> getTronToken(String contractAddress) async {
    try {
      return TronToken(
        name: '',
        symbol: '',
        contractAddress: contractAddress,
        decimal: 10,
      );
    } catch (e) {
      return null;
    }
  }
}
