import "dart:async";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/reactions/wallet_connect.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/erc20_token_resolver.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_request_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/typed_data_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/wallet_admin_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart";
import "package:cake_wallet/src/screens/wallet_connect/services/bottom_sheet_service.dart";
import "package:cake_wallet/src/screens/wallet_connect/widgets/bottom_sheet/bottom_sheet_message_display_widget.dart";
import "package:cake_wallet/src/screens/wallet_connect/services/chain_service/eth/evm_chain_id.dart";
import "package:cake_wallet/src/screens/wallet_connect/services/chain_service/eth/evm_supported_methods.dart";
import "package:cake_wallet/src/screens/wallet_connect/services/key_service/wallet_connect_key_service.dart";
import "package:cake_wallet/src/screens/wallet_connect/utils/eth_utils.dart";
import "package:cake_wallet/src/screens/wallet_connect/utils/method_utils.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/utils/proxy_wrapper.dart";
import "package:eth_sig_util/eth_sig_util.dart";
import "package:eth_sig_util/util/utils.dart";
import "package:reown_walletkit/reown_walletkit.dart";

class EvmChainServiceImpl {
  EvmChainServiceImpl({
    required this.reference,
    required this.appStore,
    required this.wcKeyService,
    required this.bottomSheetService,
    required this.walletKit,
    Web3Client? web3Client,
  })  : ethClient = web3Client ?? _createWeb3Client(reference, appStore),
        decoder = EvmRequestDecoder(appStore),
        typedDataDecoder = TypedDataDecoder(Erc20TokenResolver(appStore)),
        walletAdminDecoder = WalletAdminDecoder() {
    for (final event in EventsConstants.allEvents) {
      walletKit.registerEventEmitter(
        chainId: getChainId(),
        event: event,
      );
    }

    for (final handler in methodRequestHandlers.entries) {
      walletKit.registerRequestHandler(
        chainId: getChainId(),
        method: handler.key,
        handler: handler.value,
      );
    }
    for (final handler in sessionRequestHandlers.entries) {
      walletKit.registerRequestHandler(
        chainId: getChainId(),
        method: handler.key,
        handler: handler.value,
      );
    }
  }
  Map<String, dynamic Function(String, dynamic)> get sessionRequestHandlers => {
        EVMSupportedMethods.ethSign.name: ethSign,
        EVMSupportedMethods.ethSignTransaction.name: ethSignTransaction,
        EVMSupportedMethods.ethSignTypedData.name: ethSignTypedData,
        EVMSupportedMethods.ethSignTypedDataV3.name: ethSignTypedDataV3,
        EVMSupportedMethods.ethSignTypedDataV4.name: ethSignTypedDataV4,
      };

  Map<String, dynamic Function(String, dynamic)> get methodRequestHandlers => {
        EVMSupportedMethods.personalSign.name: personalSign,
        EVMSupportedMethods.ethSendTransaction.name: ethSendTransaction,
        EVMSupportedMethods.switchChain.name: walletSwitchEthereumChain,
        EVMSupportedMethods.addChain.name: walletAddEthereumChain,
      };

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
      if (walletClient != null) {
        return walletClient;
      }
    }
    final node = appStore.settingsStore.getCurrentNode(appStore.wallet!.type);
    return Web3Client(node.uri.toString(), ProxyWrapper().getHttpIOClient());
  }

  Future<void> personalSign(String topic, dynamic parameters) async {
    final error = Errors.getSdkError(Errors.USER_REJECTED);
    await _signMessage(
      topic,
      parameters,
      EVMSupportedMethods.personalSign,
      rejectError: JsonRpcError(code: error.code, message: error.message),
    );
  }

  Future<void> ethSign(String topic, dynamic parameters) async {
    final error = Errors.getSdkError(Errors.USER_REJECTED).toSignError();
    await _signMessage(
      topic,
      parameters,
      EVMSupportedMethods.ethSign,
      rejectError: JsonRpcError(code: error.code, message: error.message),
    );
  }

  Future<void> _signMessage(
    String topic,
    dynamic parameters,
    EVMSupportedMethods method, {
    required JsonRpcError rejectError,
  }) async {
    printV("${method.name} request: $parameters");

    final pRequest = MethodsUtils.pendingRequestFor(topic, method.name, getChainId());
    if (pRequest == null) {
      return;
    }

    final address = EthUtils.getAddressFromSessionRequest(pRequest);
    if (!await _authorizeRequest(topic, pRequest.id, requestAddress: address)) {
      return;
    }

    var response = JsonRpcResponse(id: pRequest.id, jsonrpc: "2.0");

    final payload = EthUtils.getDataFromSessionRequest(pRequest);
    if (payload is! String) {
      await _respondMalformed(topic, response);
      return;
    }

    final message = EthUtils.getUtf8Message(payload);

    final decoded = WCDecodedRequest(
      actionTitle: S.current.wc_action_sign_message,
      rows: [WCDecodedRow(label: S.current.wc_message_label, value: message)],
      hideTo: true,
      hideValue: true,
    );

    final isApproved = await MethodsUtils.requestApproval(
      decoded,
      topic: topic,
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
          EthUtils.getMessageBytes(payload),
        );
        response = response.copyWith(result: bytesToHex(signature, include0x: true));
      } catch (e) {
        printV("${method.name} error $e");
        final error = Errors.getSdkError(Errors.MALFORMED_REQUEST_PARAMS);
        response = response.copyWith(
          error: JsonRpcError(code: error.code, message: error.message),
        );
      }
    } else {
      response = response.copyWith(error: rejectError);
    }

    await MethodsUtils.respondForTopic(topic, response);
  }

  Future<void> ethSignTypedData(String topic, dynamic parameters) async {
    final error = Errors.getSdkError(Errors.USER_REJECTED).toSignError();
    await _signTypedData(
      topic,
      parameters,
      EVMSupportedMethods.ethSignTypedData,
      rejectError: JsonRpcError(code: error.code, message: error.message),
    );
  }

  Future<void> ethSignTypedDataV3(String topic, dynamic parameters) async {
    final error = Errors.getSdkError(Errors.USER_REJECTED).toSignError();
    await _signTypedData(
      topic,
      parameters,
      EVMSupportedMethods.ethSignTypedDataV3,
      rejectError: JsonRpcError(code: error.code, message: error.message),
    );
  }

  Future<void> ethSignTypedDataV4(String topic, dynamic parameters) async {
    await _signTypedData(
      topic,
      parameters,
      EVMSupportedMethods.ethSignTypedDataV4,
      rejectError: JsonRpcError(code: 5002, message: S.current.user_rejected_method),
    );
  }

  Future<void> _signTypedData(
    String topic,
    dynamic parameters,
    EVMSupportedMethods method, {
    required JsonRpcError rejectError,
  }) async {
    printV("${method.name} request: $parameters");

    final pRequest = MethodsUtils.pendingRequestFor(topic, method.name, getChainId());
    if (pRequest == null) {
      return;
    }

    final address = EthUtils.getAddressFromSessionRequest(pRequest);
    if (!await _authorizeRequest(topic, pRequest.id, requestAddress: address)) {
      return;
    }

    var response = JsonRpcResponse(id: pRequest.id, jsonrpc: "2.0");

    final data = EthUtils.stringifyTypedData(EthUtils.getDataFromSessionRequest(pRequest));
    if (data == null) {
      await _respondMalformed(topic, response);
      return;
    }

    final decoded = await _safeDecodeTypedData(parameters: data, rawForFallback: data);

    final isApproved = await MethodsUtils.requestApproval(
      decoded,
      topic: topic,
      method: pRequest.method,
      chainId: pRequest.chainId,
      address: address,
      transportType: pRequest.transportType.name,
      verifyContext: pRequest.verifyContext,
    );

    if (isApproved) {
      try {
        final keys = wcKeyService.getKeysForChain(appStore.wallet!);
        TypedDataVersion version;
        if (method == EVMSupportedMethods.ethSignTypedDataV3) {
          version = TypedDataVersion.V3;
        } else if (method == EVMSupportedMethods.ethSignTypedDataV4) {
          version = TypedDataVersion.V4;
        } else {
          // Legacy eth_signTypedData carries a V1 payload (a JSON array of
          // typed entries). Hashing that as V4 produces a signature no dApp
          // can recover.
          version = data.trimLeft().startsWith("[") ? TypedDataVersion.V1 : TypedDataVersion.V4;
        }
        final signature = EthSigUtil.signTypedData(
          privateKey: keys[0].privateKey,
          jsonData: data,
          version: version,
        );
        response = response.copyWith(result: signature);
      } catch (e) {
        printV("${method.name} error $e");
        final error = Errors.getSdkError(Errors.MALFORMED_REQUEST_PARAMS);
        response = response.copyWith(
          error: JsonRpcError(code: error.code, message: error.message),
        );
      }
    } else {
      response = response.copyWith(error: rejectError);
    }

    await MethodsUtils.respondForTopic(topic, response);
  }

  Future<void> ethSignTransaction(String topic, dynamic parameters) async {
    printV("ethSignTransaction request: $parameters");

    final pRequest = MethodsUtils.pendingRequestFor(
        topic, EVMSupportedMethods.ethSignTransaction.name, getChainId());
    if (pRequest == null) {
      return;
    }

    final data = EthUtils.getTransactionFromSessionRequest(pRequest);
    var response = JsonRpcResponse(id: pRequest.id, jsonrpc: "2.0");

    if (data == null) {
      await _respondMalformed(topic, response);
      return;
    }

    if (!await _authorizeRequest(topic, pRequest.id, requestAddress: data["from"]?.toString())) {
      return;
    }

    final address = EthUtils.getAddressFromSessionRequest(pRequest);

    final transaction = await _approveTransaction(
      data,
      topic: topic,
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
        final chainId = getChainId().split(":").last;
        final signature = await ethClient.signTransaction(
          credentials,
          transaction,
          chainId: int.parse(chainId),
        );
        final signedTx = bytesToHex(signature, include0x: true);
        response = response.copyWith(result: signedTx);
      } on RPCError catch (e) {
        printV("ethSignTransaction error $e");
        response = response.copyWith(
          error: JsonRpcError(code: e.errorCode, message: e.message),
        );
      } catch (e) {
        printV("ethSignTransaction error $e");
        final error = Errors.getSdkError(Errors.MALFORMED_REQUEST_PARAMS);
        response = response.copyWith(
          error: JsonRpcError(code: error.code, message: error.message),
        );
      }
    } else {
      response = response.copyWith(error: transaction as JsonRpcError);
    }

    await MethodsUtils.respondForTopic(topic, response);
  }

  Future<void> ethSendTransaction(String topic, dynamic parameters) async {
    printV("ethSendTransaction request: $parameters");

    final pRequest = MethodsUtils.pendingRequestFor(
        topic, EVMSupportedMethods.ethSendTransaction.name, getChainId());
    if (pRequest == null) {
      return;
    }

    final data = EthUtils.getTransactionFromSessionRequest(pRequest);
    var response = JsonRpcResponse(id: pRequest.id, jsonrpc: "2.0");

    if (data == null) {
      await _respondMalformed(topic, response);
      return;
    }

    if (!await _authorizeRequest(topic, pRequest.id, requestAddress: data["from"]?.toString())) {
      return;
    }

    final transaction = await _approveTransaction(
      data,
      topic: topic,
      method: pRequest.method,
      chainId: pRequest.chainId,
      transportType: pRequest.transportType.name,
      verifyContext: pRequest.verifyContext,
    );
    if (transaction is Transaction) {
      try {
        final keys = wcKeyService.getKeysForChain(appStore.wallet!);
        final credentials = EthPrivateKey.fromHex(keys[0].privateKey);
        final chainId = getChainId().split(":").last;
        final signedTx = await ethClient.sendTransaction(
          credentials,
          transaction,
          chainId: int.parse(chainId),
        );
        response = response.copyWith(result: signedTx);
      } on RPCError catch (e) {
        printV("ethSendTransaction error $e");
        response = response.copyWith(
          error: JsonRpcError(code: e.errorCode, message: e.message),
        );
      } catch (e) {
        printV("ethSendTransaction error $e");
        final error = Errors.getSdkError(Errors.MALFORMED_REQUEST_PARAMS);
        response = response.copyWith(
          error: JsonRpcError(code: error.code, message: error.message),
        );
      }
    } else {
      response = response.copyWith(error: transaction as JsonRpcError);
    }

    await MethodsUtils.respondForTopic(topic, response);
  }

  Future<void> walletSwitchEthereumChain(String topic, dynamic parameters) async {
    printV("walletSwitchEthereumChain request: $parameters");
    final pRequest =
        MethodsUtils.pendingRequestFor(topic, EVMSupportedMethods.switchChain.name, getChainId());
    if (pRequest == null) {
      return;
    }

    if (!await _authorizeRequest(topic, pRequest.id)) {
      return;
    }

    var response = JsonRpcResponse(id: pRequest.id, jsonrpc: "2.0");

    final targetChainId = walletAdminDecoder.extractChainId(parameters);
    final currentChainId = reference.chainId;
    final canSwitch = targetChainId != null && targetChainId == currentChainId;

    final decoded = walletAdminDecoder.decodeSwitchChain(parameters);

    final isApproved = await MethodsUtils.requestApproval(
      decoded,
      topic: topic,
      method: pRequest.method,
      chainId: pRequest.chainId,
      transportType: pRequest.transportType.name,
      verifyContext: pRequest.verifyContext,
    );

    if (!isApproved) {
      final error = Errors.getSdkError(Errors.USER_REJECTED);
      response = response.copyWith(
        error: JsonRpcError(code: error.code, message: error.message),
      );
    } else if (!canSwitch) {
      response = response.copyWith(
        error: JsonRpcError(
          code: 4902,
          message: S.current.wc_warning_chain_not_supported,
        ),
      );
    } else {
      response = response.copyWith(result: null);
    }

    await MethodsUtils.respondForTopic(topic, response);
  }

  Future<void> walletAddEthereumChain(String topic, dynamic parameters) async {
    printV("walletAddEthereumChain request: $parameters");
    final pRequest =
        MethodsUtils.pendingRequestFor(topic, EVMSupportedMethods.addChain.name, getChainId());
    if (pRequest == null) {
      return;
    }

    if (!await _authorizeRequest(topic, pRequest.id)) {
      return;
    }

    var response = JsonRpcResponse(id: pRequest.id, jsonrpc: "2.0");

    final decoded = walletAdminDecoder.decodeAddChain(parameters);

    final isApproved = await MethodsUtils.requestApproval(
      decoded,
      topic: topic,
      method: pRequest.method,
      chainId: pRequest.chainId,
      transportType: pRequest.transportType.name,
      verifyContext: pRequest.verifyContext,
    );

    if (!isApproved) {
      final error = Errors.getSdkError(Errors.USER_REJECTED);
      response = response.copyWith(
        error: JsonRpcError(code: error.code, message: error.message),
      );
    } else {
      response = response.copyWith(
        error: JsonRpcError(
          code: 4902,
          message: S.current.wc_warning_add_chain_not_supported,
        ),
      );
    }

    await MethodsUtils.respondForTopic(topic, response);
  }

  /// True when this request may be answered: the session must belong to the
  /// open wallet, and any address the dApp names must be that wallet's. A
  /// request for a different wallet is rejected and the user is told why,
  /// so switching wallets in the app cannot hand a dApp the wrong account.
  Future<bool> _authorizeRequest(String topic, int requestId, {String? requestAddress}) async {
    final wallet = appStore.wallet;
    if (wallet == null) {
      return false;
    }

    final keys = wcKeyService.getKeysForChain(wallet);
    if (keys.isEmpty) {
      return false;
    }

    final walletAddress = keys.first.publicKey;
    final ownsSession =
        MethodsUtils.isSessionOwnedByWallet(walletKit.sessions.get(topic), walletAddress);
    final addressMatches =
        requestAddress == null || MethodsUtils.isSameAccount(requestAddress, walletAddress);

    if (ownsSession && addressMatches) {
      return true;
    }

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
      printV("_authorizeRequest reject failed: $e");
    }

    return false;
  }

  Future<void> _respondMalformed(String topic, JsonRpcResponse<dynamic> response) async {
    final error = Errors.getSdkError(Errors.MALFORMED_REQUEST_PARAMS);
    await MethodsUtils.respondForTopic(
      topic,
      response.copyWith(error: JsonRpcError(code: error.code, message: error.message)),
    );
  }

  Future<WCDecodedRequest> _safeDecodeTransaction({
    required String? rawData,
    required String? toAddress,
    required String? fromAddress,
    required String nativeSymbol,
    required BigInt valueWei,
  }) async {
    try {
      return await decoder.decodeTransaction(
        rawData: rawData,
        toAddress: toAddress,
        fromAddress: fromAddress,
        nativeSymbol: nativeSymbol,
        valueWei: valueWei,
      );
    } catch (e, s) {
      printV("decodeTransaction threw, falling back to the contract-call view: $e\n$s");
      return WCDecodedRequest(
        actionTitle: S.current.wc_contract_call,
        warnings: [S.current.wc_warning_unknown_contract],
      );
    }
  }

  // A decoder bug must never block signing, so any exception falls back to
  // the raw JSON view.
  Future<WCDecodedRequest> _safeDecodeTypedData({
    required dynamic parameters,
    required String rawForFallback,
  }) async {
    try {
      return await typedDataDecoder.decode(parameters);
    } catch (e, s) {
      printV("typedDataDecoder.decode threw, falling back to raw view: $e\n$s");
      return WCDecodedRequest(
        actionTitle: S.current.wc_action_sign_typed_data,
        warnings: [S.current.wc_warning_typed_data_invalid],
        rawFallback: rawForFallback,
      );
    }
  }

  Future<dynamic> _approveTransaction(
    Map<String, dynamic> transactionJson, {
    required String topic,
    required String transportType,
    String? title,
    String? method,
    String? chainId,
    String? address,
    VerifyContext? verifyContext,
  }) async {
    Transaction transaction = transactionJson.toTransaction();

    if (transactionJson.containsKey("gas") && transaction.maxGas == null) {
      final gasHex = transactionJson["gas"].toString();
      try {
        final gasValue = int.parse(
          gasHex.replaceFirst("0x", "").replaceFirst("0X", ""),
          radix: 16,
        );
        transaction = transaction.copyWith(maxGas: gasValue);
      } catch (e) {
        printV("Failed to parse gas value: $gasHex, error: $e");
      }
    }

    try {
      transaction = await _ensureWCTransactionHasGasLimit(transaction);
    } on RPCError catch (e) {
      return JsonRpcError(code: e.errorCode, message: e.message);
    }

    transaction = await _applyWCBufferedFees(transaction);

    final nativeCurrency = evm?.getChainInfoByChainId(reference.chainId ?? 1)?.currency;
    final nativeSymbol = nativeCurrency?.title ?? "ETH";

    final valueWei = transaction.value?.getInWei ?? BigInt.zero;

    final decoded = await _safeDecodeTransaction(
      rawData: transactionJson["data"]?.toString(),
      toAddress: transaction.to?.hex,
      fromAddress: transaction.from?.hex,
      nativeSymbol: nativeSymbol,
      valueWei: valueWei,
    );

    final mergedRows = <WCDecodedRow>[
      ...decoded.rows,
      if (!decoded.hideTo &&
          transaction.to != null &&
          !decoded.rows.any((r) => r.label == S.current.to))
        WCDecodedRow(
          label: S.current.to,
          value: transaction.to!.hex,
          kind: WCDecodedRowKind.address,
        ),
      if (!decoded.hideValue && valueWei > BigInt.zero)
        WCDecodedRow(
          label: S.current.wc_value,
          value: "${decoder.tokenResolver.formatNativeAmount(valueWei)} $nativeSymbol",
          kind: WCDecodedRowKind.amount,
        ),
    ];

    final rawData = transactionJson["data"]?.toString();
    final hasCalldata = rawData != null && rawData.replaceFirst("0x", "").isNotEmpty;

    final finalDecoded = decoded.copyWith(
      rows: mergedRows,
      rawFallback: decoded.rawFallback ?? (hasCalldata ? rawData : null),
    );
    final feeRows = _buildFeeRows(transaction, nativeCurrency, nativeSymbol);

    if (await MethodsUtils.requestApproval(
      finalDecoded,
      topic: topic,
      title: title,
      method: method,
      chainId: chainId,
      address: address ?? transaction.from?.hex ?? "",
      transportType: transportType,
      verifyContext: verifyContext,
      extraRows: feeRows,
    )) {
      return transaction;
    }

    return JsonRpcError(code: 5002, message: S.current.user_rejected_method);
  }

  List<WCDecodedRow> _buildFeeRows(
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
    final feeText = decoder.tokenResolver.formatNativeAmount(feeWei);

    final cryptoPart = "$feeText $nativeSymbol";
    final fiat =
        nativeCurrency == null ? null : decoder.tokenResolver.fiatFor(nativeCurrency, feeText);

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
    if (hasGasLimit) {
      return transaction;
    }

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
      printV("WalletConnect fee refresh failed: $e");
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
}
