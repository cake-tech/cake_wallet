import 'dart:convert';

import 'package:cake_wallet/generated/i18n.dart';
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
  }) {
    for (final handler in requestHandlers.entries) {
      walletKit.registerRequestHandler(
        chainId: getChainId(),
        method: handler.key,
        handler: handler.value,
      );
    }
  }

  final AppStore appStore;
  final BottomSheetService bottomSheetService;
  final ReownWalletKit walletKit;
  final WalletConnectKeyService wcKeyService;
  final StarknetChainId reference;

  Map<String, dynamic Function(String, dynamic)> get requestHandlers => {
        StarknetSupportedMethods.signTypedData.name: starknetSignTypedData,
        StarknetSupportedMethods.requestAddInvokeTransaction.name:
            starknetRequestAddInvokeTransaction,
      };

  String getChainId() => reference.chain();

  Future<void> starknetSignTypedData(String topic, dynamic parameters) async {
    debugPrint('starknetSignTypedData request: $parameters');

    final pRequest = walletKit.pendingRequests.getAll().last;
    var response = JsonRpcResponse(id: pRequest.id, jsonrpc: '2.0');

    try {
      final parsed = _parseTypedDataRequest(parameters);
      final walletAddress = wcKeyService.getKeysForChain(appStore.wallet!).first.publicKey;
      if (parsed.accountAddress.toLowerCase() != walletAddress.toLowerCase()) {
        throw Exception('WalletConnect requested an unknown Starknet account');
      }

      final prettyMessage = const JsonEncoder.withIndent('  ').convert(parsed.typedData);
      final isApproved = await MethodsUtils.requestApproval(
        prettyMessage,
        method: pRequest.method,
        chainId: pRequest.chainId,
        address: parsed.accountAddress,
        transportType: pRequest.transportType.name,
        verifyContext: pRequest.verifyContext,
      );

      if (!isApproved) {
        final error = Errors.getSdkError(Errors.USER_REJECTED);
        response = response.copyWith(
          error: JsonRpcError(code: error.code, message: error.message),
        );
      } else {
        final signature = await starknet!.signTypedData(
          appStore.wallet!,
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

  Future<void> starknetRequestAddInvokeTransaction(String topic, dynamic parameters) async {
    debugPrint('starknetRequestAddInvokeTransaction request: $parameters');

    final pRequest = walletKit.pendingRequests.getAll().last;
    var response = JsonRpcResponse(id: pRequest.id, jsonrpc: '2.0');

    try {
      final parsed = _parseInvokeRequest(parameters);
      final walletAddress = wcKeyService.getKeysForChain(appStore.wallet!).first.publicKey;
      if (parsed.accountAddress.toLowerCase() != walletAddress.toLowerCase()) {
        throw Exception('WalletConnect requested an unknown Starknet account');
      }

      final prettyMessage =
          const JsonEncoder.withIndent('  ').convert(parsed.executionRequest);
      final isApproved = await MethodsUtils.requestApproval(
        prettyMessage,
        title: S.current.approve_request,
        method: pRequest.method,
        chainId: pRequest.chainId,
        address: parsed.accountAddress,
        transportType: pRequest.transportType.name,
        verifyContext: pRequest.verifyContext,
      );

      if (!isApproved) {
        final error = Errors.getSdkError(Errors.USER_REJECTED);
        response = response.copyWith(
          error: JsonRpcError(code: error.code, message: error.message),
        );
      } else {
        final txHash = await starknet!.executeWalletConnectCalls(
          appStore.wallet!,
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
      List<dynamic>() when parameters.isNotEmpty => Map<String, dynamic>.from(parameters.first as Map),
      _ => throw Exception('Unsupported Starknet invoke request'),
    };

    final accountAddress = payload['accountAddress']?.toString() ??
        payload['account']?.toString() ??
        '';
    final executionRequest =
        Map<String, dynamic>.from(payload['executionRequest'] as Map? ?? payload);
    final rawCalls = (executionRequest['calls'] as List<dynamic>? ?? const []);

    final calls = rawCalls
        .map(
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
        )
        .toList();

    return _InvokeRequest(
      accountAddress: accountAddress,
      executionRequest: executionRequest,
      calls: calls,
    );
  }

  void _handleResponseForTopic(String topic, JsonRpcResponse<dynamic> response) async {
    final session = walletKit.sessions.get(topic);

    try {
      await walletKit.respondSessionRequest(
        topic: topic,
        response: response,
      );

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
