// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:developer';

import 'package:cake_wallet/generated/i18n.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:eth_sig_util/util/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';

import 'package:cake_wallet/core/wallet_connect/wc_bottom_sheet_service.dart';
import 'package:cake_wallet/ethereum/ethereum.dart';
import 'package:cake_wallet/src/screens/wallet_connect/models/session_request_model.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/connection_request_widget.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/modals/web3_request_modal.dart';
import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallet_connect_v2/wallet_connect_v2.dart';
import 'package:web3dart/web3dart.dart';

import '../../themes/extensions/cake_text_theme.dart';

part 'wallet_connect_service.g.dart';

class WalletConnectService = WalletConnectServiceBase with _$WalletConnectService;

abstract class WalletConnectServiceBase with Store {
  late final WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> wallet;
  final BottomSheetService _bottomSheetHandler;

  static const projectId = '419b7919bdfe48515a1107e949ec811a';

  late WalletConnectV2 _walletConnectV2Plugin;
  late AppMetadata _walletMetadata;

  @observable
  ObservableList<Session> sessions;

  String? _privateKey;
  String? _address;

  String? _dappTopic;

  bool _isInitiated = false;
  bool _isForeground = true;

  WalletConnectServiceBase(
    this.wallet,
    this._bottomSheetHandler,
  ) : sessions = ObservableList<Session>();

  static const pSign = 'personal_sign';
  static const eSign = 'eth_sign';
  static const eSignTransaction = 'eth_signTransaction';
  static const eSignTypedData = 'eth_signTypedData';
  static const eSignTypedDataV4 = 'eth_signTypedData_v4';
  static const eSendTransaction = 'eth_sendTransaction';

  @action
  Future<void> createAndInitialize() async {
    _walletConnectV2Plugin = WalletConnectV2();

    _walletMetadata = AppMetadata(
      name: 'Cake Wallet',
      url: 'https://cakewallet.com',
      description: 'Cake Wallet by CakeLabs',
      icons: ['https://cakewallet.com/assets/image/cake_logo.avif'],
    );

    initializeConfigurations();
  }

  @action
  void initializeConfigurations() {
    _walletConnectV2Plugin.onConnectionStatus = onConnectionStatusEvent;

    _walletConnectV2Plugin.onSessionProposal = onSessionProposalEvent;

    _walletConnectV2Plugin.onSessionSettle = onSessionSettleEvent;

    _walletConnectV2Plugin.onSessionRejection = onSessionRejectionEvent;

    _walletConnectV2Plugin.onSessionResponse = onSessionResponseEvent;

    _walletConnectV2Plugin.onSessionUpdate = onSessionUpdateEvent;

    _walletConnectV2Plugin.onSessionDelete = onSessionDeleteEvent;

    _walletConnectV2Plugin.onEventError = onEventError;

    _walletConnectV2Plugin.onSessionRequest = onSessionRequestEvent;
  }

  @action
  Future<void> initWalletConnect() async {
    await _initDapp();
    await _initWallet();
    await _walletConnectV2Plugin.init(projectId: projectId, appMetadata: _walletMetadata);
    await _walletConnectV2Plugin.connect();
  }

  @action
  Future<void> createPairing(String uri) async {
    try {
      await _walletConnectV2Plugin.pair(uri: uri);
      await _refreshSessions();
    } catch (e) {
      log('Error while creating a pairing connection: $e');
      rethrow;
    }
  }

//! Session related events
  Future<void> onConnectionStatusEvent(bool isConnected) async {
    debugPrint('---: CONNECTED: $isConnected');
    if (_isInitiated) {
      if (!isConnected && _isForeground) {
        _walletConnectV2Plugin.connect();
      }
    } else {
      if (isConnected) {
        _isInitiated = true;
        _refreshSessions();
      }
    }
  }

  Future<void> onSessionProposalEvent(SessionProposal proposal) async {
    if (proposal.namespaces.length != 1 ||
        !proposal.namespaces.containsKey('eip155') ||
        proposal.namespaces['eip155']?.chains == null) {
      await _walletConnectV2Plugin.rejectSession(proposalId: proposal.id);
      await _bottomSheetHandler.queueBottomSheet(
        isModalDismissible: true,
        widget: ErrorWidgetDisplay(errorText: 'Please choose Ethereum networks only to do test!'),
      );
      return;
    }

    final Widget modalWidget = Web3RequestModal(
      child: ConnectionRequestWidget(
        sessionProposal: SessionRequestModel(request: proposal),
      ),
    );

    // show the bottom sheet
    final bool? isApprove = await _bottomSheetHandler.queueBottomSheet(
      widget: modalWidget,
    ) as bool?;

    if (isApprove == true) {
      try {
        final requiredMethods = proposal.namespaces['eip155']?.methods ?? <String>[];
        final requiredEvents = proposal.namespaces['eip155']?.events ?? <String>[];

        final optionalMethods = proposal.optionalNamespaces?['eip155']?.methods ?? <String>[];
        final optionalEvents = proposal.optionalNamespaces?['eip155']?.events ?? <String>[];

        final List<String> chainList = [];
        chainList.addAll(proposal.namespaces['eip155']!.chains!);
        chainList.addAll(proposal.optionalNamespaces!['eip155']!.chains!);
        final chainIDs = chainList.toSet().toList();

        final approval = SessionApproval(id: proposal.id, namespaces: {
          'eip155': SessionNamespace(
              accounts: chainIDs.map((e) => '$e:$_address').toList(),
              methods: requiredMethods.isNotEmpty
                  ? <String>{...requiredMethods, ...optionalMethods}.toList()
                  : [],
              events: requiredEvents.isNotEmpty
                  ? <String>{...requiredEvents, ...optionalEvents}.toList()
                  : [])
        });

        print(approval.toJson());

        _walletConnectV2Plugin.approveSession(approval: approval);
      } catch (e) {
        _bottomSheetHandler.queueBottomSheet(
          isModalDismissible: true,
          widget: ErrorWidgetDisplay(errorText: 'Approve session error: ${e.toString()}'),
        );
      }
    } else {
      try {
        _walletConnectV2Plugin.rejectSession(proposalId: proposal.id);
      } catch (e) {
        _bottomSheetHandler.queueBottomSheet(
          isModalDismissible: true,
          widget: ErrorWidgetDisplay(errorText: 'Reject session error: ${e.toString()}'),
        );
      }
    }
  }

  Future<void> onSessionSettleEvent(Session session) async {
    await _refreshSessions();
    _dappTopic = session.topic;
    _setDappTopic(_dappTopic!);
  }

  Future<void> onSessionRejectionEvent(String topic) async {
    await _refreshSessions();
  }

  Future<void> onSessionResponseEvent(SessionResponse response) async {
    _bottomSheetHandler.queueBottomSheet(
      isModalDismissible: true,
      widget: ErrorWidgetDisplay(
          errorText: '${response.results is String ? 'Signature' : 'Error'}: ${response.results}'),
    );
  }

  void onSessionUpdateEvent(String _) {
    _refreshSessions();
  }

  void onSessionDeleteEvent(String _) {
    _refreshSessions();
  }

  void onEventError(code, message) {
    _bottomSheetHandler.queueBottomSheet(
      isModalDismissible: true,
      widget: ErrorWidgetDisplay(errorText: 'code: $code | message: $message'),
    );
  }

//! Subscription related methods
  @action
  Future<void> eSignTransactionEvent(SessionRequest request) async {
    try {
      final object = request.params.first as Map;
      final gasLimit =
          object['gasLimit'] != null ? BigInt.tryParse(object['gasLimit'] as String) : null;
      final gasPrice = object['gasPrice'] != null
          ? EtherAmount.fromBigInt(
              EtherUnit.wei, (BigInt.tryParse(object['gasPrice'] as String) ?? BigInt.zero))
          : null;
      final value = object['value'] != null
          ? EtherAmount.fromBigInt(
              EtherUnit.wei, (BigInt.tryParse(object['value'] as String) ?? BigInt.zero))
          : null;
      final from =
          object['from'] != null ? EthereumAddress.fromHex(object['from'] as String) : null;
      final to = object['to'] != null ? EthereumAddress.fromHex(object['to'] as String) : null;
      final data = object['data'] != null ? hexToBytes(object['data'] as String) : null;
      final tx = Transaction(
        from: from,
        data: data,
        value: value,
        maxGas: gasLimit?.toInt(),
        to: to,
        gasPrice: gasPrice,
      );
      final client =
          Web3Client('https://mainnet.infura.io/v3/51716d2096df4e73bec298680a51f0c5', Client());

      final signature = await client.signTransaction(EthPrivateKey.fromHex(_privateKey ?? ''), tx);

      await _walletConnectV2Plugin.approveRequest(
        topic: request.topic,
        requestId: request.id,
        result: bytesToHex(signature, include0x: true),
      );
    } catch (e) {
      _bottomSheetHandler.queueBottomSheet(
        isModalDismissible: true,
        widget: ErrorWidgetDisplay(errorText: 'Sign error: ${e.toString()}'),
      );
    }
  }

  @action
  Future<void> ethSignEvent(SessionRequest request) async {
    try {
      String message = request.params.firstWhere((element) => element != _address) as String;
      final signature =
          EthSigUtil.signPersonalMessage(message: hexToBytes(message), privateKey: _privateKey);
      await _walletConnectV2Plugin.approveRequest(
          topic: request.topic, requestId: request.id, result: signature);
    } catch (e) {
      _bottomSheetHandler.queueBottomSheet(
        isModalDismissible: true,
        widget: ErrorWidgetDisplay(errorText: 'Approve error: ${e.toString()}'),
      );
    }
  }

  @action
  Future<void> ethSignTypedDataEvent(SessionRequest request) async {
    try {
      final message = request.params.firstWhere((element) => element != _address);
      final jsonData = message is Map ? jsonEncode(message) : message;
      final signature = EthSigUtil.signTypedData(
        jsonData: jsonData.toString(),
        privateKey: _privateKey,
        version: TypedDataVersion.V4,
      );
      await _walletConnectV2Plugin.approveRequest(
          topic: request.topic, requestId: request.id, result: signature);
    } catch (e) {
      _bottomSheetHandler.queueBottomSheet(
        isModalDismissible: true,
        widget: ErrorWidgetDisplay(errorText: 'Approve request error: ${e.toString()}'),
      );
    }
  }

  @action
  Future<void> onUnsupportedMethodEvent(SessionRequest request) async {
    _walletConnectV2Plugin.rejectRequest(topic: request.topic, requestId: request.id);
    _bottomSheetHandler.queueBottomSheet(
      isModalDismissible: true,
      widget: ErrorWidgetDisplay(errorText: 'Unhandled method ${request.method}'),
    );
  }

  @action
  Future<void> onSessionRequestApproved(SessionRequest request) async {
    switch (request.method) {
      case eSendTransaction:
      case eSignTransaction:
        return eSignTransactionEvent(request);
      case pSign:
      case eSign:
        return ethSignEvent(request);
      case eSignTypedData:
      case eSignTypedDataV4:
        return ethSignTypedDataEvent(request);
      default:
        return onUnsupportedMethodEvent(request);
    }
  }

  @action
  Future<void> onSessionRequestRejected(SessionRequest request) async {
    try {
      await _walletConnectV2Plugin.rejectRequest(topic: request.topic, requestId: request.id);
    } catch (e) {
      _bottomSheetHandler.queueBottomSheet(
        isModalDismissible: true,
        widget: ErrorWidgetDisplay(errorText: 'Reject request error: ${e.toString()}'),
      );
    }
  }

  @action
  Future<void> onSessionRequestEvent(SessionRequest request) async {
    final Widget modalWidget = Web3RequestModal(
      child: ConnectionRequestWidget(
        sessionProposal: SessionRequestModel(sessionRequest: request),
      ),
    );

    // show the bottom sheet
    final bool? isApprove = await _bottomSheetHandler.queueBottomSheet(
      widget: modalWidget,
    ) as bool?;

    if (isApprove == true) {
      await onSessionRequestApproved(request);
    } else {
      await onSessionRequestRejected(request);
    }
  }

  @action
  Future<void> _refreshSessions() async {
    try {
      final newSessions = await _walletConnectV2Plugin.getActivatedSessions();
      if (newSessions.where((element) => element.topic == _dappTopic).toList().isEmpty) {
        _setDappTopic(_dappTopic = null);
      }
      sessions.clear();
      sessions.addAll(newSessions);
    } catch (e) {
      _bottomSheetHandler.queueBottomSheet(
        isModalDismissible: true,
        widget: ErrorWidgetDisplay(errorText: 'Refresh sessions error: ${e.toString()}'),
      );
    }
  }

  @action
  Future<void> deleteSession(Session session) async {
    await _walletConnectV2Plugin.disconnectSession(
      topic: session.topic,
    );
    _refreshSessions();
  }

  @action
  Future<void> _initWallet() async {
    _privateKey = ethereum!.getPrivateKey(wallet);
    _address = ethereum!.getPublicKey(wallet);
  }

  @action
  Future<void> _initDapp() async {
    final sp = await SharedPreferences.getInstance();
    _dappTopic = sp.getString('dapp_topic');
  }

  @action
  Future<bool> _setDappTopic(String? topic) async {
    final sp = await SharedPreferences.getInstance();
    if (topic != null) {
      return sp.setString('dapp_topic', topic);
    }
    return sp.remove('dapp_topic');
  }

  @action
  Future<void> dispose() async {
    await _walletConnectV2Plugin.dispose();
  }
}

class ErrorWidgetDisplay extends StatelessWidget {
  final String errorText;

  const ErrorWidgetDisplay({super.key, required this.errorText});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.current.error,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Text(
          errorText,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
