import "dart:async";
import 'dart:convert';

import 'package:blockchain_utils/base58/base58.dart';
import 'package:blockchain_utils/blockchain_utils.dart' as blockchain_utils;
import 'package:cake_wallet/src/screens/wallet_connect/services/chain_service/solana/solana_supported_methods.dart';
import "package:cw_core/utils/print_verbose.dart";
import 'package:flutter/material.dart';
import 'package:on_chain/solana/solana.dart';
import 'package:reown_walletkit/reown_walletkit.dart';

import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/solana_request_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart";
import 'package:cake_wallet/src/screens/wallet_connect/services/bottom_sheet_service.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/chain_service/solana/solana_chain_id.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/key_service/wallet_connect_key_service.dart';
import 'package:cake_wallet/src/screens/wallet_connect/utils/method_utils.dart';
import "package:cake_wallet/src/screens/wallet_connect/widgets/bottom_sheet/bottom_sheet_message_display_widget.dart";
import 'package:cake_wallet/store/app_store.dart';

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

  static const _maxSignMessageLength = 10000;

  static const _maxTransactions = 100;

  static final _malformed = Errors.getSdkError(Errors.MALFORMED_REQUEST_PARAMS);

  static const _unauthorized = JsonRpcError(
    code: 4100,
    message: "The requested account has not been authorized by the user.",
  );

  Future<void> solanaSignMessage(String topic, dynamic parameters) async {
    debugPrint('solanaSignMessage request: $parameters');

    final pRequest = MethodsUtils.pendingRequestFor(
      topic,
      SolanaSupportedMethods.solSignMessage.name,
      getChainId(),
      parameters,
    );
    if (pRequest == null) {
      return;
    }

    if (!await _authorizeRequest(topic, pRequest.id)) {
      return;
    }

    final List<int> messageBytes;
    final WCDecodedRequest decoded;
    try {
      final params = parameters as Map<String, dynamic>;
      if (_namesAnotherAccount(params, _walletAddress())) {
        await _refuseAsForAnotherWallet(topic, pRequest.id);
        return;
      }

      final message = params['message'].toString();
      if (message.length > _maxSignMessageLength) {
        throw const FormatException("solana_signMessage payload is too long");
      }

      messageBytes = base58.decode(message);
      decoded = decoder.decodeSignMessage(messageBytes);
    } catch (e) {
      printV("solanaSignMessage refused: $e");
      await _refuse(topic, pRequest.id);
      return;
    }

    await _approveAndSign(pRequest, decoded, _walletAddress(), (privateKey) {
      final signedBytes = privateKey.sign(messageBytes);
      final signature = blockchain_utils.Base58Encoder.encode(signedBytes);
      return {"signature": signature};
    });
  }

  Future<void> solanaSignTransaction(String topic, dynamic parameters) async {
    debugPrint('solanaSignTransaction: ${jsonEncode(parameters)}');

    final pRequest = MethodsUtils.pendingRequestFor(
      topic,
      SolanaSupportedMethods.solSignTransaction.name,
      getChainId(),
      parameters,
    );
    if (pRequest == null) {
      return;
    }

    if (!await _authorizeRequest(topic, pRequest.id)) {
      return;
    }

    final walletAddress = _walletAddress();
    final List<int> messageBytes;
    final WCDecodedRequest decoded;
    try {
      final params = parameters as Map<String, dynamic>;
      final unSignedTransaction = decoder.transactionFromParams(params);
      if (unSignedTransaction == null) {
        await _refuse(topic, pRequest.id);
        return;
      }

      if (_namesAnotherAccount(params, walletAddress) ||
          !_isSigner(unSignedTransaction, walletAddress)) {
        await _refuseAsForAnotherWallet(topic, pRequest.id);
        return;
      }

      messageBytes = unSignedTransaction.serializeMessage();
      decoded = await decoder.decodeTransaction(params, walletAddress: walletAddress);
    } catch (e, s) {
      printV("solanaSignTransaction refused: $e, $s");
      await _refuse(topic, pRequest.id);
      return;
    }

    await _approveAndSign(pRequest, decoded, walletAddress, (privateKey) {
      final signedTx = privateKey.sign(messageBytes);
      final signature = Base58Encoder.encode(signedTx.toList(growable: false));
      return {"signature": signature};
    });
  }

  Future<void> solanaSignAllTransaction(String topic, dynamic parameters) async {
    debugPrint('solanaSignAllTransaction: ${jsonEncode(parameters)}');

    final pRequest = MethodsUtils.pendingRequestFor(
      topic,
      SolanaSupportedMethods.solSignAllTransaction.name,
      getChainId(),
      parameters,
    );
    if (pRequest == null) {
      return;
    }

    if (!await _authorizeRequest(topic, pRequest.id)) {
      return;
    }

    final walletAddress = _walletAddress();
    final List<SolanaTransaction> transactions;
    final WCDecodedRequest decoded;
    try {
      final params = parameters as Map<String, dynamic>;
      final entries = params["transactions"] as List? ?? const [];
      if (entries.isEmpty) {
        await _refuse(topic, pRequest.id);
        return;
      }

      if (entries.length > _maxTransactions) {
        await _refuse(
          topic,
          pRequest.id,
          message: S.current.wc_too_many_transactions(_maxTransactions.toString()),
        );
        return;
      }

      transactions = decoder.transactionsFromParams(params);
      if (!transactions.every((transaction) => _isSigner(transaction, walletAddress))) {
        await _refuseAsForAnotherWallet(topic, pRequest.id);
        return;
      }

      decoded = await decoder.decodeAllTransactions(params, walletAddress: walletAddress);
    } catch (e, s) {
      printV("solanaSignAllTransactions refused: $e, $s");
      await _refuse(topic, pRequest.id);
      return;
    }

    await _approveAndSign(pRequest, decoded, walletAddress, (privateKey) {
      final List<String> signedTransactions = [];
      for (final transaction in transactions) {
        final signature = privateKey.sign(transaction.serializeMessage());
        transaction.addSignature(privateKey.publicKey().toAddress(), signature);
        signedTransactions.add(
          transaction.serializeString(encoding: TransactionSerializeEncoding.base64),
        );
      }
      return {"transactions": signedTransactions};
    });
  }

  SolanaPrivateKey _getSolanaPrivateKey() {
    return SolanaPrivateKey.fromSeedHex(wcKeyService.getPrivateKey(appStore.wallet!));
  }

  Future<void> _approveAndSign(
    SessionRequest request,
    WCDecodedRequest decoded,
    String walletAddress,
    Map<String, dynamic> Function(SolanaPrivateKey privateKey) sign,
  ) async {
    final topic = request.topic;
    var response = JsonRpcResponse(id: request.id, jsonrpc: "2.0");

    final isApproved = await MethodsUtils.requestApproval(
      decoded,
      topic: topic,
      method: request.method,
      chainId: request.chainId,
      address: walletAddress,
      transportType: request.transportType.name,
      verifyContext: request.verifyContext,
    );

    if (isApproved && !await _isRequestStillValid(topic, request.id)) {
      return;
    }

    if (isApproved) {
      try {
        response = response.copyWith(result: sign(_getSolanaPrivateKey()));
      } catch (e) {
        printV("${request.method}: signing failed (${e.runtimeType})");
        response = response.copyWith(
          error: JsonRpcError(code: _malformed.code, message: _malformed.message),
        );
      }
    } else {
      response = response.copyWith(error: MethodsUtils.userRejectedError);
    }

    await MethodsUtils.respondForTopic(topic, response);
  }

  bool _namesAnotherAccount(Map<String, dynamic> params, String walletAddress) {
    final pubkey = params["pubkey"];

    return pubkey != null && pubkey != walletAddress;
  }

  bool _isSigner(SolanaTransaction transaction, String walletAddress) =>
      transaction.signers.any((signer) => signer.address == walletAddress);

  Future<void> _refuseAsForAnotherWallet(String topic, int requestId) => _refuse(
    topic,
    requestId,
    message: S.current.wc_request_for_different_wallet,
    error: _unauthorized,
  );

  Future<void> _refuse(String topic, int requestId, {String? message, JsonRpcError? error}) async {
    _showMessage(message ?? S.current.wc_request_malformed);
    await MethodsUtils.respondForTopic(
      topic,
      JsonRpcResponse(
        id: requestId,
        jsonrpc: "2.0",
        error: error ?? JsonRpcError(code: _malformed.code, message: _malformed.message),
      ),
      isUserDecision: false,
    );
  }

  Future<bool> _isRequestStillValid(String topic, int requestId) async {
    if (!await MethodsUtils.isRequestStillPending(topic, requestId)) {
      _showMessage(S.current.wc_request_expired);
      return false;
    }

    return _authorizeRequest(topic, requestId);
  }

  Future<bool> _authorizeRequest(String topic, int requestId) async {
    final wallet = appStore.wallet;
    if (wallet != null) {
      final keys = wcKeyService.getKeysForChain(wallet);
      if (keys.isNotEmpty &&
          keys.first.chains.contains(getChainId()) &&
          MethodsUtils.isSessionOwnedByWallet(
            walletKit.sessions.get(topic),
            keys.first.publicKey,
          )) {
        return true;
      }
    }

    _showMessage(S.current.wc_request_for_different_wallet);
    await MethodsUtils.respondUnauthorized(topic, requestId);

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

  String _walletAddress() => wcKeyService.getKeysForChain(appStore.wallet!).first.publicKey;
}
