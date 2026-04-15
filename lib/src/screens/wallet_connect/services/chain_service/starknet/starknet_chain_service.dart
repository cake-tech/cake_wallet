import 'dart:convert';

import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/main.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/starknet/starknet.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/bottom_sheet_service.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/chain_service/starknet/starknet_chain_id.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/chain_service/starknet/starknet_supported_methods.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/key_service/wallet_connect_key_service.dart';
import 'package:cake_wallet/src/screens/wallet_connect/utils/method_utils.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cw_starknet/starknet_client.dart';
import 'package:flutter/material.dart';
import 'package:reown_walletkit/reown_walletkit.dart';

class StarknetChainService {
  StarknetChainService({
    required this.appStore,
    required this.bottomSheetService,
    required this.walletKit,
    required this.wcKeyService,
    required this.reference,
    Future<bool> Function({
      required String text,
      String? title,
      String? method,
      String? chainId,
      String? address,
      required String transportType,
      VerifyContext? verifyContext,
    })? approvalRequester,
    Future<dynamic> Function(Map<String, String> requestUr)?
        urRoundTripRequester,
    Object? Function()? pendingRequestProvider,
    Future<void> Function(String topic, JsonRpcResponse<dynamic> response)?
        responseSender,
    Object? Function(String topic)? sessionProvider,
    bool registerHandlers = true,
  }) {
    _approvalRequester = approvalRequester;
    _urRoundTripRequester = urRoundTripRequester;
    _pendingRequestProvider = pendingRequestProvider;
    _responseSender = responseSender;
    _sessionProvider = sessionProvider;

    if (registerHandlers) {
      for (final handler in requestHandlers.entries) {
        walletKit.registerRequestHandler(
          chainId: getChainId(),
          method: handler.key,
          handler: handler.value,
        );
      }
    }
  }

  final AppStore appStore;
  final BottomSheetService bottomSheetService;
  final ReownWalletKit walletKit;
  final WalletConnectKeyService wcKeyService;
  final StarknetChainId reference;
  late final Future<bool> Function({
    required String text,
    String? title,
    String? method,
    String? chainId,
    String? address,
    required String transportType,
    VerifyContext? verifyContext,
  })? _approvalRequester;
  late final Future<dynamic> Function(Map<String, String> requestUr)?
      _urRoundTripRequester;
  late final Object? Function()? _pendingRequestProvider;
  late final Future<void> Function(
      String topic, JsonRpcResponse<dynamic> response)? _responseSender;
  late final Object? Function(String topic)? _sessionProvider;

  Map<String, dynamic Function(String, dynamic)> get requestHandlers => {
        StarknetSupportedMethods.signTypedData.name: starknetSignTypedData,
        StarknetSupportedMethods.requestAddInvokeTransaction.name:
            starknetRequestAddInvokeTransaction,
      };

  String getChainId() => reference.chain();

  Future<void> starknetSignTypedData(String topic, dynamic parameters) async {
    debugPrint('starknetSignTypedData request: $parameters');

    final pRequest = _currentPendingRequest();
    var response = JsonRpcResponse(id: pRequest.id, jsonrpc: '2.0');

    try {
      final parsed = _parseTypedDataRequest(parameters);
      final walletAddress =
          wcKeyService.getKeysForChain(appStore.wallet!).first.publicKey;
      if (parsed.accountAddress.toLowerCase() != walletAddress.toLowerCase()) {
        throw Exception('WalletConnect requested an unknown Starknet account');
      }

      final prettyMessage =
          const JsonEncoder.withIndent('  ').convert(parsed.typedData);
      final isApproved = await _requestApproval(
        text: prettyMessage,
        method: pRequest.method,
        chainId: pRequest.chainId,
        address: parsed.accountAddress,
        transportType: pRequest.transportType,
        verifyContext: pRequest.verifyContext,
      );

      if (!isApproved) {
        final error = Errors.getSdkError(Errors.USER_REJECTED);
        response = response.copyWith(
          error: JsonRpcError(code: error.code, message: error.message),
        );
      } else {
        final wallet = appStore.wallet!;
        final signature = starknet!.supportsOfflineUrSigning(wallet)
            ? await _roundTripListUr(
                await starknet!.buildTypedDataSignUr(
                  wallet,
                  jsonEncode(parsed.typedData),
                  address: parsed.accountAddress,
                ),
              )
            : await starknet!.signTypedData(
                wallet,
                jsonEncode(parsed.typedData),
                address: parsed.accountAddress,
              );
        response = response.copyWith(result: {'signature': signature});
      }
    } catch (e) {
      debugPrint('starknetSignTypedData error $e');
      final error = Errors.getSdkError(Errors.MALFORMED_REQUEST_PARAMS);
      response = response.copyWith(
        error: JsonRpcError(code: error.code, message: '$e'),
      );
    }

    _handleResponseForTopic(topic, response);
  }

  Future<void> starknetRequestAddInvokeTransaction(
      String topic, dynamic parameters) async {
    debugPrint('starknetRequestAddInvokeTransaction request: $parameters');

    final pRequest = _currentPendingRequest();
    var response = JsonRpcResponse(id: pRequest.id, jsonrpc: '2.0');

    try {
      final parsed = _parseInvokeRequest(parameters);
      final walletAddress =
          wcKeyService.getKeysForChain(appStore.wallet!).first.publicKey;
      if (parsed.accountAddress.toLowerCase() != walletAddress.toLowerCase()) {
        throw Exception('WalletConnect requested an unknown Starknet account');
      }

      final prettyMessage =
          const JsonEncoder.withIndent('  ').convert(parsed.executionRequest);
      final isApproved = await _requestApproval(
        text: prettyMessage,
        title: _approvalRequester == null ? S.current.approve_request : null,
        method: pRequest.method,
        chainId: pRequest.chainId,
        address: parsed.accountAddress,
        transportType: pRequest.transportType,
        verifyContext: pRequest.verifyContext,
      );

      if (!isApproved) {
        final error = Errors.getSdkError(Errors.USER_REJECTED);
        response = response.copyWith(
          error: JsonRpcError(code: error.code, message: error.message),
        );
      } else {
        final wallet = appStore.wallet!;
        final txHash = starknet!.supportsOfflineUrSigning(wallet)
            ? await _roundTripStringUr(
                await starknet!.buildExecutionUr(
                  wallet,
                  parsed.calls,
                ),
              )
            : await starknet!.executeWalletConnectCalls(
                wallet,
                parsed.calls,
              );
        response = response.copyWith(result: {'transaction_hash': txHash});
      }
    } catch (e) {
      debugPrint('starknetRequestAddInvokeTransaction error $e');
      final error = Errors.getSdkError(Errors.MALFORMED_REQUEST_PARAMS);
      response = response.copyWith(
        error: JsonRpcError(code: error.code, message: '$e'),
      );
    }

    _handleResponseForTopic(topic, response);
  }

  _TypedDataRequest _parseTypedDataRequest(dynamic parameters) {
    if (parameters is List && parameters.length >= 2) {
      return _TypedDataRequest(
        accountAddress: parameters[0].toString(),
        typedData: parameters[1] as Map<String, dynamic>,
      );
    }

    if (parameters is Map<String, dynamic>) {
      return _TypedDataRequest(
        accountAddress: parameters['accountAddress']?.toString() ??
            parameters['account']?.toString() ??
            '',
        typedData: Map<String, dynamic>.from(parameters['typedData'] as Map),
      );
    }

    throw Exception('Unsupported Starknet typed data request');
  }

  _InvokeRequest _parseInvokeRequest(dynamic parameters) {
    final payload = switch (parameters) {
      Map<String, dynamic>() => parameters,
      List<dynamic>() when parameters.isNotEmpty =>
        Map<String, dynamic>.from(parameters.first as Map),
      _ => throw Exception('Unsupported Starknet invoke request'),
    };

    final accountAddress = payload['accountAddress']?.toString() ??
        payload['account']?.toString() ??
        '';
    final executionRequest = Map<String, dynamic>.from(
        payload['executionRequest'] as Map? ?? payload);
    final rawCalls = (executionRequest['calls'] as List<dynamic>? ?? const []);

    final calls = rawCalls.map(
      (dynamic rawCall) {
        final call = Map<String, dynamic>.from(rawCall as Map);
        return StarknetExecutionCall(
          contractAddressHex: call['contractAddress']?.toString() ?? '',
          entrypoint: call['entrypoint']?.toString() ?? '',
          calldataHex: (call['calldata'] as List<dynamic>? ?? const [])
              .map((value) => value.toString())
              .toList(),
        );
      },
    ).toList();

    return _InvokeRequest(
      accountAddress: accountAddress,
      executionRequest: executionRequest,
      calls: calls,
    );
  }

  void _handleResponseForTopic(
      String topic, JsonRpcResponse<dynamic> response) async {
    final session = _sessionProvider != null
        ? _sessionProvider(topic)
        : walletKit.sessions.get(topic);
    final redirect = _sessionRedirect(session);

    try {
      if (_responseSender != null) {
        await _responseSender(topic, response);
      } else {
        await walletKit.respondSessionRequest(
          topic: topic,
          response: response,
        );
      }

      if (session == null) return;

      MethodsUtils.handleRedirect(
        topic,
        redirect,
        response.error?.message,
        response.error == null,
      );
    } on ReownSignError catch (error) {
      if (session == null) return;

      MethodsUtils.handleRedirect(
        topic,
        redirect,
        error.message,
      );
    }
  }

  Future<String> _roundTripStringUr(Map<String, String> requestUr) async {
    if (_urRoundTripRequester != null) {
      final result = await _urRoundTripRequester(requestUr);
      if (result is String) {
        return result;
      }
      throw Exception('Unexpected Starknet UR result: ${result.runtimeType}');
    }

    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      throw Exception('Navigator is not available for Starknet UR flow');
    }

    final result = await navigator.pushNamed(
      Routes.urqrAnimatedPage,
      arguments: requestUr,
    );

    if (result == null) {
      throw Exception('Canceled by user');
    }

    if (result is String) {
      return result;
    }

    throw Exception('Unexpected Starknet UR result: ${result.runtimeType}');
  }

  Future<List<String>> _roundTripListUr(Map<String, String> requestUr) async {
    if (_urRoundTripRequester != null) {
      final result = await _urRoundTripRequester(requestUr);
      if (result is List<dynamic>) {
        return result.map((item) => item.toString()).toList();
      }
      throw Exception('Unexpected Starknet UR result: ${result.runtimeType}');
    }

    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      throw Exception('Navigator is not available for Starknet UR flow');
    }

    final result = await navigator.pushNamed(
      Routes.urqrAnimatedPage,
      arguments: requestUr,
    );

    if (result == null) {
      throw Exception('Canceled by user');
    }

    if (result is List<dynamic>) {
      return result.map((item) => item.toString()).toList();
    }

    throw Exception('Unexpected Starknet UR result: ${result.runtimeType}');
  }

  Future<bool> _requestApproval({
    required String text,
    String? title,
    String? method,
    String? chainId,
    String? address,
    required String transportType,
    VerifyContext? verifyContext,
  }) {
    if (_approvalRequester != null) {
      return _approvalRequester(
        text: text,
        title: title,
        method: method,
        chainId: chainId,
        address: address,
        transportType: transportType,
        verifyContext: verifyContext,
      );
    }

    return MethodsUtils.requestApproval(
      text,
      title: title,
      method: method,
      chainId: chainId,
      address: address,
      transportType: transportType,
      verifyContext: verifyContext,
    );
  }

  _PendingRequestView _currentPendingRequest() => _PendingRequestView.from(
        _pendingRequestProvider?.call() ??
            walletKit.pendingRequests.getAll().last,
      );

  Redirect? _sessionRedirect(Object? session) {
    if (session == null) {
      return null;
    }

    final dynamic dynamicSession = session;
    return dynamicSession.peer?.metadata?.redirect as Redirect?;
  }
}

class _TypedDataRequest {
  const _TypedDataRequest({
    required this.accountAddress,
    required this.typedData,
  });

  final String accountAddress;
  final Map<String, dynamic> typedData;
}

class _InvokeRequest {
  const _InvokeRequest({
    required this.accountAddress,
    required this.executionRequest,
    required this.calls,
  });

  final String accountAddress;
  final Map<String, dynamic> executionRequest;
  final List<StarknetExecutionCall> calls;
}

class _PendingRequestView {
  const _PendingRequestView({
    required this.id,
    required this.method,
    required this.chainId,
    required this.transportType,
    required this.verifyContext,
  });

  factory _PendingRequestView.from(Object? pendingRequest) {
    final dynamic request = pendingRequest;
    final dynamic transportType = request.transportType;

    return _PendingRequestView(
      id: request.id is int
          ? request.id as int
          : int.parse(request.id.toString()),
      method: request.method?.toString(),
      chainId: request.chainId?.toString(),
      transportType: transportType?.name?.toString() ?? '',
      verifyContext: request.verifyContext as VerifyContext?,
    );
  }

  final int id;
  final String? method;
  final String? chainId;
  final String transportType;
  final VerifyContext? verifyContext;
}
