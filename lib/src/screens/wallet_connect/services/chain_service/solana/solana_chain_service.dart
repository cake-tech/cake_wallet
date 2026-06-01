import 'dart:convert';

import 'package:blockchain_utils/base58/base58.dart';
import 'package:blockchain_utils/blockchain_utils.dart' as blockchain_utils;
import 'package:cake_wallet/src/screens/wallet_connect/decoders/solana/solana_request_decoder.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/bottom_sheet_service.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/chain_service/solana/solana_chain_id.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/chain_service/solana/solana_supported_methods.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/key_service/wallet_connect_key_service.dart';
import 'package:cake_wallet/src/screens/wallet_connect/utils/method_utils.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:on_chain/solana/solana.dart';
import 'package:reown_walletkit/reown_walletkit.dart';

class SolanaChainService {
  Map<String, dynamic Function(String, dynamic)> get solanaRequestHandlers => {
        SolanaSupportedMethods.solSignMessage.name: solanaSignMessage,
        SolanaSupportedMethods.solSignTransaction.name: solanaSignTransaction,
        SolanaSupportedMethods.solSignAllTransaction.name: solanaSignAllTransaction,
      };

  SolanaChainService({
    required this.appStore,
    required this.bottomSheetService,
    required this.walletKit,
    required this.wcKeyService,
    required this.reference,
  }) : decoder = SolanaRequestDecoder(appStore) {
    for (var handler in solanaRequestHandlers.entries) {
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
  final SolanaChainId reference;
  final SolanaRequestDecoder decoder;

  String getChainId() => reference.chain();

  Future<void> solanaSignMessage(String topic, dynamic parameters) async {
    printV('solanaSignMessage request: $parameters');

    final pRequest = walletKit.pendingRequests.getAll().last;
    var response = JsonRpcResponse(id: pRequest.id, jsonrpc: '2.0');

    try {
      final params = parameters as Map<String, dynamic>;
      final message = params['message'].toString();
      final privateKey = _getSolanaPrivateKey();

      final decoded = await decoder.decodeSignMessage(message);

      final isApproved = await MethodsUtils.requestApproval(
        decoded,
        method: pRequest.method,
        chainId: pRequest.chainId,
        address: privateKey.publicKey().toAddress().address,
        transportType: pRequest.transportType.name,
        verifyContext: pRequest.verifyContext,
      );

      if (isApproved) {
        final base58Decoded = base58.decode(message);
        final signedBytes = await privateKey.sign(base58Decoded);
        final signature = blockchain_utils.Base58Encoder.encode(signedBytes);
        response = response.copyWith(result: {'signature': signature});
      } else {
        final error = Errors.getSdkError(Errors.USER_REJECTED);
        response = response.copyWith(
          error: JsonRpcError(code: error.code, message: error.message),
        );
      }
    } catch (e) {
      printV('solanaSignMessage error $e');
      final error = Errors.getSdkError(Errors.MALFORMED_REQUEST_PARAMS);
      response = response.copyWith(
        error: JsonRpcError(code: error.code, message: error.message),
      );
    }

    _handleResponseForTopic(topic, response);
  }

  Future<void> solanaSignTransaction(String topic, dynamic parameters) async {
    printV('solanaSignTransaction: ${jsonEncode(parameters)}');

    final pRequest = walletKit.pendingRequests.getAll().last;
    var response = JsonRpcResponse(id: pRequest.id, jsonrpc: '2.0');

    try {
      final params = parameters as Map<String, dynamic>;
      final privateKey = _getSolanaPrivateKey();

      SolanaTransaction unSignedTransaction;
      if (params.containsKey('transaction')) {
        final transaction = params['transaction'] as String;
        final transactionBytes = base64.decode(transaction);
        unSignedTransaction = SolanaTransaction.deserialize(transactionBytes);
      } else {
        final feePayer = params['feePayer'].toString();
        final recentBlockHash = params['recentBlockhash'].toString();
        final instructionsList = params['instructions'] as List<dynamic>;

        final instructions = instructionsList.map((json) {
          return (json as Map<String, dynamic>).toInstruction();
        }).toList();

        unSignedTransaction = SolanaTransaction(
          payerKey: SolAddress(feePayer),
          instructions: instructions,
          recentBlockhash: SolAddress(recentBlockHash),
        );
      }

      final decoded = await decoder.decodeTransaction(params);

      final isApproved = await MethodsUtils.requestApproval(
        decoded,
        method: pRequest.method,
        chainId: pRequest.chainId,
        address: privateKey.publicKey().toAddress().address,
        transportType: pRequest.transportType.name,
        verifyContext: pRequest.verifyContext,
      );

      if (isApproved) {
        final signedTx = await privateKey.sign(unSignedTransaction.serializeMessage());
        final signature = Base58Encoder.encode(signedTx.toList(growable: false));
        response = response.copyWith(result: {'signature': signature});
      } else {
        final error = Errors.getSdkError(Errors.USER_REJECTED);
        response = response.copyWith(
          error: JsonRpcError(code: error.code, message: error.message),
        );
      }
    } catch (e, s) {
      printV('solanaSignTransaction error $e, $s');
      final error = Errors.getSdkError(Errors.MALFORMED_REQUEST_PARAMS);
      response = response.copyWith(
        error: JsonRpcError(code: error.code, message: error.message),
      );
    }

    _handleResponseForTopic(topic, response);
  }

  Future<void> solanaSignAllTransaction(String topic, dynamic parameters) async {
    printV('solanaSignAllTransaction: ${jsonEncode(parameters)}');

    final pRequest = walletKit.pendingRequests.getAll().last;
    var response = JsonRpcResponse(id: pRequest.id, jsonrpc: '2.0');

    try {
      final params = parameters as Map<String, dynamic>;
      final privateKey = _getSolanaPrivateKey();

      final decoded = await decoder.decodeAllTransactions(params);

      final isApproved = await MethodsUtils.requestApproval(
        decoded,
        method: pRequest.method,
        chainId: pRequest.chainId,
        address: privateKey.publicKey().toAddress().address,
        transportType: pRequest.transportType.name,
        verifyContext: pRequest.verifyContext,
      );

      if (isApproved) {
        if (params.containsKey('transactions')) {
          final transactions = params['transactions'] as List<String>;
          final List<String> signedTransactions = [];
          for (var transaction in transactions) {
            final transactionBytes = base64.decode(transaction);
            final unsignedTx = SolanaTransaction.deserialize(transactionBytes);
            final serializedTx = await privateKey.sign(unsignedTx.serializeMessage());
            unsignedTx.addSignature(privateKey.publicKey().toAddress(), serializedTx);
            final reEncodedTx = unsignedTx.serializeString(
              encoding: TransactionSerializeEncoding.base64,
            );
            signedTransactions.add(reEncodedTx);
          }
          response = response.copyWith(result: {'transactions': signedTransactions});
        }
      } else {
        final error = Errors.getSdkError(Errors.USER_REJECTED);
        response = response.copyWith(
          error: JsonRpcError(code: error.code, message: error.message),
        );
      }
    } catch (e, s) {
      printV('solanaSignAllTransactions error $e, $s');
      final error = Errors.getSdkError(Errors.MALFORMED_REQUEST_PARAMS);
      response = response.copyWith(
        error: JsonRpcError(code: error.code, message: error.message),
      );
    }

    _handleResponseForTopic(topic, response);
  }

  SolanaPrivateKey _getSolanaPrivateKey() {
    final keys = wcKeyService.getKeysForChain(appStore.wallet!);
    return SolanaPrivateKey.fromSeedHex(keys[0].privateKey);
  }

  void _handleResponseForTopic(String topic, JsonRpcResponse<dynamic> response) async {
    final session = walletKit.sessions.get(topic);

    try {
      await walletKit.respondSessionRequest(topic: topic, response: response);
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
}

extension on Map<String, dynamic> {
  TransactionInstruction toInstruction() {
    final programId = this['programId'] as String;
    final data = (this['data'] as List).map((e) => e as int).toList();
    final keys = this['keys'] as List;
    return TransactionInstruction.fromBytes(
      programId: SolAddress(programId),
      instructionBytes: data,
      keys: keys.map((k) {
        final kParams = (k as Map<String, dynamic>);
        return AccountMeta(
          publicKey:
              SolanaPublicKey.fromBytes(base58.decode(kParams['pubkey'] as String)).toAddress(),
          isWritable: kParams['isWritable'] as bool,
          isSigner: kParams['isSigner'] as bool,
        );
      }).toList(),
    );
  }
}
