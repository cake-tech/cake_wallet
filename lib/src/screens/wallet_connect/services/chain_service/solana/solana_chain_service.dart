import "dart:async";
import "dart:convert";

import "package:blockchain_utils/base58/base58.dart";
import "package:blockchain_utils/blockchain_utils.dart" as blockchain_utils;
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/solana_request_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/services/bottom_sheet_service.dart";
import "package:cake_wallet/src/screens/wallet_connect/widgets/bottom_sheet/bottom_sheet_message_display_widget.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/services/chain_service/solana/solana_chain_id.dart";
import "package:cake_wallet/src/screens/wallet_connect/services/chain_service/solana/solana_supported_methods.dart";
import "package:cake_wallet/src/screens/wallet_connect/services/key_service/wallet_connect_key_service.dart";
import "package:cake_wallet/src/screens/wallet_connect/utils/method_utils.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:on_chain/solana/solana.dart";
import "package:reown_walletkit/reown_walletkit.dart";

class SolanaChainService {
  SolanaChainService({
    required this.appStore,
    required this.bottomSheetService,
    required this.walletKit,
    required this.wcKeyService,
    required this.reference,
  }) : decoder = SolanaRequestDecoder(appStore) {
    for (final handler in solanaRequestHandlers.entries) {
      walletKit.registerRequestHandler(
        chainId: getChainId(),
        method: handler.key,
        handler: handler.value,
      );
    }
  }
  Map<String, dynamic Function(String, dynamic)> get solanaRequestHandlers => {
        SolanaSupportedMethods.solSignMessage.name: solanaSignMessage,
        SolanaSupportedMethods.solSignTransaction.name: solanaSignTransaction,
        SolanaSupportedMethods.solSignAllTransaction.name: solanaSignAllTransaction,
      };

  final AppStore appStore;
  final BottomSheetService bottomSheetService;
  final ReownWalletKit walletKit;
  final WalletConnectKeyService wcKeyService;
  final SolanaChainId reference;
  final SolanaRequestDecoder decoder;

  String getChainId() => reference.chain();

  Future<void> solanaSignMessage(String topic, dynamic parameters) async {
    printV("solanaSignMessage request: $parameters");

    final pRequest = MethodsUtils.pendingRequestFor(
        topic, SolanaSupportedMethods.solSignMessage.name, getChainId());
    if (pRequest == null) {
      return;
    }

    if (!await _authorizeRequest(topic, pRequest.id)) {
      return;
    }

    var response = JsonRpcResponse(id: pRequest.id, jsonrpc: "2.0");

    try {
      final params = parameters as Map<String, dynamic>;
      final message = params["message"].toString();
      final privateKey = _getSolanaPrivateKey();

      final decoded = await decoder.decodeSignMessage(message);

      final isApproved = await MethodsUtils.requestApproval(
        decoded,
        topic: topic,
        method: pRequest.method,
        chainId: pRequest.chainId,
        address: privateKey.publicKey().toAddress().address,
        transportType: pRequest.transportType.name,
        verifyContext: pRequest.verifyContext,
      );

      if (isApproved) {
        final base58Decoded = base58.decode(message);
        final signedBytes = privateKey.sign(base58Decoded);
        final signature = blockchain_utils.Base58Encoder.encode(signedBytes);
        response = response.copyWith(result: {"signature": signature});
      } else {
        final error = Errors.getSdkError(Errors.USER_REJECTED);
        response = response.copyWith(
          error: JsonRpcError(code: error.code, message: error.message),
        );
      }
    } catch (e) {
      printV("solanaSignMessage error $e");
      final error = Errors.getSdkError(Errors.MALFORMED_REQUEST_PARAMS);
      response = response.copyWith(
        error: JsonRpcError(code: error.code, message: error.message),
      );
    }

    await MethodsUtils.respondForTopic(topic, response);
  }

  Future<void> solanaSignTransaction(String topic, dynamic parameters) async {
    printV("solanaSignTransaction: ${jsonEncode(parameters)}");

    final pRequest = MethodsUtils.pendingRequestFor(
        topic, SolanaSupportedMethods.solSignTransaction.name, getChainId());
    if (pRequest == null) {
      return;
    }

    if (!await _authorizeRequest(topic, pRequest.id)) {
      return;
    }

    var response = JsonRpcResponse(id: pRequest.id, jsonrpc: "2.0");

    try {
      final params = parameters as Map<String, dynamic>;
      final privateKey = _getSolanaPrivateKey();

      final unSignedTransaction = decoder.transactionFromParams(params);
      if (unSignedTransaction == null) {
        final error = Errors.getSdkError(Errors.MALFORMED_REQUEST_PARAMS);
        await MethodsUtils.respondForTopic(
          topic,
          response.copyWith(error: JsonRpcError(code: error.code, message: error.message)),
        );
        return;
      }

      final decoded = await decoder.decodeTransaction(params);

      final isApproved = await MethodsUtils.requestApproval(
        decoded,
        topic: topic,
        method: pRequest.method,
        chainId: pRequest.chainId,
        address: privateKey.publicKey().toAddress().address,
        transportType: pRequest.transportType.name,
        verifyContext: pRequest.verifyContext,
      );

      if (isApproved) {
        final signedTx = privateKey.sign(unSignedTransaction.serializeMessage());
        final signature = Base58Encoder.encode(signedTx.toList(growable: false));
        response = response.copyWith(result: {"signature": signature});
      } else {
        final error = Errors.getSdkError(Errors.USER_REJECTED);
        response = response.copyWith(
          error: JsonRpcError(code: error.code, message: error.message),
        );
      }
    } catch (e, s) {
      printV("solanaSignTransaction error $e, $s");
      final error = Errors.getSdkError(Errors.MALFORMED_REQUEST_PARAMS);
      response = response.copyWith(
        error: JsonRpcError(code: error.code, message: error.message),
      );
    }

    await MethodsUtils.respondForTopic(topic, response);
  }

  Future<void> solanaSignAllTransaction(String topic, dynamic parameters) async {
    printV("solanaSignAllTransaction: ${jsonEncode(parameters)}");

    final pRequest = MethodsUtils.pendingRequestFor(
        topic, SolanaSupportedMethods.solSignAllTransaction.name, getChainId());
    if (pRequest == null) {
      return;
    }

    if (!await _authorizeRequest(topic, pRequest.id)) {
      return;
    }

    var response = JsonRpcResponse(id: pRequest.id, jsonrpc: "2.0");

    try {
      final params = parameters as Map<String, dynamic>;
      final privateKey = _getSolanaPrivateKey();

      final transactions = (params["transactions"] as List?)?.cast<String>() ?? const <String>[];
      if (transactions.isEmpty) {
        final error = Errors.getSdkError(Errors.MALFORMED_REQUEST_PARAMS);
        await MethodsUtils.respondForTopic(
          topic,
          response.copyWith(error: JsonRpcError(code: error.code, message: error.message)),
        );
        return;
      }

      final decoded = await decoder.decodeAllTransactions(params);

      final isApproved = await MethodsUtils.requestApproval(
        decoded,
        topic: topic,
        method: pRequest.method,
        chainId: pRequest.chainId,
        address: privateKey.publicKey().toAddress().address,
        transportType: pRequest.transportType.name,
        verifyContext: pRequest.verifyContext,
      );

      if (isApproved) {
        final List<String> signedTransactions = [];
        for (final transaction in transactions) {
          final transactionBytes = base64.decode(transaction);
          final unsignedTx = SolanaTransaction.deserialize(transactionBytes);
          final serializedTx = privateKey.sign(unsignedTx.serializeMessage());
          unsignedTx.addSignature(privateKey.publicKey().toAddress(), serializedTx);
          final reEncodedTx = unsignedTx.serializeString(
            encoding: TransactionSerializeEncoding.base64,
          );
          signedTransactions.add(reEncodedTx);
        }
        response = response.copyWith(result: {"transactions": signedTransactions});
      } else {
        final error = Errors.getSdkError(Errors.USER_REJECTED);
        response = response.copyWith(
          error: JsonRpcError(code: error.code, message: error.message),
        );
      }
    } catch (e, s) {
      printV("solanaSignAllTransactions error $e, $s");
      final error = Errors.getSdkError(Errors.MALFORMED_REQUEST_PARAMS);
      response = response.copyWith(
        error: JsonRpcError(code: error.code, message: error.message),
      );
    }

    await MethodsUtils.respondForTopic(topic, response);
  }

  /// True when this request may be answered: the session must belong to the
  /// open wallet. A request for a different wallet is rejected and the user is
  /// told why, so switching wallets cannot hand a dApp the wrong account.
  Future<bool> _authorizeRequest(String topic, int requestId) async {
    final wallet = appStore.wallet;
    if (wallet != null) {
      final keys = wcKeyService.getKeysForChain(wallet);
      if (keys.isNotEmpty &&
          MethodsUtils.isSessionOwnedByWallet(
            walletKit.sessions.get(topic),
            keys.first.publicKey,
          )) {
        return true;
      }
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

  SolanaPrivateKey _getSolanaPrivateKey() {
    final keys = wcKeyService.getKeysForChain(appStore.wallet!);
    return SolanaPrivateKey.fromSeedHex(keys[0].privateKey);
  }
}
