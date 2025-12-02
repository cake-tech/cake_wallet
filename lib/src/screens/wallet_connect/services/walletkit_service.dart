import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cw_core/wallet_type.dart';
import 'package:eth_sig_util/util/utils.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:reown_walletkit/reown_walletkit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/chain_service/eth/evm_chain_id.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/chain_service/eth/evm_chain_service.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/key_service/chain_key_model.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/key_service/wallet_connect_key_service.dart';
import 'package:cake_wallet/src/screens/wallet_connect/utils/eth_utils.dart';
import 'package:cake_wallet/src/screens/wallet_connect/utils/method_utils.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/wc_connection_request_widget.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/bottom_sheet/bottom_sheet_message_display_widget.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/wc_request_widget.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/wc_session_auth_request_widget.dart';
import 'package:cake_wallet/store/app_store.dart';

import 'bottom_sheet_service.dart';
import 'chain_service/solana/solana_chain_id.dart';
import 'chain_service/solana/solana_chain_service.dart';

part 'walletkit_service.g.dart';

class WalletKitService = WalletKitServiceBase with _$WalletKitService;

abstract class WalletKitServiceBase with Store {
  WalletKitServiceBase(
    this._bottomSheetHandler,
    this.walletKeyService,
    this.appStore,
    this.sharedPreferences,
  )   : pairings = ObservableList<PairingInfo>(),
        sessions = ObservableList<SessionData>(),
        auth = ObservableList<PendingSessionAuthRequest>(),
        isInitialized = false;

  final AppStore appStore;
  final SharedPreferences sharedPreferences;
  final BottomSheetService _bottomSheetHandler;
  final WalletConnectKeyService walletKeyService;

  late ReownWalletKit _walletKit;

  @observable
  bool isInitialized;

  /// The list of requests from the dapp
  /// Potential types include, but aren't limited to:
  /// [SessionProposalEvent], [SessionAuthRequest]
  @observable
  ObservableList<PairingInfo> pairings;

  @observable
  ObservableList<SessionData> sessions;

  @observable
  ObservableList<PendingSessionAuthRequest> auth;

  @action
  void create() {
    // Create the walletkit client
    _walletKit = ReownWalletKit(
      core: ReownCore(
        projectId: secrets.walletConnectProjectId,
      ),
      metadata: const PairingMetadata(
        name: 'Cake Wallet',
        description: 'Cake Wallet',
        url: 'https://cakewallet.com',
        icons: ['https://cakewallet.com/assets/image/cake_logo.png'],
        redirect: Redirect(native: 'cakewallet://'),
      ),
    );

    _walletKit.core.addLogListener(_logListener);

    // Setup our listeners
    log('Created instance of walletKit');

    _walletKit.core.pairing.onPairingInvalid.subscribe(_onPairingInvalid);
    _walletKit.core.pairing.onPairingCreate.subscribe(_onPairingCreate);
    _walletKit.core.relayClient.onRelayClientError.subscribe(_onRelayClientError);
    _walletKit.core.relayClient.onRelayClientMessage.subscribe(_onRelayClientMessage);

    _walletKit.onSessionProposal.subscribe(_onSessionProposal);
    _walletKit.onSessionProposalError.subscribe(_onSessionProposalError);
    _walletKit.onSessionConnect.subscribe(_onSessionConnect);
    _walletKit.onSessionAuthRequest.subscribe(_onSessionAuthRequest);

    _walletKit.pairings.onSync.subscribe(_onPairingsSync);
    _walletKit.core.pairing.onPairingDelete.subscribe(_onPairingDelete);
    _walletKit.core.pairing.onPairingExpire.subscribe(_onPairingDelete);

    // Setup our accounts
    List<ChainKeyModel> chainKeys = walletKeyService.getKeys(appStore.wallet!);
    for (final chainKey in chainKeys) {
      for (final chainId in chainKey.chains) {
        final chainNameSpace = getChainNameSpaceAndIdBasedOnWalletType(appStore.wallet!.type);
        if (chainNameSpace == chainId) {
          final account = '$chainId:${chainKey.publicKey}';
          debugPrint('registerAccount $account');
          _walletKit.registerAccount(
            chainId: chainId,
            accountAddress: chainKey.publicKey,
          );
        }
      }
    }
  }

  void _logListener(String event) {
    debugPrint('[WalletKit] $event');
  }

  @action
  Future<void> init() async {
    // Await the initialization of walletKit
    debugPrint('Intializing walletKit');
    if (!isInitialized) {
      try {
        await _walletKit.init();
        debugPrint('Initialized');
        isInitialized = true;
      } catch (e) {
        debugPrint('init Error: ${e.toString()}');
        isInitialized = false;
      }
    }

    await _emitEvent();

    _refreshPairings();

    final newSessions = _walletKit.sessions.getAll();
    sessions.addAll(newSessions);

    final newAuthRequests = _walletKit.sessionAuthRequests.getAll();
    auth.addAll(newAuthRequests);

    if (isEVMCompatibleChain(appStore.wallet!.type)) {
      for (final cId in EVMChainId.values) {
        EvmChainServiceImpl(
          reference: cId,
          appStore: appStore,
          wcKeyService: walletKeyService,
          bottomSheetService: _bottomSheetHandler,
          walletKit: _walletKit,
        );
      }
    }

    if (appStore.wallet!.type == WalletType.solana) {
      for (final cId in SolanaChainId.values) {
        SolanaChainService(
          reference: cId,
          appStore: appStore,
          wcKeyService: walletKeyService,
          bottomSheetService: _bottomSheetHandler,
          walletKit: _walletKit,
        );
      }
    }
  }

  @action
  Future<void> _emitEvent() async {
    final isOnline = _walletKit.core.connectivity.isOnline.value;
    if (!isOnline) {
      await Future.delayed(const Duration(milliseconds: 500));
      _emitEvent();
      return;
    }

    final sessions = _walletKit.sessions.getAll();
    for (var session in sessions) {
      final chainKeys = walletKeyService.getKeysForChain(appStore.wallet!);
      for (var chain in chainKeys) {
        for (var chainID in chain.chains) {
          try {
            final events = NamespaceUtils.getNamespacesEventsForChain(
              chainId: chainID,
              namespaces: session.namespaces,
            );
            if (events.contains('accountsChanged')) {
              final chainKeys = walletKeyService.getKeysForChain(appStore.wallet!);
              _walletKit.emitSessionEvent(
                topic: session.topic,
                chainId: chainID,
                event: SessionEventParams(
                  name: 'accountsChanged',
                  data: [chainKeys.first.publicKey],
                ),
              );
            }
          } on ReownSignError catch (e) {
            if (e.code == 6) {
              try {
                await deletePairing(topic: session.pairingTopic);
              } catch (_) {}
              _refreshPairings();
            }
          } catch (_) {}
        }
      }
    }
  }

  @action
  FutureOr<void> onDispose() {
    log('walletKit dispose');
    _walletKit.core.removeLogListener(_logListener);

    _walletKit.core.pairing.onPairingInvalid.unsubscribe(_onPairingInvalid);
    _walletKit.core.pairing.onPairingCreate.unsubscribe(_onPairingCreate);
    _walletKit.core.relayClient.onRelayClientError.unsubscribe(_onRelayClientError);
    _walletKit.core.relayClient.onRelayClientMessage.unsubscribe(_onRelayClientMessage);

    _walletKit.onSessionProposal.unsubscribe(_onSessionProposal);
    _walletKit.onSessionProposalError.unsubscribe(_onSessionProposalError);
    _walletKit.onSessionConnect.unsubscribe(_onSessionConnect);
    _walletKit.onSessionAuthRequest.unsubscribe(_onSessionAuthRequest);

    _walletKit.pairings.onSync.unsubscribe(_onPairingsSync);
    _walletKit.core.pairing.onPairingDelete.unsubscribe(_onPairingDelete);
    _walletKit.core.pairing.onPairingExpire.unsubscribe(_onPairingDelete);

    isInitialized = false;
  }

  ReownWalletKit get walletKit => _walletKit;

  void _onRelayClientMessage(MessageEvent? event) async {
    if (event != null) {
      final jsonObject = await EthUtils.decodeMessageEvent(event);
      debugPrint('_onRelayClientMessage $jsonObject');

      if (jsonObject is JsonRpcRequest) {
        debugPrint(jsonObject.id.toString());
        debugPrint(jsonObject.method);

        if (jsonObject.method == 'wc_sessionDelete') {
          await disconnectSession(topic: event.topic);
        }
      }
    }
  }

  void _onPairingsSync(StoreSyncEvent? args) {
    if (args != null) {
      _refreshPairings();
    }
  }

  void _onPairingDelete(PairingEvent? event) {
    _refreshPairings();
  }

  @action
  Future<void> _onSessionProposal(SessionProposalEvent? args) async {
    debugPrint('_onSessionProposal ${jsonEncode(args?.params)}');

    if (args != null) {
      final proposer = args.params.proposer;
      final result = (await _bottomSheetHandler.queueBottomSheet(
            widget: WCRequestWidget(
              verifyContext: args.verifyContext,
              child: WCConnectionRequestWidget(
                proposalData: args.params,
                verifyContext: args.verifyContext,
                requester: proposer,
                walletKeyService: walletKeyService,
                walletKit: walletKit,
                appStore: appStore,
              ),
            ),
          )) ??
          WCBottomSheetResult.reject;

      if (result != WCBottomSheetResult.reject) {
        try {
          await _walletKit.approveSession(
            id: args.id,
            namespaces: NamespaceUtils.regenerateNamespacesWithChains(
              args.params.generatedNamespaces!,
            ),
            sessionProperties: args.params.sessionProperties,
          );
        } on ReownSignError catch (error) {
          MethodsUtils.handleRedirect(
            '',
            proposer.metadata.redirect,
            error.message,
          );
        }
      } else {
        final error = Errors.getSdkError(Errors.USER_REJECTED).toSignError();
        await _walletKit.rejectSession(id: args.id, reason: error);
        await _walletKit.core.pairing.disconnect(topic: args.params.pairingTopic);
        MethodsUtils.handleRedirect(
          '',
          proposer.metadata.redirect,
          error.message,
        );
      }
    }
  }

  @action
  Future<void> _onSessionProposalError(SessionProposalErrorEvent? args) async {
    debugPrint('_onSessionProposalError $args');

    if (args != null) {
      String errorMessage = args.error.message;
      if (args.error.code == 5100) {
        errorMessage =
            errorMessage.replaceFirst('${S.current.requested}:', '\n\n${S.current.requested}:');
        errorMessage =
            errorMessage.replaceFirst('${S.current.supported}:', '\n\n${S.current.supported}:');
      }
      MethodsUtils.goBackModal(
        title: S.current.error,
        message: errorMessage,
        success: false,
      );
    }
  }

  @action
  Future<void> _onSessionConnect(SessionConnect? args) async {
    if (args != null) {
      final session = jsonEncode(args.session.toJson());

      debugPrint('_onSessionConnect $session');

      await savePairingTopicToLocalStorage(args.session.pairingTopic);

      sessions.add(args.session);

      _refreshPairings();

      MethodsUtils.handleRedirect(
        args.session.topic,
        args.session.peer.metadata.redirect,
        '',
        true,
      );
    }
  }

  @action
  void _onRelayClientError(ErrorEvent? args) {
    debugPrint('_onRelayClientError ${args?.error}');
    //  _bottomSheetHandler.queueBottomSheet(
    //     isModalDismissible: true,
    //     widget: BottomSheetMessageDisplayWidget(
    //       message: "WC RelayClient Error: ${args?.error}",
    //     ),
    //   );
  }

  @action
  void _onPairingInvalid(PairingInvalidEvent? args) {
    debugPrint('_onPairingInvalid $args');
    _bottomSheetHandler.queueBottomSheet(
      isModalDismissible: true,
      widget: BottomSheetMessageDisplayWidget(
        message: '${S.current.pairingInvalidEvent}: $args',
      ),
    );
  }

  @action
  void _onPairingCreate(PairingEvent? args) {
    debugPrint('_onPairingCreate $args');
  }

  Future<void> _onSessionAuthRequest(SessionAuthRequest? args) async {
    if (args != null) {
      final SessionAuthPayload authPayload = args.authPayload;
      final jsonPyaload = jsonEncode(authPayload.toJson());

      debugPrint('_onSessionAuthRequest $jsonPyaload');

      final chainKeys = walletKeyService.getKeysForChain(appStore.wallet!);
      final supportedChains = chainKeys.first.chains;
      final supportedMethods = getChainSupportedMethodsOnWalletType(appStore.wallet!.type);

      final newAuthPayload = AuthSignature.populateAuthPayload(
        authPayload: authPayload,
        chains: supportedChains.toList(),
        methods: supportedMethods.toList(),
      );
      final cacaoRequestPayload = CacaoRequestPayload.fromSessionAuthPayload(
        newAuthPayload,
      );

      final List<Map<String, dynamic>> formattedMessages = [];
      for (var chain in newAuthPayload.chains) {
        final chainKeys = walletKeyService.getKeysForChain(appStore.wallet!);
        final iss = 'did:pkh:$chain:${chainKeys.first.publicKey}';

        final message = _walletKit.formatAuthMessage(
          iss: iss,
          cacaoPayload: cacaoRequestPayload,
        );
        formattedMessages.add({iss: message});
      }

      final WCBottomSheetResult result = (await _bottomSheetHandler.queueBottomSheet(
            widget: WCSessionAuthRequestWidget(
              child: WCConnectionRequestWidget(
                sessionAuthPayload: newAuthPayload,
                verifyContext: args.verifyContext,
                requester: args.requester,
                walletKeyService: walletKeyService,
                walletKit: _walletKit,
                appStore: appStore,
              ),
            ),
          ) as WCBottomSheetResult?) ??
          WCBottomSheetResult.reject;

      if (result != WCBottomSheetResult.reject) {
        final chainKeys = walletKeyService.getKeysForChain(appStore.wallet!);
        final privateKey = '0x${chainKeys.first.privateKey}';
        final credentials = EthPrivateKey.fromHex(privateKey);
        //
        final messageToSign = formattedMessages.length;
        final count = (result == WCBottomSheetResult.one) ? 1 : messageToSign;
        //
        final List<Cacao> cacaos = [];
        for (var i = 0; i < count; i++) {
          final iss = formattedMessages[i].keys.first;
          final message = formattedMessages[i].values.first as String;

          final signature = credentials.signPersonalMessageToUint8List(
            Uint8List.fromList(message.codeUnits),
          );
          final hexSignature = bytesToHex(signature, include0x: true);

          cacaos.add(
            AuthSignature.buildAuthObject(
              requestPayload: cacaoRequestPayload,
              signature: CacaoSignature(t: CacaoSignature.EIP191, s: hexSignature),
              iss: iss,
            ),
          );
        }
        //
        try {
          final session = await _walletKit.approveSessionAuthenticate(
            id: args.id,
            auths: cacaos,
          );

          debugPrint('_onSessionAuthRequest - approveSessionAuthenticate $session');

          MethodsUtils.handleRedirect(
            session.topic,
            session.session?.peer.metadata.redirect,
            '',
            true,
          );
        } on ReownSignError catch (error) {
          MethodsUtils.handleRedirect(
            args.topic,
            args.requester.metadata.redirect,
            error.message,
          );
        }
      } else {
        final error = Errors.getSdkError(Errors.USER_REJECTED_AUTH);
        await _walletKit.rejectSessionAuthenticate(
          id: args.id,
          reason: error.toSignError(),
        );
        MethodsUtils.handleRedirect(
          args.topic,
          args.requester.metadata.redirect,
          error.message,
        );
      }
    }
  }

  @action
  Future<void> deletePairing({required String topic}) async {
    final topicSessions = sessions.where((element) => element.pairingTopic == topic);

    await _walletKit.core.pairing.disconnect(topic: topic);
    for (var session in topicSessions) {
      await _walletKit.disconnectSession(
        topic: session.topic,
        reason: Errors.getSdkError(Errors.USER_DISCONNECTED).toSignError(),
      );
    }
  }

  @action
  Future<void> disconnectSession({required String topic}) async {
    await walletKit.disconnectSession(
      topic: topic,
      reason: Errors.getSdkError(Errors.USER_DISCONNECTED).toSignError(),
    );
  }

  @action
  Future<void> updateSession({
    required String topic,
    required Map<String, Namespace> namespaces,
  }) async {
    await walletKit.updateSession(topic: topic, namespaces: namespaces);
  }

  @action
  Future<void> extendSession({required String topic}) async {
    await walletKit.extendSession(topic: topic);
  }

  @action
  Future<void> pairWithUri(Uri uri) async {
    try {
      debugPrint('pairWithUri - Pairing with URI: $uri');
      await _walletKit.pair(uri: uri);
    } on ReownSignError catch (e) {
      _bottomSheetHandler.queueBottomSheet(
        isModalDismissible: true,
        widget: BottomSheetMessageDisplayWidget(message: e.message),
      );
    } catch (e) {
      _bottomSheetHandler.queueBottomSheet(
        isModalDismissible: true,
        widget: BottomSheetMessageDisplayWidget(message: e.toString()),
      );
    }
  }

  @action
  void _refreshPairings() {
    debugPrint('_refreshPairings - Refreshing pairings');

    pairings.clear();

    final allPairings = _walletKit.pairings.getAll();

    final keyForWallet = getKeyForStoringTopicsForWallet();

    if (keyForWallet.isEmpty) return;

    final currentTopicsForWallet = getPairingTopicsForWallet(keyForWallet);

    final filteredPairings = allPairings.where(
      (pairing) {
        bool isInCurrentTopics = currentTopicsForWallet.contains(pairing.topic);
        bool isActive = pairing.active;

        return isInCurrentTopics && isActive;
      },
    ).toList();

    pairings.addAll(filteredPairings);
  }

  @action
  List<SessionData> getSessionsForPairingInfo(PairingInfo pairing) {
    return sessions.where((element) => element.pairingTopic == pairing.topic).toList();
  }

  String getKeyForStoringTopicsForWallet() {
    List<ChainKeyModel> chainKeys = walletKeyService.getKeysForChain(appStore.wallet!);

    if (chainKeys.isEmpty) {
      return '';
    }

    final keyForPairingTopic =
        PreferencesKey.walletConnectPairingTopicsListForWallet(chainKeys.first.publicKey);

    return keyForPairingTopic;
  }

  List<String> getPairingTopicsForWallet(String key) {
    // Get the JSON-encoded string from shared preferences
    final jsonString = sharedPreferences.getString(key);

    // If the string is null, return an empty list
    if (jsonString == null) {
      return [];
    }

    // Decode the JSON string to a list of strings
    final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;

    // Cast each item to a string
    return jsonList.map((item) => item as String).toList();
  }

  Future<void> savePairingTopicToLocalStorage(String pairingTopic) async {
    // Get key specific to the current wallet
    final key = getKeyForStoringTopicsForWallet();

    if (key.isEmpty) return;

    // Get all pairing topics attached to this key
    final pairingTopicsForWallet = getPairingTopicsForWallet(key);

    bool isPairingTopicAlreadySaved = pairingTopicsForWallet.contains(pairingTopic);
    debugPrint('Is Pairing Topic Saved: $isPairingTopicAlreadySaved');

    if (!isPairingTopicAlreadySaved) {
      // Update the list with the most recent pairing topic
      pairingTopicsForWallet.add(pairingTopic);

      // Convert the list of updated pairing topics to a JSON-encoded string
      final jsonString = jsonEncode(pairingTopicsForWallet);

      // Save the encoded string to shared preferences
      await sharedPreferences.setString(key, jsonString);
    }
  }
}
