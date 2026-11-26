import "dart:async";

import 'package:cake_wallet/generated/i18n.dart';
import 'package:cw_core/crypto_currency.dart';
import "package:cw_core/utils/print_verbose.dart";
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:eth_sig_util/util/utils.dart';
import 'package:flutter/material.dart';
import 'package:reown_walletkit/reown_walletkit.dart';

import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/erc20_token_resolver.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_request_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/typed_data_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/wallet_admin_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart";
import 'package:cake_wallet/src/screens/wallet_connect/services/bottom_sheet_service.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/chain_service/eth/evm_chain_id.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/chain_service/eth/evm_supported_methods.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/key_service/wallet_connect_key_service.dart';
import 'package:cake_wallet/src/screens/wallet_connect/utils/eth_utils.dart';
import 'package:cake_wallet/src/screens/wallet_connect/utils/method_utils.dart';
import "package:cake_wallet/src/screens/wallet_connect/widgets/bottom_sheet/bottom_sheet_message_display_widget.dart";
import 'package:cake_wallet/store/app_store.dart';
import "package:cake_wallet/store/dashboard/fiat_conversion_store.dart";
import 'package:cake_wallet/evm/evm.dart';

class EvmChainServiceImpl {
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

  EvmChainServiceImpl({
    required this.reference,
    required this.appStore,
    required this.wcKeyService,
    required this.bottomSheetService,
    required this.walletKit,
    required FiatConversionStore fiatConversionStore,
    Web3Client? web3Client,
  })  : _web3Client = web3Client,
        decoder = EvmRequestDecoder(appStore, fiatConversionStore: fiatConversionStore),
        typedDataDecoder = TypedDataDecoder(Erc20TokenResolver(appStore)),
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
  }

  final AppStore appStore;
  final EVMChainId reference;
  final Web3Client? _web3Client;
  final ReownWalletKit walletKit;
  final WalletConnectKeyService wcKeyService;
  final BottomSheetService bottomSheetService;
  final EvmRequestDecoder decoder;
  final TypedDataDecoder typedDataDecoder;
  final WalletAdminDecoder walletAdminDecoder;

  String getChainId() => reference.chain();

  Web3Client get ethClient {
    final wallet = appStore.wallet!;
    final walletClient = _web3Client ?? evm?.getWeb3Client(wallet);
    if (walletClient != null) {
      return walletClient;
    }

    return _ownClient;
  }

  late final _ownClient = Web3Client(
    appStore.settingsStore
        .getCurrentNode(appStore.wallet!.type, chainId: reference.chainId)
        .uri
        .toString(),
    ProxyWrapper().getHttpIOClient(),
  );

  Future<void> personalSign(String topic, dynamic parameters) =>
      _signMessage(topic, parameters, EVMSupportedMethods.personalSign);

  Future<void> ethSign(String topic, dynamic parameters) =>
      _signMessage(topic, parameters, EVMSupportedMethods.ethSign);

  Future<void> _signMessage(String topic, dynamic parameters, EVMSupportedMethods method) async {
    printV("${method.name} request: $parameters");

    final pRequest = MethodsUtils.pendingRequestFor(topic, method.name, getChainId(), parameters);
    if (pRequest == null) {
      return;
    }

    final address = EthUtils.getAddressFromSessionRequest(pRequest);
    if (!await _authorizeRequest(topic, pRequest.id, requestAddress: address)) {
      return;
    }

    var response = JsonRpcResponse(id: pRequest.id, jsonrpc: '2.0');

    final payload = EthUtils.getDataFromSessionRequest(pRequest);
    if (payload is! String) {
      await _respondMalformed(topic, response);
      return;
    }

    final message = EthUtils.getUtf8Message(payload);

    final decoded = WCDecodedRequest.signMessage(message);

    final isApproved = await MethodsUtils.requestApproval(
      decoded,
      topic: topic,
      method: pRequest.method,
      chainId: pRequest.chainId,
      address: _walletAddress(),
      transportType: pRequest.transportType.name,
      verifyContext: pRequest.verifyContext,
    );

    if (isApproved && !await _isRequestStillValid(topic, pRequest.id, requestAddress: address)) {
      return;
    }

    if (isApproved) {
      try {
        final credentials = EthPrivateKey.fromHex(wcKeyService.getPrivateKey(appStore.wallet!));
        final signature = credentials.signPersonalMessageToUint8List(
          EthUtils.getMessageBytes(payload),
        );
        response = response.copyWith(result: bytesToHex(signature, include0x: true));
      } catch (e) {
        printV("${method.name} error $e");
        response = response.copyWith(error: _malformedError());
      }
    } else {
      response = response.copyWith(error: MethodsUtils.userRejectedError);
    }

    await MethodsUtils.respondForTopic(topic, response);
  }

  Future<void> ethSignTypedData(String topic, dynamic parameters) =>
      _signTypedData(topic, parameters, EVMSupportedMethods.ethSignTypedData);

  Future<void> ethSignTypedDataV3(String topic, dynamic parameters) =>
      _signTypedData(topic, parameters, EVMSupportedMethods.ethSignTypedDataV3);

  Future<void> ethSignTypedDataV4(String topic, dynamic parameters) =>
      _signTypedData(topic, parameters, EVMSupportedMethods.ethSignTypedDataV4);

  Future<void> _signTypedData(String topic, dynamic parameters, EVMSupportedMethods method) async {
    printV("${method.name} request: $parameters");

    final pRequest = MethodsUtils.pendingRequestFor(topic, method.name, getChainId(), parameters);
    if (pRequest == null) {
      return;
    }

    final address = EthUtils.getAddressFromSessionRequest(pRequest);
    if (!await _authorizeRequest(topic, pRequest.id, requestAddress: address)) {
      return;
    }

    var response = JsonRpcResponse(id: pRequest.id, jsonrpc: '2.0');

    final data = EthUtils.stringifyTypedData(EthUtils.getDataFromSessionRequest(pRequest));
    if (data == null) {
      await _respondMalformed(topic, response);
      return;
    }

    TypedDataVersion version;
    if (method == EVMSupportedMethods.ethSignTypedDataV3) {
      version = TypedDataVersion.V3;
    } else if (method == EVMSupportedMethods.ethSignTypedDataV4) {
      version = TypedDataVersion.V4;
    } else {
      version = data.trimLeft().startsWith("[") ? TypedDataVersion.V1 : TypedDataVersion.V4;
    }

    final int? domainChainId;
    try {
      TypedDataDecoder.validate(data, version);
      domainChainId = TypedDataDecoder.domainChainId(data);
    } catch (e) {
      printV("${method.name} refused, typed data does not match its declared types: $e");
      await _refuse(
        topic,
        response,
        code: _malformed.code,
        message: S.current.wc_warning_typed_data_invalid,
        reply: _typedDataInvalidReply,
      );
      return;
    }

    if (domainChainId != null && domainChainId != reference.chainId) {
      await _refuse(
        topic,
        response,
        code: _malformed.code,
        message: S.current.wc_typed_data_wrong_chain(domainChainId.toString()),
        reply: "The typed data is for chain $domainChainId, not for the chain of this request.",
      );
      return;
    }

    if (!await _switchToRequestNetwork(pRequest)) {
      return;
    }

    final WCDecodedRequest decoded;
    try {
      decoded = await typedDataDecoder.decode(
        data,
        walletAddress: _walletAddress(),
        chainId: reference.chainId,
        nativeSymbol: evm?.getChainInfoByChainId(reference.chainId!)?.currency.title ?? "ETH",
      );
    } catch (e, s) {
      printV("${method.name} refused, validated typed data could not be decoded: $e\n$s");
      await _refuse(
        topic,
        response,
        code: _malformed.code,
        message: S.current.wc_warning_typed_data_invalid,
        reply: _typedDataInvalidReply,
      );
      return;
    }

    final isApproved = await MethodsUtils.requestApproval(
      decoded,
      topic: topic,
      method: pRequest.method,
      chainId: pRequest.chainId,
      address: _walletAddress(),
      transportType: pRequest.transportType.name,
      verifyContext: pRequest.verifyContext,
    );

    if (isApproved && !await _isRequestStillValid(topic, pRequest.id, requestAddress: address)) {
      return;
    }

    if (isApproved && !await _isStillOnRequestNetwork(topic, response)) {
      return;
    }

    if (isApproved) {
      try {
        final signature = EthSigUtil.signTypedData(
          privateKey: wcKeyService.getPrivateKey(appStore.wallet!),
          jsonData: data,
          version: version,
        );
        response = response.copyWith(result: signature);
      } catch (e) {
        printV("${method.name} error $e");
        response = response.copyWith(error: _malformedError());
      }
    } else {
      response = response.copyWith(error: MethodsUtils.userRejectedError);
    }

    await MethodsUtils.respondForTopic(topic, response);
  }

  Future<void> ethSignTransaction(String topic, dynamic parameters) =>
      _signTransaction(topic, parameters, EVMSupportedMethods.ethSignTransaction);

  Future<void> ethSendTransaction(String topic, dynamic parameters) =>
      _signTransaction(topic, parameters, EVMSupportedMethods.ethSendTransaction);

  Future<void> _signTransaction(
    String topic,
    dynamic parameters,
    EVMSupportedMethods method,
  ) async {
    printV("${method.name} request: $parameters");

    final pRequest = MethodsUtils.pendingRequestFor(topic, method.name, getChainId(), parameters);
    if (pRequest == null) {
      return;
    }

    final data = EthUtils.getTransactionFromSessionRequest(pRequest);
    var response = JsonRpcResponse(id: pRequest.id, jsonrpc: "2.0");

    if (data == null) {
      await _respondMalformed(topic, response);
      return;
    }

    if (!await _authorizeRequest(
      topic,
      pRequest.id,
      requestAddress: data["from"]?.toString(),
    )) {
      return;
    }

    final transaction = await _approveTransaction(data, pRequest);
    if (transaction == null) {
      return;
    }

    try {
      final credentials = EthPrivateKey.fromHex(wcKeyService.getPrivateKey(appStore.wallet!));
      if (method == EVMSupportedMethods.ethSendTransaction) {
        final transactionHash = await ethClient.sendTransaction(
          credentials,
          transaction,
          chainId: reference.chainId,
        );
        response = response.copyWith(result: transactionHash);
      } else {
        final signature = await ethClient.signTransaction(
          credentials,
          transaction,
          chainId: reference.chainId,
        );
        final signedTx = transaction.isEIP1559
            ? prependTransactionType(0x02, signature)
            : signature;
        response = response.copyWith(result: bytesToHex(signedTx, include0x: true));
      }
    } on RPCError catch (e) {
      printV("${method.name} error $e");
      response = response.copyWith(
        error: JsonRpcError(code: e.errorCode, message: e.message),
      );
    } catch (e) {
      printV("${method.name} error $e");
      response = response.copyWith(error: _malformedError());
    }

    await MethodsUtils.respondForTopic(
      topic,
      response,
      isBroadcast: method == EVMSupportedMethods.ethSendTransaction,
    );
  }

  Future<void> walletSwitchEthereumChain(String topic, dynamic parameters) => _switchOrAddChain(
    topic,
    parameters,
    EVMSupportedMethods.switchChain,
    unsupportedChainCode: 4902,
    unsupportedChainMessage: S.current.wc_warning_chain_not_supported,
    unsupportedChainReply: "The wallet does not support this chain.",
  );

  Future<void> walletAddEthereumChain(String topic, dynamic parameters) => _switchOrAddChain(
    topic,
    parameters,
    EVMSupportedMethods.addChain,
    unsupportedChainCode: 4200,
    unsupportedChainMessage: S.current.wc_warning_add_chain_not_supported,
    unsupportedChainReply: "The wallet only has its built-in chains, this one was not added.",
  );

  Future<void> _switchOrAddChain(
    String topic,
    dynamic parameters,
    EVMSupportedMethods method, {
    required int unsupportedChainCode,
    required String unsupportedChainMessage,
    required String unsupportedChainReply,
  }) async {
    printV("${method.name} request: $parameters");

    final pRequest = MethodsUtils.pendingRequestFor(topic, method.name, getChainId(), parameters);
    if (pRequest == null) {
      return;
    }

    if (!await _authorizeRequest(topic, pRequest.id)) {
      return;
    }

    final response = JsonRpcResponse(id: pRequest.id, jsonrpc: "2.0");

    final targetChain = _builtInChain(walletAdminDecoder.extractChainId(parameters));
    if (targetChain == null) {
      await _refuse(
        topic,
        response,
        code: unsupportedChainCode,
        message: unsupportedChainMessage,
        reply: unsupportedChainReply,
      );
      return;
    }

    final switched = response.copyWith(result: "0x${targetChain.chainId.toRadixString(16)}");

    if (targetChain.chainId == evm!.getSelectedChainId(appStore.wallet!) &&
        _isChainInSession(topic, targetChain.chainId)) {
      await MethodsUtils.respondForTopic(topic, switched, isUserDecision: false);
      return;
    }

    if (!await _switchChain(pRequest, targetChain, method: method.name)) {
      return;
    }

    await MethodsUtils.respondForTopic(topic, switched);
    await _emitChainChanged(topic, targetChain.chainId);
  }

  Future<void> _lastNetworkSwitch = Future.value();

  Future<bool> _switchToRequestNetwork(SessionRequest request) async {
    final waitFor = _lastNetworkSwitch;
    final done = Completer<void>();
    _lastNetworkSwitch = done.future;

    await waitFor;

    try {
      if (!await _authorizeRequest(request.topic, request.id)) {
        return false;
      }

      final chain = evm!.getChainInfoByChainId(reference.chainId!)!;
      if (evm!.getSelectedChainId(appStore.wallet!) == chain.chainId) {
        return true;
      }

      final isSwitched = await _switchChain(
        request,
        chain,
        method: EVMSupportedMethods.switchChain.name,
        reason: S.current.wc_switch_to_continue(chain.name),
      );
      if (!isSwitched) {
        return false;
      }

      unawaited(_emitChainChanged(request.topic, chain.chainId));
      return true;
    } finally {
      done.complete();
    }
  }

  Future<bool> _switchChain(
    SessionRequest request,
    ChainInfo chain, {
    required String method,
    String? reason,
  }) async {
    final response = JsonRpcResponse(id: request.id, jsonrpc: "2.0");

    final isApproved = await MethodsUtils.requestApproval(
      walletAdminDecoder.decodeSwitchChain(chain, reason: reason),
      topic: request.topic,
      method: method,
      chainId: request.chainId,
      address: _walletAddress(),
      transportType: request.transportType.name,
      verifyContext: request.verifyContext,
    );

    if (!isApproved) {
      await MethodsUtils.respondForTopic(
        request.topic,
        response.copyWith(error: MethodsUtils.userRejectedError),
      );
      return false;
    }

    if (!await _isRequestStillValid(request.topic, request.id)) {
      return false;
    }

    try {
      await _addChainToSession(request.topic, chain.chainId);
      final wallet = appStore.wallet!;
      final node = appStore.settingsStore.getCurrentNode(wallet.type, chainId: chain.chainId);
      await evm!.selectChain(wallet, chain.chainId, node: node);
      return true;
    } catch (e) {
      printV("switching to chain ${chain.chainId} failed: $e");
      await _refuse(
        request.topic,
        response,
        code: 4901,
        message: S.current.wc_switch_chain_failed,
        reply: "The wallet could not switch to the requested chain.",
      );
      return false;
    }
  }

  ChainInfo? _builtInChain(int? chainId) {
    if (chainId == null || !EVMChainId.values.any((id) => id.chainId == chainId)) {
      return null;
    }

    return evm!.getChainInfoByChainId(chainId);
  }

  bool _isChainInSession(String topic, int chainId) {
    final chain = evm!.getCaip2ByChainId(chainId);
    final accounts = walletKit.sessions.get(topic)?.namespaces["eip155"]?.accounts ?? const [];

    return accounts.any((account) => account.startsWith("$chain:"));
  }

  Future<void> _addChainToSession(String topic, int chainId) async {
    if (_isChainInSession(topic, chainId)) {
      return;
    }

    final session = walletKit.sessions.get(topic)!;
    final namespace = session.namespaces["eip155"]!;
    final chain = evm!.getCaip2ByChainId(chainId);
    final address = _walletAddress();
    try {
      await walletKit
          .updateSession(
            topic: topic,
            namespaces: {
              ...session.namespaces,
              "eip155": namespace.copyWith(
                chains: namespace.chains == null ? null : [...namespace.chains!, chain],
                accounts: [...namespace.accounts, "$chain:$address"],
              ),
            },
          )
          .timeout(const Duration(seconds: 3));
    } on TimeoutException catch (e) {
      printV("session update was not acknowledged: $e");
    }
  }

  Future<void> _emitChainChanged(String topic, int chainId) async {
    try {
      await walletKit
          .emitSessionEvent(
            topic: topic,
            chainId: evm!.getCaip2ByChainId(chainId),
            event: SessionEventParams(name: "chainChanged", data: chainId),
          )
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      printV("chainChanged event failed: $e");
    }
  }

  Future<bool> _isRequestStillValid(String topic, int requestId, {String? requestAddress}) async {
    if (!await MethodsUtils.isRequestStillPending(topic, requestId)) {
      _showMessage(S.current.wc_request_expired);
      return false;
    }

    return _authorizeRequest(topic, requestId, requestAddress: requestAddress);
  }

  Future<bool> _authorizeRequest(String topic, int requestId, {String? requestAddress}) async {
    final wallet = appStore.wallet;
    if (wallet != null) {
      final keys = wcKeyService.getKeysForChain(wallet);
      if (keys.isNotEmpty &&
          keys.first.chains.contains(getChainId()) &&
          MethodsUtils.isSessionOwnedByWallet(
            walletKit.sessions.get(topic),
            keys.first.publicKey,
          ) &&
          (requestAddress == null ||
              MethodsUtils.isSameAccount(requestAddress, keys.first.publicKey))) {
        return true;
      }
    }

    _showMessage(S.current.wc_request_for_different_wallet);
    await MethodsUtils.respondUnauthorized(topic, requestId);

    return false;
  }

  String _walletAddress() => wcKeyService.getKeysForChain(appStore.wallet!).first.publicKey;

  Future<bool> _isStillOnRequestNetwork(String topic, JsonRpcResponse<dynamic> response) async {
    if (evm!.getSelectedChainId(appStore.wallet!) == reference.chainId) {
      return true;
    }

    final network = evm!.getChainInfoByChainId(reference.chainId!)?.name ?? getChainId();
    await _refuse(
      topic,
      response,
      code: 4901,
      message: S.current.wc_request_for_other_network(network),
      reply: "The wallet is no longer on the chain of this request.",
    );
    return false;
  }

  void _showMessage(String message) {
    unawaited(
      bottomSheetService.queueBottomSheet(
        isModalDismissible: true,
        widget: BottomSheetMessageDisplayWidget(message: message),
      ),
    );
  }

  Future<void> _refuse(
    String topic,
    JsonRpcResponse<dynamic> response, {
    required int code,
    required String message,
    required String reply,
  }) async {
    _showMessage(message);
    await MethodsUtils.respondForTopic(
      topic,
      response.copyWith(
        error: JsonRpcError(code: code, message: reply),
      ),
      isUserDecision: false,
    );
  }

  static final _malformed = Errors.getSdkError(Errors.MALFORMED_REQUEST_PARAMS);
  static const _typedDataInvalidReply = "The typed data is malformed and could not be read.";

  Future<void> _respondMalformed(String topic, JsonRpcResponse<dynamic> response) async {
    _showMessage(S.current.wc_request_malformed);
    await MethodsUtils.respondForTopic(
      topic,
      response.copyWith(error: _malformedError()),
      isUserDecision: false,
    );
  }

  JsonRpcError _malformedError() =>
      JsonRpcError(code: _malformed.code, message: _malformed.message);

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
        chainId: reference.chainId,
      );
    } catch (e, s) {
      printV("decodeTransaction threw, falling back to the contract-call view: $e\n$s");
      return WCDecodedRequest(
        actionTitle: S.current.wc_contract_call,
        rows: [
          if (toAddress != null)
            WCDecodedRow(label: S.current.to, value: toAddress, kind: WCDecodedRowKind.address),
        ],
        warnings: [S.current.wc_warning_unknown_contract],
      );
    }
  }

  Future<Transaction?> _approveTransaction(
    Map<String, dynamic> transactionJson,
    SessionRequest request,
  ) async {
    final topic = request.topic;
    final response = JsonRpcResponse(id: request.id, jsonrpc: "2.0");

    if (EthUtils.hasConflictingCalldata(transactionJson) ||
        EthUtils.hasMalformedQuantity(transactionJson)) {
      await _respondMalformed(topic, response);
      return null;
    }

    Transaction transaction;
    try {
      transaction = transactionJson.toTransaction();
    } catch (e) {
      printV("WalletConnect transaction could not be parsed: $e");
      await _respondMalformed(topic, response);
      return null;
    }

    final Object? gas = transactionJson["gas"];
    if (gas != null && transaction.maxGas == null) {
      final gasLimit = int.tryParse(gas.toString().substring(2), radix: 16);
      if (gasLimit == null) {
        await _respondMalformed(topic, response);
        return null;
      }
      transaction = transaction.copyWith(maxGas: gasLimit);
    }

    if (!await _switchToRequestNetwork(request)) {
      return null;
    }

    try {
      transaction = await _ensureWCTransactionHasGasLimit(transaction);
      transaction = await _applyWCBufferedFees(transaction);
    } catch (e) {
      printV("WalletConnect transaction could not be prepared: $e");
      _showMessage(S.current.wc_transaction_prepare_failed);
      await MethodsUtils.respondForTopic(
        topic,
        response.copyWith(
          error: e is RPCError
              ? JsonRpcError(code: e.errorCode, message: e.message)
              : const JsonRpcError(
                  code: -32000,
                  message: "The wallet could not prepare the transaction.",
                ),
        ),
        isUserDecision: false,
      );
      return null;
    }

    final nativeCurrency = evm?.getChainInfoByChainId(reference.chainId ?? 1)?.currency;
    final nativeSymbol = nativeCurrency?.title ?? 'ETH';

    final valueWei = transaction.value?.getInWei ?? BigInt.zero;
    final calldata = transaction.data;
    final rawData =
        calldata == null || calldata.isEmpty ? null : bytesToHex(calldata, include0x: true);

    final decoded = await _safeDecodeTransaction(
      rawData: rawData,
      toAddress: transaction.to?.hex,
      fromAddress: transaction.from?.hex,
      nativeSymbol: nativeSymbol,
      valueWei: valueWei,
    );

    final mergedRows = <WCDecodedRow>[
      ...decoded.rows,
      if (!decoded.isValueShown && valueWei > BigInt.zero)
        WCDecodedRow(
          label: S.current.wc_value,
          value: "${decoder.tokenResolver.formatNativeAmount(valueWei)} $nativeSymbol",
          kind: WCDecodedRowKind.amount,
        ),
    ];

    final finalDecoded = decoded.copyWith(
      rows: mergedRows,
      rawFallback: decoded.rawFallback ?? rawData,
    );
    final feeRows = _buildFeeRows(transaction, nativeCurrency, nativeSymbol);

    final isApproved = await MethodsUtils.requestApproval(
      finalDecoded,
      topic: topic,
      method: request.method,
      chainId: request.chainId,
      address: transaction.from?.hex ?? "",
      transportType: request.transportType.name,
      verifyContext: request.verifyContext,
      extraRows: feeRows,
    );

    if (!isApproved) {
      await MethodsUtils.respondForTopic(
        topic,
        response.copyWith(error: MethodsUtils.userRejectedError),
      );
      return null;
    }

    if (!await _isRequestStillValid(topic, request.id, requestAddress: transaction.from?.hex)) {
      return null;
    }

    if (!await _isStillOnRequestNetwork(topic, response)) {
      return null;
    }

    return transaction;
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
      debugPrint('WalletConnect fee refresh failed: $e');
    }

    if (!transaction.isEIP1559 && transaction.gasPrice == null) {
      return transaction.copyWith(gasPrice: await ethClient.getGasPrice());
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
}
