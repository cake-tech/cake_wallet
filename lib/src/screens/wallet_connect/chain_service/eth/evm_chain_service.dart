// import 'dart:convert';
// import 'dart:typed_data';

// import 'package:cake_wallet/core/wallet_connect/eth_transaction_model.dart';
// import 'package:cake_wallet/core/wallet_connect/chain_service/eth/evm_chain_id.dart';
// import 'package:cake_wallet/core/wallet_connect/wc_bottom_sheet_service.dart';
// import 'package:cake_wallet/generated/i18n.dart';
// import 'package:cake_wallet/reactions/wallet_connect.dart';
// import 'package:cake_wallet/src/screens/wallet_connect/widgets/message_display_widget.dart';
// import 'package:cake_wallet/store/app_store.dart';
// import 'package:cake_wallet/core/wallet_connect/models/chain_key_model.dart';
// import 'package:cake_wallet/core/wallet_connect/models/connection_model.dart';
// import 'package:cake_wallet/src/screens/wallet_connect/widgets/connection_widget.dart';
// import 'package:cake_wallet/src/screens/wallet_connect/widgets/modals/web3_request_modal.dart';
// import 'package:cake_wallet/src/screens/wallet_connect/utils/string_parsing.dart';
// import 'package:convert/convert.dart';
// import 'package:eth_sig_util/eth_sig_util.dart';
// import 'package:eth_sig_util/util/utils.dart' as eth_sig_utils;
// import 'package:http/http.dart' as http;
// import 'package:reownwalletkit/reownwalletkit.dart';
// import '../chain_service.dart';
// import '../../wallet_connect_key_service.dart';

// class EvmChainServiceImpl implements ChainService {
//   final AppStore appStore;
//   final BottomSheetService bottomSheetService;
//   final ReownWalletKit wallet;
//   final WalletConnectKeyService wcKeyService;

//   static const namespace = 'eip155';
//   static const pSign = 'personal_sign';
//   static const eSign = 'eth_sign';
//   static const eSignTransaction = 'eth_signTransaction';
//   static const eSignTypedData = 'eth_signTypedData_v4';
//   static const eSendTransaction = 'eth_sendTransaction';

//   final EVMChainId reference;

//   final Web3Client ethClient;

//   EvmChainServiceImpl({
//     required this.reference,
//     required this.appStore,
//     required this.wcKeyService,
//     required this.bottomSheetService,
//     required this.wallet,
//     Web3Client? web3Client,
//   }) : ethClient = web3Client ??
//             Web3Client(
//               appStore.settingsStore.getCurrentNode(appStore.wallet!.type).uri.toString(),
//               http.Client(),
//             ) {
//     for (final String event in getEvents()) {
//       wallet.registerEventEmitter(chainId: getChainId(), event: event);
//     }
//     wallet.registerRequestHandler(
//       chainId: getChainId(),
//       method: pSign,
//       handler: personalSign,
//     );
//     wallet.registerRequestHandler(
//       chainId: getChainId(),
//       method: eSign,
//       handler: ethSign,
//     );
//     wallet.registerRequestHandler(
//       chainId: getChainId(),
//       method: eSignTransaction,
//       handler: ethSignTransaction,
//     );
//     wallet.registerRequestHandler(
//       chainId: getChainId(),
//       method: eSendTransaction,
//       handler: ethSignTransaction,
//     );
//     wallet.registerRequestHandler(
//       chainId: getChainId(),
//       method: eSignTypedData,
//       handler: ethSignTypedData,
//     );
//   }

//   @override
//   String getNamespace() {
//     return namespace;
//   }

//   @override
//   String getChainId() {
//     return reference.chain();
//   }

//   @override
//   List<String> getEvents() {
//     return ['chainChanged', 'accountsChanged'];
//   }

//   Future<String?> requestAuthorization(String? text) async {
//     // Show the bottom sheet
//     final bool? isApproved = await bottomSheetService.queueBottomSheet(
//       widget: Web3RequestModal(
//         child: ConnectionWidget(
//           title: S.current.signTransaction,
//           info: [
//             ConnectionModel(
//               text: text,
//             ),
//           ],
//         ),
//       ),
//     ) as bool?;

//     if (isApproved != null && isApproved == false) {
//       return 'User rejected signature';
//     }

//     return null;
//   }

//   Future<String> personalSign(String topic, dynamic parameters) async {
//     log('received personal sign request: $parameters');

//     final String message;
//     if (parameters[0] == null) {
//       message = '';
//     } else {
//       message = parameters[0].toString().utf8Message;
//     }

//     final String? authError = await requestAuthorization(message);

//     if (authError != null) {
//       return authError;
//     }

//     try {
//       // Load the private key
//       final List<ChainKeyModel> keys = wcKeyService.getKeysForChain(appStore.wallet!);

//       final Credentials credentials = EthPrivateKey.fromHex(keys[0].privateKey);

//       final String signature = hex.encode(
//         credentials.signPersonalMessageToUint8List(Uint8List.fromList(utf8.encode(message))),
//       );

//       return '0x$signature';
//     } catch (e) {
//       log(e.toString());
//       bottomSheetService.queueBottomSheet(
//         isModalDismissible: true,
//         widget: BottomSheetMessageDisplayWidget(
//           message: '${S.current.errorGettingCredentials} ${e.toString()}',
//         ),
//       );
//       return 'Failed: Error while getting credentials';
//     }
//   }

//   Future<String> ethSign(String topic, dynamic parameters) async {
//     log('received eth sign request: $parameters');

//     final String message;
//     if (parameters[1] == null) {
//       message = '';
//     } else {
//       message = parameters[1].toString().utf8Message;
//     }

//     final String? authError = await requestAuthorization(message);
//     if (authError != null) {
//       return authError;
//     }

//     try {
//       // Load the private key
//       final List<ChainKeyModel> keys = wcKeyService.getKeysForChain(appStore.wallet!);

//       final EthPrivateKey credentials = EthPrivateKey.fromHex(keys[0].privateKey);

//       final String signature = hex.encode(
//         credentials.signPersonalMessageToUint8List(
//           Uint8List.fromList(utf8.encode(message)),
//           chainId: getChainIdBasedOnWalletType(appStore.wallet!.type),
//         ),
//       );
//       log(signature);

//       return '0x$signature';
//     } catch (e) {
//       log('error: ${e.toString()}');
//       bottomSheetService.queueBottomSheet(
//         isModalDismissible: true,
//         widget: BottomSheetMessageDisplayWidget(message: '${S.current.error}: ${e.toString()}'),
//       );
//       return 'Failed';
//     }
//   }

//   Future<String> ethSignTransaction(String topic, dynamic parameters) async {
//     log('received eth sign transaction request: $parameters');

//     final paramsData = parameters[0] as Map<String, dynamic>;

//     final message = _convertToReadable(paramsData);

//     final String? authError = await requestAuthorization(message);

//     if (authError != null) {
//       return authError;
//     }

//     // Load the private key
//     final List<ChainKeyModel> keys = wcKeyService.getKeysForChain(appStore.wallet!);

//     final Credentials credentials = EthPrivateKey.fromHex(keys[0].privateKey);

//     WCEthereumTransactionModel ethTransaction =
//         WCEthereumTransactionModel.fromJson(parameters[0] as Map<String, dynamic>);

//     final transaction = Transaction(
//       from: EthereumAddress.fromHex(ethTransaction.from),
//       to: EthereumAddress.fromHex(ethTransaction.to),
//       maxGas: ethTransaction.gasLimit != null ? int.tryParse(ethTransaction.gasLimit ?? "") : null,
//       gasPrice: ethTransaction.gasPrice != null
//           ? EtherAmount.inWei(BigInt.parse(ethTransaction.gasPrice ?? ""))
//           : null,
//       value: EtherAmount.inWei(BigInt.parse(ethTransaction.value)),
//       data: eth_sig_utils.hexToBytes(ethTransaction.data ?? ""),
//       nonce: ethTransaction.nonce != null ? int.tryParse(ethTransaction.nonce ?? "") : null,
//     );

//     try {
//       final result = await ethClient.sendTransaction(
//         credentials,
//         transaction,
//         chainId: getChainIdBasedOnWalletType(appStore.wallet!.type),
//       );

//       log('Result: $result');

//       bottomSheetService.queueBottomSheet(
//         isModalDismissible: true,
//         widget: BottomSheetMessageDisplayWidget(
//           message: S.current.awaitDAppProcessing,
//           isError: false,
//         ),
//       );

//       return result;
//     } catch (e) {
//       log('An error has occurred while signing transaction: ${e.toString()}');
//       bottomSheetService.queueBottomSheet(
//         isModalDismissible: true,
//         widget: BottomSheetMessageDisplayWidget(
//           message: '${S.current.errorSigningTransaction}: ${e.toString()}',
//         ),
//       );
//       return 'Failed';
//     }
//   }

//   Future<String> ethSignTypedData(String topic, dynamic parameters) async {
//     log('received eth sign typed data request: $parameters');
//     final String? data = parameters[1] as String?;

//     final String? authError = await requestAuthorization(data);

//     if (authError != null) {
//       return authError;
//     }

//     final List<ChainKeyModel> keys = wcKeyService.getKeysForChain(appStore.wallet!);

//     return EthSigUtil.signTypedData(
//       privateKey: keys[0].privateKey,
//       jsonData: data ?? '',
//       version: TypedDataVersion.V4,
//     );
//   }

//   String _convertToReadable(Map<String, dynamic> data) {
//     final tokenName = getTokenNameBasedOnWalletType(appStore.wallet!.type);
//     String gas = int.parse((data['gas'] as String).substring(2), radix: 16).toString();
//     String value = data['value'] != null
//         ? (int.parse((data['value'] as String).substring(2), radix: 16) / 1e18).toString() +
//             ' $tokenName'
//         : '0 $tokenName';
//     String from = data['from'] as String;
//     String to = data['to'] as String;

//     return '''
//  Gas: $gas\n
//  Value: $value\n
//  From: $from\n
//  To: $to
//              ''';
//   }
// }

import 'dart:convert';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/src/screens/wallet_connect/bottom_sheet/wc_bottom_sheet_service.dart';
import 'package:cake_wallet/src/screens/wallet_connect/chain_service/eth/evm_chain_id.dart';
import 'package:cake_wallet/src/screens/wallet_connect/chain_service/eth/evm_supported_methods.dart';
import 'package:cake_wallet/src/screens/wallet_connect/key_service/chain_key_model.dart';
import 'package:cake_wallet/src/screens/wallet_connect/key_service/wallet_connect_key_service.dart';
import 'package:cake_wallet/src/screens/wallet_connect/models/connection_model.dart';
import 'package:cake_wallet/src/screens/wallet_connect/utils/eth_utils.dart';
import 'package:cake_wallet/src/screens/wallet_connect/utils/method_utils.dart';
import 'package:cake_wallet/src/screens/wallet_connect/utils/namespace_model_builder.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:eth_sig_util/util/utils.dart';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:reown_walletkit/reown_walletkit.dart';

class EvmChainServiceImpl {
  Map<String, dynamic Function(String, dynamic)> get sessionRequestHandlers => {
        EVMSupportedMethods.ethSign.name: ethSign,
        EVMSupportedMethods.ethSignTransaction.name: ethSignTransaction,
        EVMSupportedMethods.ethSignTypedData.name: ethSignTypedData,
        EVMSupportedMethods.ethSignTypedDataV4.name: ethSignTypedDataV4,
        EVMSupportedMethods.switchChain.name: switchChain,
        EVMSupportedMethods.addChain.name: addChain,
      };

  Map<String, dynamic Function(String, dynamic)> get methodRequestHandlers => {
        EVMSupportedMethods.personalSign.name: personalSign,
        EVMSupportedMethods.ethSendTransaction.name: ethSendTransaction,
      };

  final AppStore appStore;
  final EVMChainId reference;
  final Web3Client ethClient;
  final ReownWalletKit walletKit;
  final WalletConnectKeyService wcKeyService;
  final BottomSheetService bottomSheetService;

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
              http.Client(),
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

  String getChainId() => reference.chain();

  // personal_sign is handled using onSessionRequest event for demo purposes
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
          error: JsonRpcError(
            code: error.code,
            message: error.message,
          ),
        );
      }
    } else {
      final error = Errors.getSdkError(Errors.USER_REJECTED);
      response = response.copyWith(
        error: JsonRpcError(
          code: error.code,
          message: error.message,
        ),
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
          error: JsonRpcError(
            code: error.code,
            message: error.message,
          ),
        );
      }
    } else {
      final error = Errors.getSdkError(Errors.USER_REJECTED).toSignError();
      response = response.copyWith(
        error: JsonRpcError(
          code: error.code,
          message: error.message,
        ),
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
          error: JsonRpcError(
            code: error.code,
            message: error.message,
          ),
        );
      }
    } else {
      final error = Errors.getSdkError(Errors.USER_REJECTED).toSignError();
      response = response.copyWith(
        error: JsonRpcError(
          code: error.code,
          message: error.message,
        ),
      );
    }

    _handleResponseForTopic(topic, response);
  }

  Future<void> ethSignTypedDataV4(String topic, dynamic parameters) async {
    debugPrint('ethSignTypedDataV4 request: $parameters');

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
        debugPrint('ethSignTypedDataV4 error $e');
        final error = Errors.getSdkError(Errors.MALFORMED_REQUEST_PARAMS);
        response = response.copyWith(
          error: JsonRpcError(
            code: error.code,
            message: error.message,
          ),
        );
      }
    } else {
      response = response.copyWith(
        error: const JsonRpcError(code: 5002, message: 'User rejected method'),
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
          error: JsonRpcError(
            code: e.errorCode,
            message: e.message,
          ),
        );
      } catch (e) {
        debugPrint('ethSignTransaction error $e');
        final error = Errors.getSdkError(Errors.MALFORMED_REQUEST_PARAMS);
        response = response.copyWith(
          error: JsonRpcError(
            code: error.code,
            message: error.message,
          ),
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

    var response = JsonRpcResponse(
      id: pRequest.id,
      jsonrpc: '2.0',
    );

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
          error: JsonRpcError(
            code: e.errorCode,
            message: e.message,
          ),
        );
      } catch (e) {
        debugPrint('ethSendTransaction error $e');
        final error = Errors.getSdkError(Errors.MALFORMED_REQUEST_PARAMS);
        response = response.copyWith(
          error: JsonRpcError(
            code: error.code,
            message: error.message,
          ),
        );
      }
    } else {
      response = response.copyWith(error: transaction as JsonRpcError);
    }

    _handleResponseForTopic(topic, response);
  }

  Future<void> switchChain(String topic, dynamic parameters) async {
    debugPrint('switchChain request: $topic $parameters');
    final pRequest = walletKit.pendingRequests.getAll().last;
    var response = JsonRpcResponse(id: pRequest.id, jsonrpc: '2.0');
    try {
      final params = (parameters as List).first as Map<String, dynamic>;
      final hexChainId = params['chainId'].toString().replaceFirst('0x', '');
      final chainId = int.parse(hexChainId, radix: 16);

      final keys = wcKeyService.getKeysForChain(appStore.wallet!);

      final chainInfo = keys.firstWhere(
        (e) {
          return e.chains.any((chainData) => chainData == 'eip155:$chainId');
        },
      );

      // this change will handle the session event emit, see settings_page
      // getIt<IWalletKitService>().currentSelectedChain.value = chainInfo;

      response = response.copyWith(result: true);
    } on ReownSignError catch (e) {
      debugPrint('switchChain error $e');
      response = response.copyWith(
        error: JsonRpcError(
          code: e.code,
          message: e.message,
        ),
      );
    } catch (e) {
      debugPrint('switchChain error $e');
      final error = Errors.getSdkError(Errors.MALFORMED_REQUEST_PARAMS);
      response = response.copyWith(
        error: JsonRpcError(
          code: error.code,
          message: error.message,
        ),
      );
    }

    _handleResponseForTopic(topic, response);
  }

  Future<void> addChain(String topic, dynamic parameters) async {
    debugPrint('addChain request: $topic $parameters');
    final pRequest = walletKit.pendingRequests.getAll().last;
    var response = JsonRpcResponse(
      id: pRequest.id,
      jsonrpc: '2.0',
    );

    if (await MethodsUtils.requestApproval(
      jsonEncode(parameters),
      method: pRequest.method,
      chainId: pRequest.chainId,
      transportType: pRequest.transportType.name,
      verifyContext: pRequest.verifyContext,
    )) {
      try {
        final params = (parameters as List).first as Map<String, dynamic>;
        final hexChainId = params['chainId'].toString().replaceFirst('0x', '');
        final decimalChainId = int.parse(hexChainId, radix: 16);
        final chainId = 'eip155:$decimalChainId';

        final keys = wcKeyService.getKeysForChain(appStore.wallet!);

        ChainKeyModel eipChainModel = keys.firstWhere((key) => key.namespace == 'eip155');

        // final chainData = ChainMetadata(
        //   type: ChainType.eip155,
        //   chainId: chainId,
        //   name: params['chainName'] as String,
        //   logo: '/chain-logos/eip155-$decimalChainId.png',
        //   color: Colors.blue.shade300,
        //   rpc: (params['rpcUrls'] as List).map((e) => e.toString()).toList(),
        // );

        // Register the corresponding singleton for the new chain
        // This will also call registerEventEmitter and registerRequestHandler
        getIt.registerSingleton<EvmChainServiceImpl>(
          EvmChainServiceImpl(
            reference: reference,
            appStore: appStore,
            wcKeyService: wcKeyService,
            bottomSheetService: bottomSheetService,
            walletKit: walletKit,
            // chainSupported: chainData,
          ),
          instanceName: chainId,
        );

        // register the new account
        final chainKeys = wcKeyService.getKeysForChain(appStore.wallet!);
        final address = chainKeys.first.publicKey;
        walletKit.registerAccount(chainId: chainId, accountAddress: address);

        // update session's namespaces
        final currentSession = walletKit.sessions.get(topic)!;
        final namespaces = ConnectionWidgetBuilder.updateNamespaces(
          currentSession.namespaces,
          'eip155',
          [chainId],
        );
        await walletKit.updateSession(topic: topic, namespaces: namespaces);

        // add the new chain to the list
        // ChainsDataList.eip155Chains.add(chainData);
        eipChainModel.chains.add(chainId);

        // this change will handle the session event emit, see settings_page
        // getIt<IWalletKitService>().currentSelectedChain.value = chainData;

        response = response.copyWith(result: true);
      } on ReownSignError catch (e) {
        debugPrint('addChain error $e');
        response = response.copyWith(
          error: JsonRpcError(
            code: e.code,
            message: e.message,
          ),
        );
      } catch (e) {
        debugPrint('addChain error $e');
        final error = Errors.getSdkError(Errors.MALFORMED_REQUEST_PARAMS);
        response = response.copyWith(
          error: JsonRpcError(
            code: error.code,
            message: error.message,
          ),
        );
      }
    } else {
      final error = Errors.getSdkError(Errors.USER_REJECTED);
      response = response.copyWith(
        error: JsonRpcError(
          code: error.code,
          message: error.message,
        ),
      );
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
      MethodsUtils.handleRedirect(
        topic,
        session!.peer.metadata.redirect,
        response.error?.message,
        response.error == null,
      );
    } on ReownSignError catch (error) {
      MethodsUtils.handleRedirect(
        topic,
        session!.peer.metadata.redirect,
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

    const encoder = JsonEncoder.withIndent('  ');
    final trx = encoder.convert(transactionJson);

    if (await MethodsUtils.requestApproval(
      trx,
      title: title,
      method: method,
      chainId: chainId,
      address: address,
      transportType: transportType,
      verifyContext: verifyContext,
      extraModels: [
        WCConnectionModel(
          title: 'Gas price',
          elements: ['${gweiGasPrice.toStringAsFixed(2)} GWEI'],
        ),
      ],
    )) {
      return transaction;
    }

    return const JsonRpcError(code: 5002, message: 'User rejected method');
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

  Future<dynamic> getBalance({required String address}) async {
    final uri = Uri.parse('https://rpc.walletconnect.org/v1');
    final queryParams = {'projectId': walletKit.core.projectId, 'chainId': getChainId()};
    final response = await http.post(
      uri.replace(queryParameters: queryParams),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': 1,
        'jsonrpc': '2.0',
        'method': 'eth_getBalance',
        'params': [address, 'latest'],
      }),
    );
    if (response.statusCode == 200 && response.body.isNotEmpty) {
      try {
        final result = _parseRpcResultAs<String>(response.body);
        final amount = EtherAmount.fromBigInt(
          EtherUnit.wei,
          hexToInt(result),
        );
        return amount.getValueInUnit(EtherUnit.ether);
      } catch (e) {
        throw Exception('Failed to load balance. $e');
      }
    }
    try {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>;
      final reasons = errorData['reasons'] as List<dynamic>;
      final reason = reasons.isNotEmpty ? reasons.first['description'] ?? '' : response.body;
      throw Exception(reason);
    } catch (e) {
      rethrow;
    }
  }

  T _parseRpcResultAs<T>(String body) {
    try {
      final bodyMap = jsonDecode(body) as Map<String, dynamic>;
      final result = Map<String, dynamic>.from({...bodyMap, 'id': 1});
      final jsonResponse = JsonRpcResponse.fromJson(result);
      if (jsonResponse.result != null) {
        return jsonResponse.result as T;
      } else {
        throw jsonResponse.error ?? 'Error parsing result';
      }
    } catch (e) {
      rethrow;
    }
  }
}
