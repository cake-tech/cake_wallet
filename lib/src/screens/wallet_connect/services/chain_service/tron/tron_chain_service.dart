import "dart:async";
import "dart:convert";

import "package:blockchain_utils/blockchain_utils.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/services/bottom_sheet_service.dart";
import "package:cake_wallet/src/screens/wallet_connect/services/chain_service/tron/tron_chain_id.dart";
import "package:cake_wallet/src/screens/wallet_connect/services/chain_service/tron/tron_supported_methods.dart";
import "package:cake_wallet/src/screens/wallet_connect/services/chain_service/tron/tron_transaction_summary.dart";
import "package:cake_wallet/src/screens/wallet_connect/services/key_service/wallet_connect_key_service.dart";
import "package:cake_wallet/src/screens/wallet_connect/utils/method_utils.dart";
import "package:cake_wallet/src/screens/wallet_connect/widgets/bottom_sheet/bottom_sheet_message_display_widget.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/tron/tron.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:on_chain/tron/tron.dart";
import "package:reown_walletkit/reown_walletkit.dart";

class TronChainService {
  TronChainService({
    required this.appStore,
    required this.bottomSheetService,
    required this.walletKit,
    required this.wcKeyService,
    required this.reference,
  }) {
    for (final event in EventsConstants.allEvents) {
      walletKit.registerEventEmitter(chainId: getChainId(), event: event);
    }

    for (final handler in tronRequestHandlers.entries) {
      walletKit.registerRequestHandler(
        chainId: getChainId(),
        method: handler.key,
        handler: handler.value,
      );
    }
  }

  Map<String, dynamic Function(String, dynamic)> get tronRequestHandlers => {
        TronSupportedMethods.tronSignMessage.name: tronSignMessage,
        TronSupportedMethods.tronSignTransaction.name: tronSignTransaction,
      };

  final AppStore appStore;
  final BottomSheetService bottomSheetService;
  final ReownWalletKit walletKit;
  final WalletConnectKeyService wcKeyService;
  final TronChainId reference;

  String getChainId() => reference.chain();

  Future<void> tronSignMessage(String topic, dynamic parameters) async {
    final pRequest = _pendingRequest(topic, TronSupportedMethods.tronSignMessage.name);
    if (pRequest == null) {
      return;
    }

    final params = _paramsOf(parameters);
    final message = params?["message"];
    if (params == null || message is! String) {
      await _respondMalformedRequest(topic, pRequest.id);
      return;
    }

    if (!_isRequestAuthorized(topic, requestAddress: params["address"]?.toString())) {
      await _rejectUnauthorizedRequest(topic, pRequest.id);
      return;
    }

    var response = JsonRpcResponse(id: pRequest.id, jsonrpc: "2.0");

    final isApproved = await MethodsUtils.requestApproval(
      message,
      method: pRequest.method,
      chainId: pRequest.chainId,
      address: _walletAddress(),
      topic: topic,
      transportType: pRequest.transportType.name,
      verifyContext: pRequest.verifyContext,
    );

    if (isApproved && !_isRequestAuthorized(topic, requestAddress: params["address"]?.toString())) {
      await _rejectUnauthorizedRequest(topic, pRequest.id);
      return;
    }

    if (isApproved) {
      try {
        final signature = _tronPrivateKey().signPersonalMessage(utf8.encode(message));

        response = response.copyWith(result: {"signature": "0x$signature"});
      } catch (e) {
        printV("tronSignMessage: signing failed (${e.runtimeType})");
        response = response.copyWith(error: _malformedRequestError());
      }
    } else {
      response = response.copyWith(error: _userRejectedError());
    }

    await _handleResponseForTopic(topic, response);
  }

  Future<void> tronSignTransaction(String topic, dynamic parameters) async {
    final pRequest = _pendingRequest(topic, TronSupportedMethods.tronSignTransaction.name);
    if (pRequest == null) {
      return;
    }

    final params = _paramsOf(parameters);
    final transaction = _transactionOf(params);
    if (params == null || transaction == null) {
      await _respondMalformedRequest(topic, pRequest.id);
      return;
    }

    if (!_isRequestAuthorized(topic, requestAddress: params["address"]?.toString())) {
      await _rejectUnauthorizedRequest(topic, pRequest.id);
      return;
    }

    final TransactionRaw rawTransaction;
    final TronTransactionSummary summary;
    try {
      rawTransaction = _parseRawTransaction(transaction);
      summary = TronTransactionSummary.of(rawTransaction, _walletTokensByContract());
    } catch (e, s) {
      printV("tronSignTransaction could not decode the transaction: $e\n$s");
      await _respondMalformedRequest(topic, pRequest.id);
      return;
    }

    printV("tronSignTransaction request for ${rawTransaction.txID}");

    final ownerAddress = summary.ownerAddress;
    if (ownerAddress == null) {
      await _respondMalformedRequest(topic, pRequest.id);
      return;
    }

    if (!_isRequestAuthorized(topic, requestAddress: ownerAddress)) {
      await _rejectUnauthorizedRequest(topic, pRequest.id);
      return;
    }

    var response = JsonRpcResponse(id: pRequest.id, jsonrpc: "2.0");

    final isApproved = await MethodsUtils.requestApproval(
      summary.text,
      method: pRequest.method,
      chainId: pRequest.chainId,
      address: _walletAddress(),
      topic: topic,
      transportType: pRequest.transportType.name,
      verifyContext: pRequest.verifyContext,
      extraModels: summary.rows,
    );

    if (isApproved && !_isRequestAuthorized(topic, requestAddress: ownerAddress)) {
      await _rejectUnauthorizedRequest(topic, pRequest.id);
      return;
    }

    if (isApproved) {
      try {
        final rawBytes = rawTransaction.toBuffer();
        final signature = BytesUtils.toHexString(_tronPrivateKey().sign(rawBytes));
        final existingSignatures = transaction["signature"];
        final signatures = <String>[
          if (existingSignatures is List) ...existingSignatures.whereType<String>(),
        ];
        if (!signatures.any((existing) => existing.toLowerCase() == signature)) {
          signatures.add(signature);
        }

        response = response.copyWith(
          result: <String, dynamic>{
            if (transaction.containsKey("visible")) "visible": transaction["visible"],
            "txID": rawTransaction.txID,
            if (transaction.containsKey("raw_data")) "raw_data": transaction["raw_data"],
            "raw_data_hex": BytesUtils.toHexString(rawBytes),
            "signature": signatures,
          },
        );
      } catch (e) {
        printV("tronSignTransaction: signing failed (${e.runtimeType})");
        response = response.copyWith(error: _malformedRequestError());
      }
    } else {
      response = response.copyWith(error: _userRejectedError());
    }

    await _handleResponseForTopic(topic, response);
  }

  Map<String, dynamic>? _paramsOf(dynamic parameters) =>
      parameters is Map<String, dynamic> ? parameters : null;

  Map<String, dynamic>? _transactionOf(Map<String, dynamic>? params) {
    final transaction = params?["transaction"];
    if (transaction is! Map<String, dynamic>) {
      return null;
    }

    final nested = transaction["transaction"];
    final hasRawData =
        transaction.containsKey("raw_data") || transaction.containsKey("raw_data_hex");
    if (!hasRawData && nested is Map<String, dynamic>) {
      return nested;
    }

    return transaction;
  }

  TransactionRaw _parseRawTransaction(Map<String, dynamic> transaction) {
    final rawDataHex = transaction["raw_data_hex"];
    final rawBytes =
        rawDataHex is String && rawDataHex.isNotEmpty ? BytesUtils.fromHexString(rawDataHex) : null;
    final rawData = transaction["raw_data"];

    final TransactionRaw rawTransaction;
    if (rawData is Map<String, dynamic>) {
      rawTransaction = _fromTronWebJson(rawData);
    } else if (rawBytes != null) {
      rawTransaction = TransactionRaw.deserialize(rawBytes);
    } else {
      throw ArgumentError("transaction has no raw_data");
    }

    if (rawBytes != null && !BytesUtils.bytesEqual(rawTransaction.toBuffer(), rawBytes)) {
      throw ArgumentError("raw_data and raw_data_hex describe different transactions");
    }

    return rawTransaction;
  }

  TransactionRaw _fromTronWebJson(Map<String, dynamic> rawData) {
    final rawTransaction = TransactionRaw.fromJson(rawData);
    final memo = rawData["data"];
    if (memo is String && memo.isNotEmpty && StringUtils.isHexBytes(memo)) {
      return rawTransaction.copyWith(data: BytesUtils.fromHexString(memo));
    }

    return rawTransaction;
  }

  Map<String, CryptoCurrency> _walletTokensByContract() {
    final wallet = appStore.wallet!;

    return {
      for (final token in tron!.getTronTokenCurrencies(wallet)) tron!.getTokenAddress(token): token,
    };
  }

  TronPrivateKey _tronPrivateKey() {
    final keys = wcKeyService.getKeysForChain(appStore.wallet!);

    return TronPrivateKey(keys.first.privateKey);
  }

  String _walletAddress() => wcKeyService.getKeysForChain(appStore.wallet!).first.publicKey;

  JsonRpcError _malformedRequestError() {
    final error = Errors.getSdkError(Errors.MALFORMED_REQUEST_PARAMS);

    return JsonRpcError(code: error.code, message: error.message);
  }

  JsonRpcError _userRejectedError() {
    final error = Errors.getSdkError(Errors.USER_REJECTED);

    return JsonRpcError(code: error.code, message: error.message);
  }

  Future<void> _respondMalformedRequest(String topic, int requestId) => _handleResponseForTopic(
        topic,
        JsonRpcResponse(
          id: requestId,
          jsonrpc: "2.0",
          error: _malformedRequestError(),
        ),
      );

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

    if (requestAddress != null && _base58Address(requestAddress) != walletAddress) {
      return false;
    }

    return true;
  }

  String? _base58Address(String address) {
    try {
      return TronAddress(address).toAddress();
    } catch (_) {
      return null;
    }
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

  Future<void> _handleResponseForTopic(String topic, JsonRpcResponse<dynamic> response) async {
    final session = walletKit.sessions.get(topic);

    try {
      await walletKit.respondSessionRequest(topic: topic, response: response);

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

      MethodsUtils.handleRedirect(topic, session.peer.metadata.redirect, error.message);
    }
  }
}
