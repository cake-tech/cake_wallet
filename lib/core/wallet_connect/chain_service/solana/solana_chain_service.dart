import 'dart:developer';

import 'package:cake_wallet/core/wallet_connect/chain_service/solana/entities/solana_sign_message.dart';
import 'package:cake_wallet/core/wallet_connect/chain_service/solana/solana_chain_id.dart';
import 'package:cake_wallet/core/wallet_connect/wc_bottom_sheet_service.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/message_display_widget.dart';
import 'package:cake_wallet/core/wallet_connect/models/connection_model.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/connection_widget.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/modals/web3_request_modal.dart';
import 'package:solana/base58.dart';
import 'package:solana/encoder.dart';
import 'package:solana/solana.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import '../chain_service.dart';
import '../../wallet_connect_key_service.dart';
import 'entities/solana_sign_transaction.dart';

class SolanaChainServiceImpl implements ChainService {
  final BottomSheetService bottomSheetService;
  final Web3Wallet wallet;
  final WalletConnectKeyService wcKeyService;

  static const namespace = 'solana';
  static const solSignTransaction = 'solana_signTransaction';
  static const solSignMessage = 'solana_signMessage';

  final SolanaChainId reference;

  final SolanaClient solanaClient;

  final Ed25519HDKeyPair? ownerKeyPair;

  SolanaChainServiceImpl({
    required this.reference,
    required this.wcKeyService,
    required this.bottomSheetService,
    required this.wallet,
    required this.ownerKeyPair,
    required String webSocketUrl,
    required Uri rpcUrl,
    SolanaClient? solanaClient,
  }) : solanaClient = solanaClient ??
            SolanaClient(
              rpcUrl: rpcUrl,
              websocketUrl: Uri.parse(webSocketUrl),
              timeout: const Duration(minutes: 2),
            ) {
    for (final String event in getEvents()) {
      wallet.registerEventEmitter(chainId: getChainId(), event: event);
    }
    wallet.registerRequestHandler(
      chainId: getChainId(),
      method: solSignTransaction,
      handler: solanaSignTransaction,
    );
    wallet.registerRequestHandler(
      chainId: getChainId(),
      method: solSignMessage,
      handler: solanaSignMessage,
    );
  }

  @override
  String getNamespace() {
    return namespace;
  }

  @override
  String getChainId() {
    return reference.chain();
  }

  @override
  List<String> getEvents() {
    return [''];
  }

  Future<String?> requestAuthorization(String? text) async {
    // Show the bottom sheet
    final bool? isApproved = await bottomSheetService.queueBottomSheet(
      widget: Web3RequestModal(
        child: ConnectionWidget(
          title: S.current.signTransaction,
          info: [
            ConnectionModel(
              text: text,
            ),
          ],
        ),
      ),
    ) as bool?;

    if (isApproved != null && isApproved == false) {
      return 'User rejected signature';
    }

    return null;
  }

  Future<String> solanaSignTransaction(String topic, dynamic parameters) async {
    log('received solana sign transaction request');

    final solanaSignTransaction =
        SolanaSignTransaction.fromJson(parameters as Map<String, dynamic>);

    final String? authError = await requestAuthorization('Confirm request to sign transaction?');

    if (authError != null) {
      return authError;
    }

    try {
      List<Instruction> instructions = List.empty(growable: true);

      for (var element in solanaSignTransaction.instructions) {
        List<AccountMeta> accountMetas = [];
        for (var key in element.keys) {
          accountMetas.add(
            AccountMeta.writeable(
              pubKey: Ed25519HDPublicKey.fromBase58(key.pubkey),
              isSigner: key.isSigner,
            ),
          );
        }
        instructions.add(
          Instruction(
            programId: Ed25519HDPublicKey.fromBase58(element.programId),
            accounts: accountMetas,
            data: ByteArray(element.data),
          ),
        );
      }

      Message message = Message.only(instructions.first);

      final sign = await ownerKeyPair?.signMessage(
        message: message,
        recentBlockhash: solanaSignTransaction.recentBlockhash,
      );

      if (sign == null) {
        return '';
      }

      String signature = sign.signatures.first.toBase58();

      bottomSheetService.queueBottomSheet(
        isModalDismissible: true,
        widget: BottomSheetMessageDisplayWidget(
          message: S.current.awaitDAppProcessing,
          isError: false,
        ),
      );

      return signature;
    } catch (e) {
      log('An error has occurred while signing transaction: ${e.toString()}');
      bottomSheetService.queueBottomSheet(
        isModalDismissible: true,
        widget: BottomSheetMessageDisplayWidget(
          message: '${S.current.errorSigningTransaction}: ${e.toString()}',
        ),
      );
      return 'Failed';
    }
  }

  Future<String> solanaSignMessage(String topic, dynamic parameters) async {
    log('received solana sign message request: $parameters');

    final solanaSignMessage = SolanaSignMessage.fromJson(parameters as Map<String, dynamic>);

    final String? authError = await requestAuthorization('Confirm request to sign message?');

    if (authError != null) {
      return authError;
    }

    final sign = await ownerKeyPair?.sign(base58decode(solanaSignMessage.message));

    if (sign == null) {
      return '';
    }

    String signature = base58encode(sign.bytes);

    return signature;
  }
}
