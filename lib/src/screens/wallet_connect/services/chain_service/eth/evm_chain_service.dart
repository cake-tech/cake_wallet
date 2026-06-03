import 'dart:convert';

import 'package:cake_wallet/evm/evm.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_request_decoder.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/evm/typed_data_decoder.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/evm/wallet_admin_decoder.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/bottom_sheet_service.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/chain_service/eth/evm_chain_id.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/chain_service/eth/evm_supported_methods.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/key_service/wallet_connect_key_service.dart';
import 'package:cake_wallet/src/screens/wallet_connect/utils/eth_utils.dart';
import 'package:cake_wallet/src/screens/wallet_connect/utils/method_utils.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:eth_sig_util/util/utils.dart';
import 'package:reown_walletkit/reown_walletkit.dart';

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
        EVMSupportedMethods.switchChain.name: walletSwitchEthereumChain,
        EVMSupportedMethods.addChain.name: walletAddEthereumChain,
      };

  EvmChainServiceImpl({
    required this.reference,
    required this.appStore,
    required this.wcKeyService,
    required this.bottomSheetService,
    required this.walletKit,
    Web3Client? web3Client,
  })  : ethClient = web3Client ?? _createWeb3Client(reference, appStore),
        decoder = EvmRequestDecoder(appStore),
        typedDataDecoder = TypedDataDecoder(),
        walletAdminDecoder = WalletAdminDecoder() {
    for (final event in EventsConstants.allEvents) {
      walletKit.registerEventEmitter(
        chainId: getChainId(),
        event: event,
      );
    }

    for (var handler in methodRequestHandlers.entries) {
      walletKit.registerRequestHandler(
        chainId: getChainId(),
        method: handler.key,
        handler: handler.value,
      );
    }
    for (var handler in sessionRequestHandlers.entries) {
      walletKit.registerRequestHandler(
        chainId: getChainId(),
        method: handler.key,
        handler: handler.value,
      );
    }

    walletKit.onSessionRequest.subscribe(_onSessionRequest);
  }

  final AppStore appStore;
  final EVMChainId reference;
  final Web3Client ethClient;
  final ReownWalletKit walletKit;
  final WalletConnectKeyService wcKeyService;
  final BottomSheetService bottomSheetService;
  final EvmRequestDecoder decoder;
  final TypedDataDecoder typedDataDecoder;
  final WalletAdminDecoder walletAdminDecoder;

  String getChainId() => reference.chain();

  static Web3Client _createWeb3Client(EVMChainId reference, AppStore appStore) {
    if (appStore.wallet != null && isEVMCompatibleChain(appStore.wallet!.type)) {
      final walletClient = evm?.getWeb3Client(appStore.wallet!);
      if (walletClient != null) return walletClient;
    }
    final node = appStore.settingsStore.getCurrentNode(appStore.wallet!.type);
    return Web3Client(node.uri.toString(), ProxyWrapper().getHttpIOClient());
  }

  Future<void> personalSign(String topic, dynamic parameters) async {
    printV('personalSign request: $parameters');

    final pRequest = walletKit.pendingRequests.getAll().last;
    final address = EthUtils.getAddressFromSessionRequest(pRequest);
    final data = EthUtils.getDataFromSessionRequest(pRequest);
    final message = EthUtils.getUtf8Message(data.toString());
    var response = JsonRpcResponse(id: pRequest.id, jsonrpc: '2.0');

    final decoded = WCDecodedRequest(
      actionTitle: S.current.wc_action_sign_message,
      rows: [WCDecodedRow(label: S.current.wc_message_label, value: message)],
      hideTo: true,
      hideZeroValue: true,
    );

    final isApproved = await MethodsUtils.requestApproval(
      decoded,
      method: pRequest.method,
      chainId: pRequest.chainId,
      address: address,
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
        printV('personalSign error $e');
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
    printV('ethSign request: $parameters');

    final pRequest = walletKit.pendingRequests.getAll().last;
    final address = EthUtils.getAddressFromSessionRequest(pRequest);
    final data = EthUtils.getDataFromSessionRequest(pRequest);
    final message = EthUtils.getUtf8Message(data.toString());
    var response = JsonRpcResponse(id: pRequest.id, jsonrpc: '2.0');

    final decoded = WCDecodedRequest(
      actionTitle: S.current.wc_action_sign_message,
      rows: [WCDecodedRow(label: S.current.wc_message_label, value: message)],
      hideTo: true,
      hideZeroValue: true,
    );

    final isApproved = await MethodsUtils.requestApproval(
      decoded,
      method: pRequest.method,
      chainId: pRequest.chainId,
      address: address,
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
        printV('ethSign error $e');
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
    printV('ethSignTypedData request: $parameters');

    final pRequest = walletKit.pendingRequests.getAll().last;
    final address = EthUtils.getAddressFromSessionRequest(pRequest);
    final data = EthUtils.getDataFromSessionRequest(pRequest) as String;
    var response = JsonRpcResponse(id: pRequest.id, jsonrpc: '2.0');

    final decoded = typedDataDecoder.decode(data);

    final isApproved = await MethodsUtils.requestApproval(
      decoded,
      method: pRequest.method,
      chainId: pRequest.chainId,
      address: address,
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
        printV('ethSignTypedData error $e');
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
    printV('ethSignTypedDataV4 request: $parameters');

    final pRequest = walletKit.pendingRequests.getAll().last;
    final address = EthUtils.getAddressFromSessionRequest(pRequest);
    final data = EthUtils.getDataFromSessionRequest(pRequest) as String;
    var response = JsonRpcResponse(id: pRequest.id, jsonrpc: '2.0');

    final decoded = typedDataDecoder.decode(parameters);

    final isApproved = await MethodsUtils.requestApproval(
      decoded,
      method: pRequest.method,
      chainId: pRequest.chainId,
      address: address,
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
        printV('ethSignTypedDataV4 error $e');
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
    printV('ethSignTransaction request: $parameters');

    final SessionRequest pRequest = walletKit.pendingRequests.getAll().last;
    final data = EthUtils.getTransactionFromSessionRequest(pRequest);
    if (data == null) return;

    final address = EthUtils.getAddressFromSessionRequest(pRequest);
    var response = JsonRpcResponse(id: pRequest.id, jsonrpc: '2.0');

    final transaction = await _approveTransaction(
      data,
      method: pRequest.method,
      chainId: pRequest.chainId,
      address: address,
      transportType: pRequest.transportType.name,
      verifyContext: pRequest.verifyContext,
    );

    if (transaction is Transaction) {
      try {
        final keys = wcKeyService.getKeysForChain(appStore.wallet!);
        final credentials = EthPrivateKey.fromHex(keys[0].privateKey);
        final chainId = getChainId().split(':').last;
        final signature = await ethClient.signTransaction(
          credentials,
          transaction,
          chainId: int.parse(chainId),
        );
        final signedTx = bytesToHex(signature, include0x: true);
        response = response.copyWith(result: signedTx);
      } on RPCError catch (e) {
        printV('ethSignTransaction error $e');
        response = response.copyWith(
          error: JsonRpcError(code: e.errorCode, message: e.message),
        );
      } catch (e) {
        printV('ethSignTransaction error $e');
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
    printV('ethSendTransaction request: $parameters');
    final SessionRequest pRequest = walletKit.pendingRequests.getAll().last;

    final data = EthUtils.getTransactionFromSessionRequest(pRequest);
    if (data == null) return;

    var response = JsonRpcResponse(id: pRequest.id, jsonrpc: '2.0');

    final transaction = await _approveTransaction(
      data,
      method: pRequest.method,
      chainId: pRequest.chainId,
      transportType: pRequest.transportType.name,
      verifyContext: pRequest.verifyContext,
    );
    if (transaction is Transaction) {
      try {
        final keys = wcKeyService.getKeysForChain(appStore.wallet!);
        final credentials = EthPrivateKey.fromHex(keys[0].privateKey);
        final chainId = getChainId().split(':').last;
        final signedTx = await ethClient.sendTransaction(
          credentials,
          transaction,
          chainId: int.parse(chainId),
        );
        response = response.copyWith(result: signedTx);
      } on RPCError catch (e) {
        printV('ethSendTransaction error $e');
        response = response.copyWith(
          error: JsonRpcError(code: e.errorCode, message: e.message),
        );
      } catch (e) {
        printV('ethSendTransaction error $e');
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

  Future<void> walletSwitchEthereumChain(String topic, dynamic parameters) async {
    printV('walletSwitchEthereumChain request: $parameters');
    final pRequest = walletKit.pendingRequests.getAll().last;
    var response = JsonRpcResponse(id: pRequest.id, jsonrpc: '2.0');

    final decoded = walletAdminDecoder.decodeSwitchChain(parameters);

    final isApproved = await MethodsUtils.requestApproval(
      decoded,
      method: pRequest.method,
      chainId: pRequest.chainId,
      transportType: pRequest.transportType.name,
      verifyContext: pRequest.verifyContext,
    );

    if (isApproved) {
      response = response.copyWith(result: null);
    } else {
      final error = Errors.getSdkError(Errors.USER_REJECTED);
      response = response.copyWith(
        error: JsonRpcError(code: error.code, message: error.message),
      );
    }

    _handleResponseForTopic(topic, response);
  }

  Future<void> walletAddEthereumChain(String topic, dynamic parameters) async {
    printV('walletAddEthereumChain request: $parameters');
    final pRequest = walletKit.pendingRequests.getAll().last;
    var response = JsonRpcResponse(id: pRequest.id, jsonrpc: '2.0');

    final decoded = walletAdminDecoder.decodeAddChain(parameters);

    final isApproved = await MethodsUtils.requestApproval(
      decoded,
      method: pRequest.method,
      chainId: pRequest.chainId,
      transportType: pRequest.transportType.name,
      verifyContext: pRequest.verifyContext,
    );

    if (isApproved) {
      response = response.copyWith(result: null);
    } else {
      final error = Errors.getSdkError(Errors.USER_REJECTED);
      response = response.copyWith(
        error: JsonRpcError(code: error.code, message: error.message),
      );
    }

    _handleResponseForTopic(topic, response);
  }

  void _handleResponseForTopic(String topic, JsonRpcResponse<dynamic> response) async {
    final session = walletKit.sessions.get(topic);
    try {
      await walletKit.respondSessionRequest(topic: topic, response: response);
      if (session == null) return;
      MethodsUtils.handleRedirect(
        topic,
        session.peer.metadata.redirect,
        response.error?.message,
        response.error == null,
      );
    } on ReownSignError catch (error) {
      if (session == null) return;
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
    VerifyContext? verifyContext,
    required String transportType,
  }) async {
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
        printV('Failed to parse gas value: $gasHex, error: $e');
      }
    }

    try {
      transaction = await _ensureWCTransactionHasGasLimit(transaction);
    } on RPCError catch (e) {
      return JsonRpcError(code: e.errorCode, message: e.message);
    }

    transaction = await _applyWCBufferedFees(transaction);

    final nativeCurrency = evm?.getChainInfoByChainId(reference.chainId ?? 1)?.currency;
    final nativeSymbol = nativeCurrency?.title ?? 'ETH';

    final valueWei = transaction.value?.getInWei ?? BigInt.zero;

    final decoded = await decoder.decodeTransaction(
      rawData: transactionJson['data']?.toString(),
      toAddress: transaction.to?.hex,
      fromAddress: transaction.from?.hex,
      nativeSymbol: nativeSymbol,
      valueWei: valueWei,
    );

    final mergedRows = <WCDecodedRow>[
      ...decoded.rows,
      if (transaction.from != null && !decoded.rows.any((r) => r.label == S.current.from))
        WCDecodedRow(
          label: S.current.from,
          value: transaction.from!.hex,
          kind: WCDecodedRowKind.address,
        ),
      if (!decoded.hideTo &&
          transaction.to != null &&
          !decoded.rows.any((r) => r.label == S.current.to))
        WCDecodedRow(
          label: S.current.to,
          value: transaction.to!.hex,
          kind: WCDecodedRowKind.address,
        ),
      if (!decoded.hideZeroValue || valueWei > BigInt.zero)
        WCDecodedRow(
          label: S.current.wc_value,
          value: '${decoder.tokenResolver.formatNative(valueWei.toDouble() / 1e18)} $nativeSymbol',
          kind: WCDecodedRowKind.amount,
        ),
    ];

    final finalDecoded = decoded.copyWith(rows: mergedRows);
    final feeRows = _buildFeeRows(transaction, nativeCurrency, nativeSymbol);

    final feeRows = _buildFeeExtraModels(transaction, nativeCurrency, nativeSymbol);

    if (await MethodsUtils.requestApproval(
      finalDecoded,
      title: title,
      method: method,
      chainId: chainId,
      address: address ?? transaction.from?.hex ?? '',
      transportType: transportType,
      verifyContext: verifyContext,
      extraRows: feeRows,
    )) {
    }

  List<WCDecodedRow> _buildFeeRows(
    Transaction transaction,
    CryptoCurrency? nativeCurrency,
    String nativeSymbol,
  ) {
    final gasLimit = transaction.maxGas;
        isEip1559 ? transaction.maxFeePerGas?.getInWei : transaction.gasPrice?.getInWei;
    if (perGasWei == null || perGasWei <= BigInt.zero) return const [];

    final feeWei = gasLimitBig * perGasWei;
    final feeNative = feeWei.toDouble() / 1e18;

    final cryptoPart = '${decoder.tokenResolver.formatNative(feeNative)} $nativeSymbol';
    final fiat = nativeCurrency == null
        ? null
        : decoder.tokenResolver.fiatFor(nativeCurrency, feeNative.toString());

    return [
      WCDecodedRow(
        label: isEip1559 ? S.current.wc_max_network_fee : S.current.wc_network_fee,
        value: cryptoPart,
        kind: WCDecodedRowKind.amount,
        fiatValue: fiat,
      ),
    ];
  }

  Future<Transaction> _ensureWCTransactionHasGasLimit(Transaction transaction) async {
    final hasGasLimit = transaction.maxGas != null && transaction.maxGas! > 0;
    if (hasGasLimit) return transaction;

    final hint = transaction.gasPrice ?? transaction.maxFeePerGas ?? await ethClient.getGasPrice();

    final gasLimit = await ethClient.estimateGas(
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

  Future<Transaction> _applyWCBufferedFees(Transaction transaction) async {
    try {
      final storedPriority =
          appStore.settingsStore.getPriority(appStore.wallet!.type, chainId: reference.chainId);
      final priority = storedPriority ?? evm!.getDefaultTransactionPriority();

      final quote = await evm!.getWCBufferedFeeQuote(appStore.wallet!, priority);
      if (quote != null) {
        return _mergeWCBufferedFees(transaction, quote);
      }
    } catch (e) {
      printV('WalletConnect fee refresh failed: $e');
    }

    if (!transaction.isEIP1559 && transaction.gasPrice == null) {
      return transaction.copyWith(gasPrice: await ethClient.getGasPrice());
    }

    return transaction;
  }

  Transaction _mergeWCBufferedFees(Transaction transaction, EvmWalletConnectFeeQuote quote) {
    if (transaction.isEIP1559) {
      final dAppMax = transaction.maxFeePerGas?.getInWei ?? BigInt.zero;
      final dAppPri = transaction.maxPriorityFeePerGas?.getInWei ?? BigInt.zero;
      final quoteMax = BigInt.from(quote.maxFeePerGasWei);
      final quotePri = BigInt.from(quote.maxPriorityFeePerGasWei);

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

  void _onSessionRequest(SessionRequestEvent? args) async {
    if (args != null && args.chainId == getChainId()) {
      printV('_onSessionRequest ${args.toString()}');
      final handler = sessionRequestHandlers[args.method];
      if (handler != null) {
        await handler(args.topic, args.params);
      }
    }
  }

  bool isValidSignature(String hexSignature, String message, String hexAddress) {
    try {
      final recoveredAddress = EthSigUtil.recoverPersonalSignature(
        signature: hexSignature,
        message: utf8.encode(message),
      );
      return recoveredAddress == hexAddress;
    } catch (e) {
      return false;
    }
  }
}
