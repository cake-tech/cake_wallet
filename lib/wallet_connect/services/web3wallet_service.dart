import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';

import 'package:cake_wallet/wallet_connect/models/auth_request_model.dart';
import 'package:cake_wallet/wallet_connect/models/session_request_model.dart';
import 'package:cake_wallet/wallet_connect/screens/widgets/connection_request_widget.dart';
import 'package:cake_wallet/wallet_connect/screens/widgets/modals/web3_request_modal.dart';
import 'package:cake_wallet/wallet_connect/utils/constants.dart';
import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

import '../models/chain_key_model.dart';
import 'bottom_sheet_service.dart';
import 'key_service.dart';

abstract class Web3WalletService implements Disposable {
  abstract ValueNotifier<List<PairingInfo>> pairings;
  abstract ValueNotifier<List<SessionData>> sessions;
  abstract ValueNotifier<List<StoredCacao>> auth;

  void create();
  Future<void> init();
  Web3Wallet getWeb3Wallet();
}

class Web3WalletServiceImpl implements Web3WalletService {
  final BottomSheetService _bottomSheetHandler = GetIt.I<BottomSheetService>();

  Web3Wallet? _web3Wallet;

  /// The list of requests from the dapp
  /// Potential types include, but aren't limited to:
  /// [SessionProposalEvent], [AuthRequest]
  @override
  ValueNotifier<List<PairingInfo>> pairings = ValueNotifier<List<PairingInfo>>([]);
  @override
  ValueNotifier<List<SessionData>> sessions = ValueNotifier<List<SessionData>>([]);
  @override
  ValueNotifier<List<StoredCacao>> auth = ValueNotifier<List<StoredCacao>>([]);

  @override
  void create() {
    // Create the web3wallet client
    _web3Wallet = Web3Wallet(
      core: Core(projectId: '8eaf78b8e19d71bfa435b5f34eef83e6'),
      metadata: const PairingMetadata(
        name: 'Example Wallet',
        description: 'Example Wallet',
        url: 'https://walletconnect.com/',
        icons: ['https://walletconnect.com/walletconnect-logo.png'],
      ),
    );

    // Setup our accounts
    List<ChainKeyModel> chainKeys = GetIt.I<WalletConnectKeyService>().getKeys();
    for (final chainKey in chainKeys) {
      for (final chainId in chainKey.chains) {
        _web3Wallet!.registerAccount(
          chainId: chainId,
          accountAddress: chainKey.publicKey,
        );
      }
    }

    // Setup our listeners
    log('web3wallet create');
    _web3Wallet!.core.pairing.onPairingInvalid.subscribe(_onPairingInvalid);
    _web3Wallet!.core.pairing.onPairingCreate.subscribe(_onPairingCreate);
    _web3Wallet!.pairings.onSync.subscribe(_onPairingsSync);
    _web3Wallet!.onSessionProposal.subscribe(_onSessionProposal);
    _web3Wallet!.onSessionProposalError.subscribe(_onSessionProposalError);
    _web3Wallet!.onSessionConnect.subscribe(_onSessionConnect);
    _web3Wallet!.onAuthRequest.subscribe(_onAuthRequest);
  }

  @override
  Future<void> init() async {
    // Await the initialization of the web3wallet
    log('web3wallet init');
    await _web3Wallet!.init();

    pairings.value = _web3Wallet!.pairings.getAll();
    sessions.value = _web3Wallet!.sessions.getAll();
    auth.value = _web3Wallet!.completeRequests.getAll();
  }

  @override
  FutureOr onDispose() {
    log('web3wallet dispose');
    _web3Wallet!.core.pairing.onPairingInvalid.unsubscribe(_onPairingInvalid);
    _web3Wallet!.pairings.onSync.unsubscribe(_onPairingsSync);
    _web3Wallet!.onSessionProposal.unsubscribe(_onSessionProposal);
    _web3Wallet!.onSessionProposalError.unsubscribe(_onSessionProposalError);
    _web3Wallet!.onSessionConnect.unsubscribe(_onSessionConnect);
    _web3Wallet!.onAuthRequest.unsubscribe(_onAuthRequest);
  }

  @override
  Web3Wallet getWeb3Wallet() {
    return _web3Wallet!;
  }

  void _onPairingsSync(StoreSyncEvent? args) {
    if (args != null) {
      pairings.value = _web3Wallet!.pairings.getAll();
    }
  }

  void _onSessionProposalError(SessionProposalErrorEvent? args) {
    log(args.toString());
  }

  void _onSessionProposal(SessionProposalEvent? args) async {
    if (args != null) {
      final Widget modalWidget = Web3RequestModal(
        child: ConnectionRequestWidget(
          wallet: _web3Wallet!,
          sessionProposal: SessionRequestModel(request: args.params),
        ),
      );
      DialogPopUpTest(modalWidget: modalWidget);
      // show the bottom sheet
      final bool? isApproved = true;
      // await _bottomSheetHandler.queueBottomSheet(
      //   widget: modalWidget,
      // );

      if (isApproved != null && isApproved) {
        _web3Wallet!.approveSession(
          id: args.id,
          namespaces: args.params.generatedNamespaces!,
        );
      } else {
        _web3Wallet!.rejectSession(
          id: args.id,
          reason: Errors.getSdkError(
            Errors.USER_REJECTED,
          ),
        );
      }
    }
  }

  void _onPairingInvalid(PairingInvalidEvent? args) {
    log('Pairing Invalid Event: $args');
  }

  void _onPairingCreate(PairingEvent? args) {
    log('Pairing Create Event: $args');
  }

  void _onSessionConnect(SessionConnect? args) {
    if (args != null) {
      sessions.value.add(args.session);
    }
  }

  Future<void> _onAuthRequest(AuthRequest? args) async {
    if (args != null) {
      List<ChainKeyModel> chainKeys = GetIt.I<WalletConnectKeyService>().getKeysForChain(
        'eip155:1',
      );
      // Create the message to be signed
      final String iss = 'did:pkh:eip155:1:${chainKeys.first.publicKey}';

      final Widget modalWidget = Web3RequestModal(
        child: ConnectionRequestWidget(
          wallet: _web3Wallet!,
          authRequest: AuthRequestModel(iss: iss, request: args),
        ),
      );
      final bool? isAuthenticated = await _bottomSheetHandler.queueBottomSheet(
        widget: modalWidget,
      ) as bool?;

      if (isAuthenticated != null && isAuthenticated) {
        final String message = _web3Wallet!.formatAuthMessage(
          iss: iss,
          cacaoPayload: CacaoRequestPayload.fromPayloadParams(
            args.payloadParams,
          ),
        );

        final String sig = EthSigUtil.signPersonalMessage(
          message: Uint8List.fromList(message.codeUnits),
          privateKey: chainKeys.first.privateKey,
        );

        await _web3Wallet!.respondAuthRequest(
          id: args.id,
          iss: iss,
          signature: CacaoSignature(
            t: CacaoSignature.EIP191,
            s: sig,
          ),
        );
      } else {
        await _web3Wallet!.respondAuthRequest(
          id: args.id,
          iss: iss,
          error: Errors.getSdkError(
            Errors.USER_REJECTED_AUTH,
          ),
        );
      }
    }
  }
}

class DialogPopUpTest extends StatefulWidget {
  final Widget modalWidget;
  const DialogPopUpTest({
    Key? key,
    required this.modalWidget,
  }) : super(key: key);

  @override
  State<DialogPopUpTest> createState() => _DialogPopUpTestState();
}

class _DialogPopUpTestState extends State<DialogPopUpTest> {
  @override
  void initState() {
    super.initState();
    showMoaBottomSheet();
  }

  Future<bool> showMoaBottomSheet() async {
    final value = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: StyleConstants.clear,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: StyleConstants.layerColor1,
            borderRadius: BorderRadius.all(
              Radius.circular(
                StyleConstants.linear16,
              ),
            ),
          ),
          padding: const EdgeInsets.all(
            StyleConstants.linear16,
          ),
          margin: const EdgeInsets.all(
            StyleConstants.linear16,
          ),
          child: widget.modalWidget,
        );
      },
    );
    return value ?? false;
    // item.completer.complete(value);
    // _bottomSheetService.showNext();
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
