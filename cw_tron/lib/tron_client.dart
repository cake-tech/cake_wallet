import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/currency.dart';
import "package:cw_core/exceptions/cake_exception.dart";
import 'package:cw_core/node.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_tron/default_tron_tokens.dart';
import 'package:cw_tron/hardware/tron_ledger_app.dart';
import 'package:cw_tron/pending_tron_transaction.dart';
import 'package:cw_tron/tron_abi.dart';
import 'package:cw_tron/tron_balance.dart';
import 'package:cw_tron/tron_http_provider.dart';
import 'package:cw_core/tron_token.dart';
import 'package:cw_tron/tron_transaction_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '.secrets.g.dart' as secrets;
import 'package:on_chain/on_chain.dart';

class PreparedTronTransaction {
  PreparedTronTransaction._({
    required TransactionRaw raw,
    required this.amount,
    required this.ownerAddress,
    required this.isHardware,
  })  : _raw = Uint8List.fromList(raw.toBuffer()),
        expiration = raw.expiration,
        fee = Money(raw.feeLimit ?? BigInt.zero, CryptoCurrency.trx),
        id = raw.txID;

  final Uint8List _raw;
  final Money amount;
  final Money fee;
  final TronAddress ownerAddress;
  final bool isHardware;
  final BigInt expiration;
  final String id;

  Uint8List get rawData => Uint8List.fromList(_raw);

  void ensureNotExpired() {
    if (expiration <= BigInt.from(DateTime.now().millisecondsSinceEpoch)) {
      throw StateError('TRON transaction expired; rebuild and sign again');
    }
  }
}

class TronClient {
  TronClient({TronProvider? provider, Future<String> Function(Uint8List)? broadcast})
      : _provider = provider,
        _broadcast = broadcast;

  late final client = ProxyWrapper().getHttpIOClient();

  TronProvider? _provider;
  final Future<String> Function(Uint8List)? _broadcast;
  // This is an internal tracker, so we don't have to "refetch".
  int _nativeTxEstimatedFee = 0;

  static const _historyRequestTimeout = Duration(seconds: 30);

  Future<List<TronTransactionModel>> fetchTransactions(String address,
      {String? contractAddress}) async {
    try {
      final response = await client.get(
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
      ).timeout(_historyRequestTimeout);
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
      log('Error getting tx: ${e.toString()}\n ${s.toString()}');
      return [];
    }
  }

  Future<List<TronTRC20TransactionModel>> fetchTrc20ExcludedTransactions(String address) async {
    try {
      final response = await client.get(
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
      ).timeout(_historyRequestTimeout);
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
      log('Error getting trc20 tx: ${e.toString()}\n ${s.toString()}');
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

  Future<BigInt> getBalance(TronAddress address, {bool throwOnError = false}) async {
    try {
      final accountDetails = await _provider!.request(TronRequestGetAccount(address: address));

      return accountDetails?.balance ?? BigInt.zero;
    } catch (_) {
      if (throwOnError) {
        rethrow;
      }
      return BigInt.zero;
    }
  }

  Future<int> getFeeLimit(
    TransactionRaw rawTransaction,
    TronAddress address,
    TronAddress receiverAddress, {
    int energyUsed = 0,
    bool isEstimatedFeeFlow = false,
  }) async {
    try {
      // Get the tron chain parameters.
      final chainParams = await _provider!.request(TronRequestGetChainParameters());

      final bandWidthInSun = chainParams.getTransactionFee!;
      log('BandWidth In Sun: $bandWidthInSun');

      final energyInSun = chainParams.getEnergyFee!;
      log('Energy In Sun: $energyInSun');

      final fakeTransaction = Transaction(
        rawData: rawTransaction,
        signature: [Uint8List(65)],
      );

      // Calculate the total size of the fake transaction, considering the required network overhead.
      final transactionSize = fakeTransaction.length + 64;

      // Assign the calculated size to the variable representing the required bandwidth.
      int neededBandWidth = transactionSize;
      log('Initial Needed Bandwidth: $neededBandWidth');

      int neededEnergy = energyUsed;
      log('Initial Needed Energy: $neededEnergy');

      // Fetch account resources to assess the available bandwidth and energy
      final accountResource =
          await _provider!.request(TronRequestGetAccountResource(address: address));

      neededEnergy -= accountResource.howManyEnergy.toInt();
      log('Account resource energy: ${accountResource.howManyEnergy.toInt()}');
      log('Needed Energy after deducting from account resource energy: $neededEnergy');

      // Deduct the bandwidth from the account's available bandwidth.
      final BigInt accountBandWidth = accountResource.howManyBandwIth;
      log('Account resource bandwidth: ${accountResource.howManyBandwIth.toInt()}');

      if (accountBandWidth >= BigInt.from(neededBandWidth) && !isEstimatedFeeFlow) {
        log('Account has more bandwidth than required');
        neededBandWidth = 0;
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

      log('Final total burn: $totalBurn');

      return totalBurn;
    } catch (_) {
      return 0;
    }
  }

  Future<int> getEstimatedFee(TronAddress ownerAddress) async {
    const constantAmount = '1000';
    // Fetch the latest Tron block
    final block = await _provider!.request(TronRequestGetNowBlock());

    // Create the transfer contract
    final contract = TransferContract(
      amount: TronHelper.toSun(constantAmount),
      ownerAddress: ownerAddress,
      toAddress: ownerAddress,
    );

    // Prepare the contract parameter for the transaction.
    final parameter = Any(typeUrl: contract.typeURL, value: contract);

    // Create a TransactionContract object with the contract type and parameter.
    final transactionContract =
        TransactionContract(type: contract.contractType, parameter: parameter);

    // Set the transaction expiration time (maximum 24 hours)
    final expireTime = DateTime.now().add(const Duration(minutes: 30));

    // Create a raw transaction
    TransactionRaw rawTransaction = TransactionRaw(
      refBlockBytes: block.blockHeader.rawData.refBlockBytes,
      refBlockHash: block.blockHeader.rawData.refBlockHash,
      expiration: BigInt.from(expireTime.millisecondsSinceEpoch),
      contract: [transactionContract],
      timestamp: block.blockHeader.rawData.timestamp,
    );

    final estimatedFee = await getFeeLimit(
      rawTransaction,
      ownerAddress,
      ownerAddress,
      isEstimatedFeeFlow: true,
    );

    _nativeTxEstimatedFee = estimatedFee;

    return estimatedFee;
  }

  Future<int> getTRCEstimatedFee(TronAddress ownerAddress) async {
    final usdtContractAddress = DefaultTronTokens().usdt.contractAddress;
    final contract = ContractABI.fromJson(trc20Abi, isTron: true);
    final function = contract.functionFromName("transfer");

    // We're using 0 as the base amount here as we get an error when balance is zero i.e for new wallets.
    final transferParams = [ownerAddress, BigInt.zero];

    final request = await _provider!.request(
      TronRequestTriggerConstantContract(
        ownerAddress: ownerAddress,
        contractAddress: TronAddress(usdtContractAddress),
        data: function.encodeHex(transferParams),
      ),
    );

    if (!request.isSuccess) {
      log("Tron TRC20 error: ${request.error} \n ${request.respose}");
    }

    return getFeeLimit(
      request.transactionRaw!,
      ownerAddress,
      ownerAddress,
      energyUsed: request.energyUsed ?? 0,
      isEstimatedFeeFlow: true,
    );
  }

  Future<PendingTronTransaction> signTransaction({
    required TronPrivateKey ownerPrivKey,
    required String toAddress,
    required Money amount,
    required BigInt tronBalance,
    required bool sendAll,
  }) async {
    final prepared = await prepareTransaction(
      ownerAddress: ownerPrivKey.publicKey().toAddress(),
      toAddress: toAddress,
      amount: amount,
      tronBalance: tronBalance,
      sendAll: sendAll,
    );
    return createPendingTransaction(prepared, ownerPrivKey.sign(prepared.rawData));
  }

  Future<PreparedTronTransaction> prepareTransaction({
    required TronAddress ownerAddress,
    required String toAddress,
    required Money amount,
    required BigInt tronBalance,
    required bool sendAll,
    bool isHardware = false,
  }) async {
    // Define the receiving Tron address for the transaction.
    final receiverAddress = TronAddress(toAddress);

    final isNativeTransaction = amount.currency == CryptoCurrency.trx;
    if (isHardware && !isNativeTransaction) {
      if (amount.currency is! TronToken ||
          TronAddress((amount.currency as TronToken).contractAddress).toAddress() !=
              'TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t' ||
          amount.currency.decimals != 6) {
        throw UnsupportedError('TRON Ledger supports only TRX and mainnet USDT');
      }
      final genesis = await _provider!.request(TronRequestGetBlockByNum(num: 0));
      if (genesis['blockID'] !=
          '00000000000000001ebf88508a03865c71d452e25f4d51194196a1d22b6653dc') {
        throw UnsupportedError('USDT Ledger transfers require a TRON mainnet node');
      }
    }

    Money totalAmount;
    TransactionRaw rawTransaction;
    if (isNativeTransaction) {
      if (sendAll) {
        final accountResource =
            await _provider!.request(TronRequestGetAccountResource(address: ownerAddress));

        final availableBandWidth = accountResource.howManyBandwIth.toInt();

        // 269 is the current middle ground for bandwidth per transaction
        if (availableBandWidth >= 269) {
          totalAmount = amount;
        } else {
          // 5000 added here is a buffer since we're working with "estimated" value of the fee.
          final result = amount.amount - BigInt.from(_nativeTxEstimatedFee + 5000);

          totalAmount = amount.copyWith(amount: result);
        }
      } else {
        totalAmount = amount;
      }
      rawTransaction = await _signNativeTransaction(
        ownerAddress,
        receiverAddress,
        totalAmount,
        tronBalance,
        sendAll,
      );
    } else {
      final tokenAddress = (amount.currency as TronToken).contractAddress;
      totalAmount = amount;
      rawTransaction = await _signTrcTokenTransaction(
        ownerAddress,
        receiverAddress,
        totalAmount,
        tokenAddress,
        tronBalance,
      );
    }

    if (isHardware) {
      return prepareHardwareTransaction(
        raw: rawTransaction,
        owner: ownerAddress,
        recipient: receiverAddress,
        amount: totalAmount,
      );
    }
    return PreparedTronTransaction._(
      raw: rawTransaction,
      amount: totalAmount,
      ownerAddress: ownerAddress,
      isHardware: false,
    );
  }

  PreparedTronTransaction prepareHardwareTransaction({
    required TransactionRaw raw,
    required TronAddress owner,
    required TronAddress recipient,
    required Money amount,
  }) {
    if (amount.currency != CryptoCurrency.trx &&
        (amount.currency is! TronToken ||
            TronAddress((amount.currency as TronToken).contractAddress).toAddress() !=
                'TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t' ||
            amount.currency.decimals != 6)) {
      throw UnsupportedError('TRON Ledger supports only TRX and mainnet USDT');
    }
    _validateLedgerTransfer(raw, owner, recipient, amount);
    final prepared = PreparedTronTransaction._(
      raw: raw,
      amount: amount,
      ownerAddress: owner,
      isHardware: true,
    );
    // Validate field framing before asking the user to approve.
    tronLedgerTransactionChunks("m/44'/195'/0'/0/0", prepared.rawData);
    return prepared;
  }

  void _validateLedgerTransfer(
    TransactionRaw raw,
    TronAddress owner,
    TronAddress recipient,
    Money amount,
  ) {
    if (raw.contract.length != 1 ||
        raw.data != null ||
        (raw.auths?.isNotEmpty ?? false) ||
        raw.scripts != null ||
        raw.refBlockBytes.length != 2 ||
        raw.refBlockHash.length != 8 ||
        raw.refBlockNum != null ||
        raw.timestamp <= BigInt.zero ||
        raw.timestamp >= raw.expiration ||
        (raw.feeLimit ?? BigInt.zero) < BigInt.zero ||
        amount.amount <= BigInt.zero ||
        raw.expiration <= BigInt.from(DateTime.now().millisecondsSinceEpoch) ||
        raw.expiration >
            BigInt.from(DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch)) {
      throw FormatException('Unsupported or expired TRON transaction fields');
    }
    final contract = raw.contract.single;
    if ((contract.permissionId ?? 0) != 0 ||
        (contract.provider?.isNotEmpty ?? false) ||
        (contract.contractName?.isNotEmpty ?? false)) {
      throw FormatException('Unsupported TRON contract permissions');
    }
    final value = contract.parameter.value;
    if (amount.currency == CryptoCurrency.trx) {
      if (value is! TransferContract ||
          contract.type != value.contractType ||
          contract.parameter.typeUrl != value.typeURL ||
          value.ownerAddress.toAddress() != owner.toAddress() ||
          value.toAddress.toAddress() != recipient.toAddress() ||
          value.amount != amount.amount) {
        throw FormatException('TRX transaction does not match the requested transfer');
      }
    } else {
      final expectedData = ContractABI.fromJson(
        trc20Abi,
        isTron: true,
      ).functionFromName('transfer').encodeHex([recipient, amount.amount]);
      if (value is! TriggerSmartContract ||
          contract.type != value.contractType ||
          contract.parameter.typeUrl != value.typeURL ||
          value.ownerAddress.toAddress() != owner.toAddress() ||
          value.contractAddress.toAddress() != 'TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t' ||
          (value.callValue ?? BigInt.zero) != BigInt.zero ||
          (value.callTokenValue ?? BigInt.zero) != BigInt.zero ||
          (value.tokenId ?? BigInt.zero) != BigInt.zero ||
          value.data == null ||
          BytesUtils.toHexString(value.data!).toLowerCase() !=
              expectedData.replaceFirst('0x', '').toLowerCase()) {
        throw FormatException('USDT transaction does not match the requested transfer');
      }
    }
  }

  PendingTronTransaction createPendingTransaction(
    PreparedTronTransaction prepared,
    List<int> signature,
  ) {
    final signed = Uint8List.fromList(signature);
    if (prepared.isHardware) {
      prepared.ensureNotExpired();
      if (signed.length != 65 || signed.last > 1) {
        throw FormatException('Invalid Ledger TRON signature');
      }
      final publicKey = TronPublicKey.fromPersonalSignature(
        QuickCrypto.sha256Hash(prepared.rawData),
        BytesUtils.toHexString(signed),
        hashMessage: false,
      );
      if (publicKey == null ||
          publicKey.toAddress().toAddress() != prepared.ownerAddress.toAddress()) {
        throw FormatException('Ledger signature does not match the wallet');
      }
    }
    return PendingTronTransaction(
      signedTransaction: Uint8List.fromList(signed),
      amount: prepared.amount,
      fee: prepared.fee,
      id: prepared.id,
      sendTransaction: () async {
        if (prepared.isHardware) prepared.ensureNotExpired();
        return _broadcastPrepared(prepared.rawData, signed);
      },
    );
  }

  Future<String> _broadcastPrepared(Uint8List raw, Uint8List signature) async {
    List<int> varint(int value) {
      final result = <int>[];
      while (value >= 128) {
        result.add((value & 127) | 128);
        value >>= 7;
      }
      return result..add(value);
    }

    final envelope = <int>[
      0x0a,
      ...varint(raw.length),
      ...raw,
      0x12,
      ...varint(signature.length),
      ...signature,
    ];
    try {
      if (_broadcast != null) return await _broadcast!(Uint8List.fromList(envelope));
      final result = await _provider!.request(
        TronRequestBroadcastHex(transaction: BytesUtils.toHexString(envelope)),
      );
      if (!result.isSuccess) throw TransactionSendingException(result.error ?? '');
      return result.txId!;
    } catch (e) {
      log('Send block Exception: ${e.toString()}');
      throw TransactionSendingException(e.toString());
    }
  }

  Future<TransactionRaw> _signNativeTransaction(
    TronAddress ownerAddress,
    TronAddress receiverAddress,
    Money amount,
    BigInt tronBalance,
    bool sendAll,
  ) async {
    // This is introduce to server as a limit in cases where feeLimit is 0
    // The transaction signing will fail if the feeLimit is explicitly 0.
    int defaultFeeLimit = 269000;

    final block = await _provider!.request(TronRequestGetNowBlock());
    // Create the transfer contract
    final contract = TransferContract(
      amount: amount.amount,
      ownerAddress: ownerAddress,
      toAddress: receiverAddress,
    );

    // Prepare the contract parameter for the transaction.
    final parameter = Any(typeUrl: contract.typeURL, value: contract);

    // Create a TransactionContract object with the contract type and parameter.
    final transactionContract =
        TransactionContract(type: contract.contractType, parameter: parameter);

    // Set the transaction expiration time (maximum 24 hours)
    final expireTime = DateTime.now().add(const Duration(minutes: 30));

    final rawTransaction = TransactionRaw(
      refBlockBytes: block.blockHeader.rawData.refBlockBytes,
      refBlockHash: block.blockHeader.rawData.refBlockHash,
      expiration: BigInt.from(expireTime.millisecondsSinceEpoch),
      contract: [transactionContract],
      timestamp: block.blockHeader.rawData.timestamp,
    );

    final feeLimit = await getFeeLimit(rawTransaction, ownerAddress, receiverAddress);
    final feeLimitToUse = feeLimit != 0 ? feeLimit : defaultFeeLimit;
    final tronBalanceInt = tronBalance.toInt();

    if (feeLimit > tronBalanceInt) {
      final feeInTrx = TronHelper.fromSun(BigInt.parse(feeLimit.toString()));
      throw TransactionGenerationException(
        'You don\'t have enough TRX to cover the transaction fee for this transaction. Please top up.\nTransaction fee: $feeInTrx TRX',
      );
    }

    return rawTransaction.copyWith(feeLimit: BigInt.from(feeLimitToUse));
  }

  Future<TransactionRaw> _signTrcTokenTransaction(
    TronAddress ownerAddress,
    TronAddress receiverAddress,
    Money amount,
    String contractAddress,
    BigInt tronBalance,
  ) async {
    final contract = ContractABI.fromJson(trc20Abi, isTron: true);

    final function = contract.functionFromName("transfer");
    final transferParams = [receiverAddress, amount.amount];
    final request = await _provider!.request(
      TronRequestTriggerConstantContract(
        ownerAddress: ownerAddress,
        contractAddress: TronAddress(contractAddress),
        data: function.encodeHex(transferParams),
      ),
    );

    if (!request.isSuccess) {
      log("Tron TRC20 error: ${request.error} \n ${request.respose}");
      throw TransactionGenerationException('An error occurred while creating the transfer request. Please try again.');
    }

    final feeLimit = await getFeeLimit(
      request.transactionRaw!,
      ownerAddress,
      receiverAddress,
      energyUsed: request.energyUsed ?? 0,
    );

    if (feeLimit > tronBalance.toInt()) {
      final feeInTrx = TronHelper.fromSun(BigInt.parse(feeLimit.toString()));
      throw TransactionGenerationException(
        'You don\'t have enough TRX to cover the transaction fee for this transaction. Please top up. Transaction fee: $feeInTrx TRX',
      );
    }

    return request.transactionRaw!.copyWith(feeLimit: BigInt.from(feeLimit));
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
        throw TransactionSendingException(txBroadcastResult.error??"");
      }
    } catch (e) {
      log('Send block Exception: ${e.toString()}');
      throw TransactionSendingException(e.toString());
    }
  }

  Future<TronBalance> fetchTronTokenBalances(String userAddress, String contractAddress,
      {bool throwOnError = false, required Currency currency}) async {
    try {
      final ownerAddress = TronAddress(userAddress);

      final contract = ContractABI.fromJson(trc20Abi, isTron: true);
      final function = contract.functionFromName("balanceOf");

      final request = await _provider!.request(
        TronRequestTriggerConstantContract.fromMethod(
          ownerAddress: ownerAddress,
          contractAddress: TronAddress(contractAddress),
          function: function,
          params: [ownerAddress],
        ),
      );

      final outputResult = request.outputResult?.first as BigInt? ?? BigInt.zero;

      return TronBalance(Money(outputResult, currency));
    } catch (_) {
      if (throwOnError) {
        rethrow;
      }
      return TronBalance(Money.zero(currency));
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

  Future<dynamic> getTokenDetail(
    ContractABI contract,
    String functionName,
    TronAddress ownerAddress,
    TronAddress tokenAddress,
  ) async {
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
      log('Erorr fetching detail: ${_.toString()}');

      return null;
    }
  }
}
