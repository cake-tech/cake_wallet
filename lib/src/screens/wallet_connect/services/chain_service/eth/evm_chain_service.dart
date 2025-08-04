import 'dart:convert';

import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:eth_sig_util/util/utils.dart';
import 'package:flutter/material.dart';
import 'package:reown_walletkit/reown_walletkit.dart';

import 'package:cake_wallet/src/screens/wallet_connect/services/bottom_sheet_service.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/chain_service/eth/evm_chain_id.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/chain_service/eth/evm_supported_methods.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/key_service/wallet_connect_key_service.dart';
import 'package:cake_wallet/src/screens/wallet_connect/models/wc_connection_model.dart';
import 'package:cake_wallet/src/screens/wallet_connect/utils/eth_utils.dart';
import 'package:cake_wallet/src/screens/wallet_connect/utils/method_utils.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;

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
    required this.reference,
    required this.appStore,
    required this.wcKeyService,
    required this.bottomSheetService,
    required this.walletKit,
    Web3Client? web3Client,
  }) : ethClient = web3Client ??
            Web3Client(
              appStore.settingsStore.getCurrentNode(appStore.wallet!.type).uri.toString(),
              ProxyWrapper().getHttpIOClient(),
            ) {
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

  String getChainId() => reference.chain();

  Future<void> personalSign(String topic, dynamic parameters) async {
    debugPrint('personalSign request: $parameters');

    final pRequest = walletKit.pendingRequests.getAll().last;
    final address = EthUtils.getAddressFromSessionRequest(pRequest);
    final data = EthUtils.getDataFromSessionRequest(pRequest);
    final message = EthUtils.getUtf8Message(data.toString());
    var response = JsonRpcResponse(id: pRequest.id, jsonrpc: '2.0');

    final isApproved = await MethodsUtils.requestApproval(
      message,
      method: pRequest.method,
      chainId: pRequest.chainId,
      address: address,
      transportType: pRequest.transportType.name,
      verifyContext: pRequest.verifyContext,
    );

    if (isApproved) {
      try {
        // Load the private key
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

    final pRequest = walletKit.pendingRequests.getAll().last;
    final address = EthUtils.getAddressFromSessionRequest(pRequest);
    final data = EthUtils.getDataFromSessionRequest(pRequest);
    final message = EthUtils.getUtf8Message(data.toString());
    var response = JsonRpcResponse(id: pRequest.id, jsonrpc: '2.0');

    final isApproved = await MethodsUtils.requestApproval(
      message,
      method: pRequest.method,
      chainId: pRequest.chainId,
      address: address,
      transportType: pRequest.transportType.name,
      verifyContext: pRequest.verifyContext,
    );

    if (isApproved) {
      try {
        // Load the private key
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

    final pRequest = walletKit.pendingRequests.getAll().last;
    final address = EthUtils.getAddressFromSessionRequest(pRequest);
    final data = EthUtils.getDataFromSessionRequest(pRequest) as String;
    var response = JsonRpcResponse(id: pRequest.id, jsonrpc: '2.0');

    final isApproved = await MethodsUtils.requestApproval(
      data,
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

    final pRequest = walletKit.pendingRequests.getAll().last;
    final address = EthUtils.getAddressFromSessionRequest(pRequest);
    final data = EthUtils.getDataFromSessionRequest(pRequest) as String;
    var response = JsonRpcResponse(id: pRequest.id, jsonrpc: '2.0');

    final isApproved = await MethodsUtils.requestApproval(
      permitRequestMessage,
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
        // Load the private key
        final keys = wcKeyService.getKeysForChain(appStore.wallet!);
        final credentials = EthPrivateKey.fromHex(keys[0].privateKey);

        final chainId = getChainId().split(':').last;

        final signature = await ethClient.signTransaction(
          credentials,
          transaction,
          chainId: int.parse(chainId),
        );

        // Sign the transaction
        final signedTx = bytesToHex(signature, include0x: true);
        response = response.copyWith(result: signedTx);
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
        // Load the private key
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

    final gasPrice = await ethClient.getGasPrice();
    try {
      final gasLimit = await ethClient.estimateGas(
        sender: transaction.from,
        to: transaction.to,
        value: transaction.value,
        data: transaction.data,
        gasPrice: gasPrice,
      );

      transaction = transaction.copyWith(
        gasPrice: gasPrice,
        maxGas: gasLimit.toInt(),
      );
    } on RPCError catch (e) {
      return JsonRpcError(code: e.errorCode, message: e.message);
    }

    final gweiGasPrice = (transaction.gasPrice?.getInWei ?? BigInt.zero) / BigInt.from(1000000000);

    final amount = (transaction.value?.getInWei ?? BigInt.zero) / BigInt.from(1e18);

    final txMessageText = '${S.current.value}: ${amount.toStringAsFixed(9)} ETH\n'
        '${S.current.from}: ${transaction.from?.hex}\n'
        '${S.current.to}: ${transaction.to?.hex}';

    if (await MethodsUtils.requestApproval(
      txMessageText,
      title: title,
      method: method,
      chainId: chainId,
      address: address,
      transportType: transportType,
      verifyContext: verifyContext,
      extraModels: [
        WCConnectionModel(
          title: S.current.gas_price,
          elements: ['${gweiGasPrice.toStringAsFixed(2)} GWEI'],
        ),
      ],
    )) {
      return transaction;
    }

    return JsonRpcError(code: 5002, message: S.current.user_rejected_method);
  }

  void _onSessionRequest(SessionRequestEvent? args) async {
    if (args != null && args.chainId == getChainId()) {
      debugPrint('_onSessionRequest ${args.toString()}');
      final handler = sessionRequestHandlers[args.method];
      if (handler != null) {
        await handler(args.topic, args.params);
      }
    }
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
      final types = typedData['types']  as Map<String, dynamic>? ?? {};
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

      if (value == null) continue;

      if (types.containsKey(fieldType)) {
        // Handle nested types
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
    if (input.isEmpty) return input;
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
