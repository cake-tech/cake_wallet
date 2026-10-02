import "dart:async";
import 'dart:convert';

import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/calculate_fiat_amount.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cw_core/crypto_currency.dart';
import "package:cw_core/utils/print_verbose.dart";
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:eth_sig_util/util/utils.dart';
import 'package:flutter/material.dart';
import 'package:reown_walletkit/reown_walletkit.dart';

import 'package:cake_wallet/src/screens/wallet_connect/services/bottom_sheet_service.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/chain_service/eth/evm_supported_methods.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/key_service/wallet_connect_key_service.dart';
import 'package:cake_wallet/src/screens/wallet_connect/models/wc_connection_model.dart';
import 'package:cake_wallet/src/screens/wallet_connect/utils/eth_utils.dart';
import 'package:cake_wallet/src/screens/wallet_connect/utils/method_utils.dart';
import "package:cake_wallet/src/screens/wallet_connect/widgets/bottom_sheet/bottom_sheet_message_display_widget.dart";
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/evm/evm.dart';

JsonRpcError unsupportedChainError(String caip2ChainId) {
  final error = Errors.getSdkError(
    Errors.UNSUPPORTED_CHAINS,
    context: "The chain $caip2ChainId is not supported",
  );
  return JsonRpcError(code: error.code, message: error.message);
}

class EvmChainServiceImpl {
  Map<String, dynamic Function(String, dynamic)> get sessionRequestHandlers => {
        EVMSupportedMethods.ethSign.name: ethSign,
        EVMSupportedMethods.ethSignTransaction.name: ethSignTransaction,
        EVMSupportedMethods.ethSignTypedData.name: ethSignTypedData,
        EVMSupportedMethods.ethSignTypedDataV4.name: ethSignTypedDataV4,
      };

  Map<String, dynamic Function(String, dynamic)> get methodRequestHandlers => {
        EVMSupportedMethods.personalSign.name: personalSign,
        EVMSupportedMethods.ethSendTransaction.name: ethSendTransaction,
      };

  EvmChainServiceImpl({
    required this.appStore,
    required this.wcKeyService,
    required this.bottomSheetService,
    required this.walletKit,
  });

  final AppStore appStore;
  final ReownWalletKit walletKit;
  final WalletConnectKeyService wcKeyService;
  final BottomSheetService bottomSheetService;

  static final _walletNotConnectedError =
      JsonRpcError.serverError("The wallet is not connected to a node");

  void registerChain(String caip2ChainId) {
    for (final event in EventsConstants.allEvents) {
      walletKit.registerEventEmitter(
        chainId: caip2ChainId,
        event: event,
      );
    }

    for (var handler in methodRequestHandlers.entries) {
      walletKit.registerRequestHandler(
        chainId: caip2ChainId,
        method: handler.key,
        handler: handler.value,
      );
    }
    for (var handler in sessionRequestHandlers.entries) {
      walletKit.registerRequestHandler(
        chainId: caip2ChainId,
        method: handler.key,
        handler: handler.value,
      );
    }
  }

  int? _requestChainId(SessionRequest request) => int.tryParse(request.chainId.split(":").last);

  bool _isCurrentWalletChain(int chainId) => appStore.wallet?.chainId == chainId;

  Future<void> personalSign(String topic, dynamic parameters) async {
    debugPrint("personalSign request: $parameters");

    final pRequest = _pendingRequest(topic, EVMSupportedMethods.personalSign.name);
    if (pRequest == null) {
      return;
    }

    final address = EthUtils.getAddressFromSessionRequest(pRequest);

    if (!_isRequestAuthorized(topic, requestAddress: address)) {
      await _rejectUnauthorizedRequest(topic, pRequest.id);
      return;
    }

    final data = EthUtils.getDataFromSessionRequest(pRequest);
    final message = EthUtils.getUtf8Message(data.toString());
    var response = JsonRpcResponse(id: pRequest.id, jsonrpc: '2.0');

    final isApproved = await MethodsUtils.requestApproval(
      message,
      method: pRequest.method,
      chainId: pRequest.chainId,
      address: address,
      topic: topic,
      transportType: pRequest.transportType.name,
      verifyContext: pRequest.verifyContext,
    );

    if (isApproved) {
      try {
        final keys = wcKeyService.getKeysForChain(appStore.wallet!);
        final credentials = EthPrivateKey.fromHex(keys[0].privateKey);

        final signature = credentials.signPersonalMessageToUint8List(
          utf8.encode(message),
        );
        final signedTx = bytesToHex(signature, include0x: true);

        isValidSignature(signedTx, message, credentials.address.hex);

        response = response.copyWith(result: signedTx);
      } catch (e) {
        debugPrint('personalSign error $e');
        final error = Errors.getSdkError(Errors.MALFORMED_REQUEST_PARAMS);
        response = response.copyWith(
          error: JsonRpcError(code: error.code, message: error.message),
        );
      }
    } else {
      final error = Errors.getSdkError(Errors.USER_REJECTED);
      response = response.copyWith(
        error: JsonRpcError(code: error.code, message: error.message),
      );
    }

    _handleResponseForTopic(topic, response);
  }

  Future<void> ethSign(String topic, dynamic parameters) async {
    debugPrint('ethSign request: $parameters');

    final pRequest = _pendingRequest(topic, EVMSupportedMethods.ethSign.name);
    if (pRequest == null) {
      return;
    }

    final address = EthUtils.getAddressFromSessionRequest(pRequest);

    if (!_isRequestAuthorized(topic, requestAddress: address)) {
      await _rejectUnauthorizedRequest(topic, pRequest.id);
      return;
    }

    final data = EthUtils.getDataFromSessionRequest(pRequest);
    final message = EthUtils.getUtf8Message(data.toString());
    var response = JsonRpcResponse(id: pRequest.id, jsonrpc: '2.0');

    final isApproved = await MethodsUtils.requestApproval(
      message,
      method: pRequest.method,
      chainId: pRequest.chainId,
      address: address,
      topic: topic,
      transportType: pRequest.transportType.name,
      verifyContext: pRequest.verifyContext,
    );

    if (isApproved) {
      try {
        final keys = wcKeyService.getKeysForChain(appStore.wallet!);
        final credentials = EthPrivateKey.fromHex(keys[0].privateKey);

        final signature = credentials.signPersonalMessageToUint8List(
          utf8.encode(message),
        );
        final signedTx = bytesToHex(signature, include0x: true);

        isValidSignature(signedTx, message, credentials.address.hex);

        response = response.copyWith(result: signedTx);
      } catch (e) {
        debugPrint('ethSign error $e');
        final error = Errors.getSdkError(Errors.MALFORMED_REQUEST_PARAMS);
        response = response.copyWith(
          error: JsonRpcError(code: error.code, message: error.message),
        );
      }
    } else {
      final error = Errors.getSdkError(Errors.USER_REJECTED).toSignError();
      response = response.copyWith(
        error: JsonRpcError(code: error.code, message: error.message),
      );
    }

    _handleResponseForTopic(topic, response);
  }

  Future<void> ethSignTypedData(String topic, dynamic parameters) async {
    debugPrint('ethSignTypedData request: $parameters');

    final pRequest = _pendingRequest(topic, EVMSupportedMethods.ethSignTypedData.name);
    if (pRequest == null) {
      return;
    }

    final address = EthUtils.getAddressFromSessionRequest(pRequest);

    if (!_isRequestAuthorized(topic, requestAddress: address)) {
      await _rejectUnauthorizedRequest(topic, pRequest.id);
      return;
    }

    final data = EthUtils.getDataFromSessionRequest(pRequest) as String;
    var response = JsonRpcResponse(id: pRequest.id, jsonrpc: '2.0');

    final isApproved = await MethodsUtils.requestApproval(
      data,
      method: pRequest.method,
      chainId: pRequest.chainId,
      address: address,
      topic: topic,
      transportType: pRequest.transportType.name,
      verifyContext: pRequest.verifyContext,
    );

    if (isApproved) {
      try {
        final keys = wcKeyService.getKeysForChain(appStore.wallet!);

        final signature = EthSigUtil.signTypedData(
          privateKey: keys[0].privateKey,
          jsonData: data,
          version: TypedDataVersion.V4,
        );

        response = response.copyWith(result: signature);
      } catch (e) {
        debugPrint('ethSignTypedData error $e');
        final error = Errors.getSdkError(Errors.MALFORMED_REQUEST_PARAMS);
        response = response.copyWith(
          error: JsonRpcError(code: error.code, message: error.message),
        );
      }
    } else {
      final error = Errors.getSdkError(Errors.USER_REJECTED).toSignError();
      response = response.copyWith(
        error: JsonRpcError(code: error.code, message: error.message),
      );
    }

    _handleResponseForTopic(topic, response);
  }

  Future<void> ethSignTypedDataV4(String topic, dynamic parameters) async {
    debugPrint('ethSignTypedDataV4 request: $parameters');

    final permitRequestMessage = await extractPermitData(parameters);

    final pRequest = _pendingRequest(topic, EVMSupportedMethods.ethSignTypedDataV4.name);
    if (pRequest == null) {
      return;
    }

    final address = EthUtils.getAddressFromSessionRequest(pRequest);

    if (!_isRequestAuthorized(topic, requestAddress: address)) {
      await _rejectUnauthorizedRequest(topic, pRequest.id);
      return;
    }

    final data = EthUtils.getDataFromSessionRequest(pRequest) as String;
    var response = JsonRpcResponse(id: pRequest.id, jsonrpc: '2.0');

    final isApproved = await MethodsUtils.requestApproval(
      permitRequestMessage,
      method: pRequest.method,
      chainId: pRequest.chainId,
      address: address,
      topic: topic,
      transportType: pRequest.transportType.name,
      verifyContext: pRequest.verifyContext,
    );

    if (isApproved) {
      try {
        final keys = wcKeyService.getKeysForChain(appStore.wallet!);

        final signature = EthSigUtil.signTypedData(
          privateKey: keys[0].privateKey,
          jsonData: data,
          version: TypedDataVersion.V4,
        );

        response = response.copyWith(result: signature);
      } catch (e) {
        debugPrint('ethSignTypedDataV4 error $e');
        final error = Errors.getSdkError(Errors.MALFORMED_REQUEST_PARAMS);
        response = response.copyWith(
          error: JsonRpcError(code: error.code, message: error.message),
        );
      }
    } else {
      response = response.copyWith(
        error: JsonRpcError(code: 5002, message: S.current.user_rejected_method),
      );
    }

    _handleResponseForTopic(topic, response);
  }

  Future<void> ethSignTransaction(String topic, dynamic parameters) async {
    debugPrint('ethSignTransaction request: $parameters');

    final pRequest = _pendingRequest(topic, EVMSupportedMethods.ethSignTransaction.name);
    if (pRequest == null) {
      return;
    }

    final data = EthUtils.getTransactionFromSessionRequest(pRequest);

    if (data == null) {
      _respondMalformedRequest(topic, pRequest.id);
      return;
    }

    if (!_isRequestAuthorized(topic, requestAddress: data['from']?.toString())) {
      await _rejectUnauthorizedRequest(topic, pRequest.id);
      return;
    }

    final chainId = _requestChainId(pRequest);
    if (chainId == null || !_isCurrentWalletChain(chainId)) {
      await _rejectOtherNetworkRequest(topic, pRequest);
      return;
    }

    final address = EthUtils.getAddressFromSessionRequest(pRequest);
    var response = JsonRpcResponse(id: pRequest.id, jsonrpc: '2.0');

    final transaction = await _approveTransaction(
      data,
      method: pRequest.method,
      chainId: pRequest.chainId,
      address: address,
      topic: topic,
      transportType: pRequest.transportType.name,
      verifyContext: pRequest.verifyContext,
    );

    if (transaction is Transaction) {
      if (!_isCurrentWalletChain(chainId)) {
        await _rejectOtherNetworkRequest(topic, pRequest);
        return;
      }

      try {
        final keys = wcKeyService.getKeysForChain(appStore.wallet!);
        final credentials = EthPrivateKey.fromHex(keys[0].privateKey);

        final client = evm!.getWeb3Client(appStore.wallet!);
        final signature = await client?.signTransaction(
          credentials,
          transaction,
          chainId: chainId,
        );

        response = signature == null
            ? response.copyWith(error: _walletNotConnectedError)
            : response.copyWith(result: bytesToHex(signature, include0x: true));
      } on RPCError catch (e) {
        debugPrint('ethSignTransaction error $e');
        response = response.copyWith(
          error: JsonRpcError(code: e.errorCode, message: e.message),
        );
      } catch (e) {
        debugPrint('ethSignTransaction error $e');
        final error = Errors.getSdkError(Errors.MALFORMED_REQUEST_PARAMS);
        response = response.copyWith(
          error: JsonRpcError(code: error.code, message: error.message),
        );
      }
    } else {
      response = response.copyWith(error: transaction as JsonRpcError);
    }

    _handleResponseForTopic(topic, response);
  }

  Future<void> ethSendTransaction(String topic, dynamic parameters) async {
    debugPrint('ethSendTransaction request: $parameters');
    final pRequest = _pendingRequest(topic, EVMSupportedMethods.ethSendTransaction.name);
    if (pRequest == null) {
      return;
    }

    final data = EthUtils.getTransactionFromSessionRequest(pRequest);
    if (data == null) {
      _respondMalformedRequest(topic, pRequest.id);
      return;
    }

    if (!_isRequestAuthorized(topic, requestAddress: data['from']?.toString())) {
      await _rejectUnauthorizedRequest(topic, pRequest.id);
      return;
    }

    final chainId = _requestChainId(pRequest);
    if (chainId == null || !_isCurrentWalletChain(chainId)) {
      await _rejectOtherNetworkRequest(topic, pRequest);
      return;
    }

    var response = JsonRpcResponse(id: pRequest.id, jsonrpc: '2.0');

    final transaction = await _approveTransaction(
      data,
      method: pRequest.method,
      chainId: pRequest.chainId,
      topic: topic,
      transportType: pRequest.transportType.name,
      verifyContext: pRequest.verifyContext,
    );
    if (transaction is Transaction) {
      if (!_isCurrentWalletChain(chainId)) {
        await _rejectOtherNetworkRequest(topic, pRequest);
        return;
      }

      try {
        final keys = wcKeyService.getKeysForChain(appStore.wallet!);
        final credentials = EthPrivateKey.fromHex(keys[0].privateKey);

        final client = evm!.getWeb3Client(appStore.wallet!);
        final signedTx = await client?.sendTransaction(
          credentials,
          transaction,
          chainId: chainId,
        );

        response = signedTx == null
            ? response.copyWith(error: _walletNotConnectedError)
            : response.copyWith(result: signedTx);
      } on RPCError catch (e) {
        debugPrint('ethSendTransaction error $e');
        response = response.copyWith(
          error: JsonRpcError(code: e.errorCode, message: e.message),
        );
      } catch (e) {
        debugPrint('ethSendTransaction error $e');
        final error = Errors.getSdkError(Errors.MALFORMED_REQUEST_PARAMS);
        response = response.copyWith(
          error: JsonRpcError(code: error.code, message: error.message),
        );
      }
    } else {
      response = response.copyWith(error: transaction as JsonRpcError);
    }

    _handleResponseForTopic(topic, response);
  }

  void _respondMalformedRequest(String topic, int requestId) {
    final error = Errors.getSdkError(Errors.MALFORMED_REQUEST_PARAMS);
    _handleResponseForTopic(
      topic,
      JsonRpcResponse(
        id: requestId,
        jsonrpc: "2.0",
        error: JsonRpcError(code: error.code, message: error.message),
      ),
    );
  }

  SessionRequest? _pendingRequest(String topic, String method) {
    final matches = walletKit.pendingRequests
        .getAll()
        .where((request) => request.topic == topic && request.method == method);

    return matches.isEmpty ? null : matches.last;
  }

  bool _isRequestAuthorized(String topic, {String? requestAddress}) {
    final wallet = appStore.wallet;
    if (wallet == null) {
      return false;
    }

    final keys = wcKeyService.getKeysForChain(wallet);
    if (keys.isEmpty) {
      return false;
    }

    final walletAddress = keys.first.publicKey;

    if (!MethodsUtils.isSessionOwnedByWallet(walletKit.sessions.get(topic), walletAddress)) {
      return false;
    }

    if (requestAddress != null && !MethodsUtils.isSameAccount(requestAddress, walletAddress)) {
      return false;
    }

    return true;
  }

  Future<void> _rejectUnauthorizedRequest(String topic, int requestId) async {
    unawaited(
      bottomSheetService.queueBottomSheet(
        isModalDismissible: true,
        widget: BottomSheetMessageDisplayWidget(
          message: S.current.wc_request_for_different_wallet,
        ),
      ),
    );

    try {
      await walletKit.respondSessionRequest(
        topic: topic,
        response: JsonRpcResponse(
          id: requestId,
          jsonrpc: "2.0",
          error: const JsonRpcError(
            code: 4100,
            message: "The requested account has not been authorized by the user.",
          ),
        ),
      );
    } catch (e) {
      printV("rejectUnauthorizedRequest: $e");
    }
  }

  Future<void> _rejectOtherNetworkRequest(String topic, SessionRequest request) async {
    final chainId = _requestChainId(request);
    final chainInfo = chainId == null ? null : evm!.getChainInfoByChainId(chainId);
    final networkName = chainInfo?.name ?? request.chainId;
    unawaited(
      bottomSheetService.queueBottomSheet(
        isModalDismissible: true,
        widget: BottomSheetMessageDisplayWidget(
          message: S.current.wc_request_for_other_network(networkName),
        ),
      ),
    );

    try {
      await walletKit.respondSessionRequest(
        topic: topic,
        response: JsonRpcResponse(
          id: request.id,
          jsonrpc: "2.0",
          error: unsupportedChainError(request.chainId),
        ),
      );
    } catch (e) {
      printV("rejectOtherNetworkRequest: $e");
    }
  }

  void _handleResponseForTopic(String topic, JsonRpcResponse<dynamic> response) async {
    final session = walletKit.sessions.get(topic);

    try {
      await walletKit.respondSessionRequest(
        topic: topic,
        response: response,
      );

      if (session == null) {
        return;
      }

      MethodsUtils.handleRedirect(
        topic,
        session.peer.metadata.redirect,
        response.error?.message,
        response.error == null,
      );
    } on ReownSignError catch (error) {
      if (session == null) {
        return;
      }

      MethodsUtils.handleRedirect(
        topic,
        session.peer.metadata.redirect,
        error.message,
      );
    }
  }

  Future<dynamic> _approveTransaction(
    Map<String, dynamic> transactionJson, {
    String? title,
    String? method,
    String? chainId,
    String? address,
    String? topic,
    VerifyContext? verifyContext,
    required String transportType,
  }) async {
    final nativeCurrency = appStore.wallet!.currency;

    final client = evm!.getWeb3Client(appStore.wallet!);
    if (client == null) {
      return _walletNotConnectedError;
    }

    Transaction transaction = transactionJson.toTransaction();

    if (transactionJson.containsKey('gas') && transaction.maxGas == null) {
      final gasHex = transactionJson['gas'].toString();
      try {
        final gasValue = int.parse(
          gasHex.replaceFirst('0x', '').replaceFirst('0X', ''),
          radix: 16,
        );
        transaction = transaction.copyWith(maxGas: gasValue);
      } catch (e) {
        debugPrint('Failed to parse gas value: $gasHex, error: $e');
      }
    }

    try {
      transaction = await _ensureWCTransactionHasGasLimit(transaction, client);
    } on RPCError catch (e) {
      return JsonRpcError(code: e.errorCode, message: e.message);
    }

    transaction = await _applyWCBufferedFees(transaction, client);

    final nativeSymbol = nativeCurrency.title;

    final amount = (transaction.value?.getInWei ?? BigInt.zero) / BigInt.from(1e18);

    final txMessageText = '${S.current.value}: ${amount.toStringAsFixed(9)} $nativeSymbol\n'
        '${S.current.from}: ${transaction.from?.hex}\n'
        '${S.current.to}: ${transaction.to?.hex}';

    final feeRows = _buildFeeExtraModels(transaction, nativeCurrency, nativeSymbol);

    if (await MethodsUtils.requestApproval(
      txMessageText,
      title: title,
      method: method,
      chainId: chainId,
      address: address ?? transaction.from?.hex ?? '',
      topic: topic,
      transportType: transportType,
      verifyContext: verifyContext,
      extraModels: feeRows,
    )) {
      return transaction;
    }

    return JsonRpcError(code: 5002, message: S.current.user_rejected_method);
  }

  List<WCConnectionModel> _buildFeeExtraModels(
    Transaction transaction,
    CryptoCurrency? nativeCurrency,
    String nativeSymbol,
  ) {
    final gasLimit = transaction.maxGas;
    if (gasLimit == null || gasLimit <= 0) {
      return const [];
    }

    final gasLimitBig = BigInt.from(gasLimit);
    final isEip1559 = transaction.isEIP1559;
    final perGasWei =
        isEip1559 ? transaction.maxFeePerGas?.getInWei : transaction.gasPrice?.getInWei;
    if (perGasWei == null || perGasWei <= BigInt.zero) {
      return const [];
    }

    final feeWei = gasLimitBig * perGasWei;
    final feeNative = feeWei.toDouble() / 1e18;

    final label = isEip1559 ? S.current.wc_max_network_fee : S.current.wc_network_fee;

    return [
      WCConnectionModel(
        title: label,
        elements: [_formatFeeLine(feeNative, nativeSymbol, nativeCurrency)],
      ),
    ];
  }

  String _formatFeeLine(
    double feeNative,
    String nativeSymbol,
    CryptoCurrency? nativeCurrency,
  ) {
    final cryptoPart = '${_formatNativeAmount(feeNative)} $nativeSymbol';

    if (nativeCurrency == null) {
      return cryptoPart;
    }

    try {
      final fiatStore = getIt.get<FiatConversionStore>();
      final price = fiatStore.prices[nativeCurrency];
      if (price == null || price <= 0) {
        return cryptoPart;
      }

      final fiatSymbol = appStore.settingsStore.fiatCurrency.title;
      final fiatValue = calculateFiatAmount(
        price: price,
        cryptoAmount: feeNative.toString(),
      );
      if (fiatValue.isEmpty || fiatValue == '0.00') {
        return cryptoPart;
      }

      return '$cryptoPart (~ $fiatValue $fiatSymbol)';
    } catch (_) {
      return cryptoPart;
    }
  }

  String _formatNativeAmount(double value) {
    if (value == 0) {
      return '0';
    }
    if (value >= 0.0001) {
      return value.toStringAsFixed(6);
    }
    return value.toStringAsExponential(4);
  }

  Future<Transaction> _ensureWCTransactionHasGasLimit(
    Transaction transaction,
    Web3Client client,
  ) async {
    final hasGasLimit = transaction.maxGas != null && transaction.maxGas! > 0;
    if (hasGasLimit) {
      return transaction;
    }

    final hint = transaction.gasPrice ?? transaction.maxFeePerGas ?? await client.getGasPrice();

    final gasLimit = await client.estimateGas(
      sender: transaction.from,
      to: transaction.to,
      value: transaction.value,
      data: transaction.data,
      gasPrice: hint,
    );

    if (transaction.isEIP1559) {
      return transaction.copyWith(maxGas: gasLimit.toInt());
    }

    return transaction.copyWith(
      maxGas: gasLimit.toInt(),
      gasPrice: transaction.gasPrice ?? hint,
    );
  }

  Future<Transaction> _applyWCBufferedFees(Transaction transaction, Web3Client client) async {
    try {
      final wallet = appStore.wallet!;
      final storedPriority =
          appStore.settingsStore.getPriority(wallet.type, chainId: wallet.chainId);
      final priority = storedPriority ?? evm!.getDefaultTransactionPriority();

      final quote = await evm!.getWCBufferedFeeQuote(wallet, priority);
      if (quote != null) {
        return _mergeWCBufferedFees(transaction, quote);
      }
    } catch (e) {
      debugPrint('WalletConnect fee refresh failed: $e');
    }

    if (!transaction.isEIP1559 && transaction.gasPrice == null) {
      return transaction.copyWith(gasPrice: await client.getGasPrice());
    }

    return transaction;
  }

  Transaction _mergeWCBufferedFees(Transaction transaction, EvmWalletConnectFeeQuote quote) {
    if (transaction.isEIP1559) {
      // the fees coming from the dApp
      final dAppMax = transaction.maxFeePerGas?.getInWei ?? BigInt.zero;
      final dAppPri = transaction.maxPriorityFeePerGas?.getInWei ?? BigInt.zero;

      // the updated fees coming from the wallet, handles buffered fees
      final quoteMax = BigInt.from(quote.maxFeePerGasWei);
      final quotePri = BigInt.from(quote.maxPriorityFeePerGasWei);

      // we'll just use the higher of the two
      var newMaxFeePerGasWei = dAppMax > quoteMax ? dAppMax : quoteMax;
      var newPriorityFeePerGasWei = dAppPri > quotePri ? dAppPri : quotePri;

      final base = quote.latestBaseFeeWei;
      if (base != null) {
        final baseB = BigInt.from(base);
        final maxPriAllowed = newMaxFeePerGasWei - baseB;
        if (newPriorityFeePerGasWei > maxPriAllowed) {
          if (maxPriAllowed > BigInt.zero) {
            newPriorityFeePerGasWei = maxPriAllowed;
          } else {
            newMaxFeePerGasWei = baseB + newPriorityFeePerGasWei;
          }
        }
      }

      return transaction.copyWith(
        maxFeePerGas: EtherAmount.inWei(newMaxFeePerGasWei),
        maxPriorityFeePerGas: EtherAmount.inWei(newPriorityFeePerGasWei),
      );
    }

    final dPrice = transaction.gasPrice?.getInWei ?? BigInt.zero;
    final floor = BigInt.from(quote.maxFeePerGasWei);
    final newPriceWei = dPrice > floor ? dPrice : floor;
    return transaction.copyWith(gasPrice: EtherAmount.inWei(newPriceWei));
  }

  bool isValidSignature(String hexSignature, String message, String hexAddress) {
    try {
      debugPrint('isValidSignature: $hexSignature, $message, $hexAddress');
      final recoveredAddress = EthSigUtil.recoverPersonalSignature(
        signature: hexSignature,
        message: utf8.encode(message),
      );
      debugPrint('recoveredAddress: $recoveredAddress');

      final recoveredAddress2 = EthSigUtil.recoverSignature(
        signature: hexSignature,
        message: utf8.encode(message),
      );
      debugPrint('recoveredAddress2: $recoveredAddress2');

      final isValid = recoveredAddress == hexAddress;
      return isValid;
    } catch (e) {
      return false;
    }
  }

  Future<String> extractPermitData(dynamic data) async {
    if (data is List && data.length >= 2) {
      final typedData = jsonDecode(data[1] as String) as Map<String, dynamic>;

      // Extracting domain details.
      final domain = typedData['domain'] as Map<String, dynamic>? ?? {};
      final domainName = domain['name']?.toString() ?? '';
      final version = domain['version']?.toString() ?? '';
      final chainId = domain['chainId']?.toString() ?? '';
      final verifyingContract = domain['verifyingContract']?.toString() ?? '';

      // Get the primary type and types
      final primaryType = typedData['primaryType']?.toString() ?? '';
      final types = typedData['types'] as Map<String, dynamic>? ?? {};
      final message = typedData['message'] as Map<String, dynamic>? ?? {};

      // Build a readable message based on the primary type and its structure
      String messageDetails = '';

      if (types.containsKey(primaryType)) {
        final typeFields = types[primaryType] as List<dynamic>;
        messageDetails = _formatMessageFields(message, typeFields, types);
      } else {
        // For unknown types, show the raw message
        messageDetails = message.toString();
      }

      return '''Domain Name: $domainName
Version: $version
Chain ID: $chainId
Verifying Contract: $verifyingContract
Primary Type: $primaryType\n
Message:
$messageDetails''';
    }
    return 'Invalid typed data format';
  }

  String _formatMessageFields(
      Map<String, dynamic> message, List<dynamic> fields, Map<String, dynamic> types) {
    final buffer = StringBuffer();

    for (var field in fields) {
      final fieldName = _toCamelCase(field['name'] as String);
      final fieldType = field['type'] as String;
      final value = message[field['name'] as String];

      if (value == null) {
        continue;
      }

      if (types.containsKey(fieldType)) {
        final nestedFields = types[fieldType] as List<dynamic>;
        if (fieldType == 'Person') {
          // Special formatting for Person type
          final name = value['name'] as String;
          final wallet = value['wallet'] as String;
          buffer.writeln('$fieldName: $name ($wallet)');
        } else {
          // For other nested types, format each field
          final formattedValue =
              _formatMessageFields(value as Map<String, dynamic>, nestedFields, types);
          buffer.writeln('$fieldName: $formattedValue');
        }
      } else {
        // Handle primitive types
        buffer.writeln('$fieldName: $value');
      }
    }

    return buffer.toString();
  }

  String _toCamelCase(String input) {
    if (input.isEmpty) {
      return input;
    }
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
  }

  Future<String> getTokenDetails(String contractAddress, String chainName) async {
    final uri = Uri.https(
      'deep-index.moralis.io',
      '/api/v2.2/erc20/metadata',
      {
        "chain": chainName,
        "addresses": contractAddress,
      },
    );

    final response = await ProxyWrapper().get(
      clearnetUri: uri,
      headers: {
        "Accept": "application/json",
        "X-API-Key": secrets.moralisApiKey,
      },
    );

    final decodedResponse = jsonDecode(response.body)[0] as Map<String, dynamic>;

    final symbol = (decodedResponse['symbol'] ?? '') as String;

    final name = decodedResponse['name'] ?? '';
    return '$name ($symbol)';
  }
}
