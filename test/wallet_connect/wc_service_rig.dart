import "dart:async";
import "dart:collection";
import "dart:convert";

import "package:cake_wallet/di.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/models/bottom_sheet_queue_item_model.dart";
import "package:cake_wallet/src/screens/wallet_connect/services/bottom_sheet_service.dart";
import "package:cake_wallet/src/screens/wallet_connect/services/key_service/chain_key_model.dart";
import "package:cake_wallet/src/screens/wallet_connect/services/key_service/wallet_connect_key_service.dart";
import "package:cake_wallet/src/screens/wallet_connect/services/walletkit_service.dart";
import "package:cake_wallet/src/screens/wallet_connect/utils/method_utils.dart";
import "package:cake_wallet/src/screens/wallet_connect/widgets/bottom_sheet/bottom_sheet_message_display_widget.dart";
import "package:cake_wallet/src/screens/wallet_connect/widgets/wc_signing_request_sheet.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/node.dart";
import "package:cw_core/transaction_history.dart";
import "package:cw_core/transaction_info.dart";
import "package:cw_core/transaction_priority.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/services.dart";
import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:reown_core/connectivity/i_connectivity.dart";
import "package:reown_core/relay_client/i_relay_client.dart";
import "package:reown_core/verify/i_verify.dart";
import "package:reown_walletkit/reown_walletkit.dart";

typedef AnyWallet = WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo>;

class RigWallet extends Fake implements AnyWallet {
  RigWallet(
    this.name, {
    required this.address,
    required this.privateKey,
    required this.chains,
    this.type = WalletType.ethereum,
  });

  @override
  final String name;

  @override
  final WalletType type;

  final String address;

  @override
  final String privateKey;

  final List<String> chains;
}

class RigKeyService implements WalletConnectKeyService {
  int privateKeyReads = 0;

  @override
  List<ChainKeyModel> getKeys(AnyWallet wallet) => getKeysForChain(wallet);

  @override
  List<ChainKeyModel> getKeysForChain(AnyWallet wallet) {
    final rigWallet = wallet as RigWallet;
    return [ChainKeyModel(chains: rigWallet.chains, publicKey: rigWallet.address)];
  }

  @override
  String getPrivateKey(AnyWallet wallet) {
    privateKeyReads += 1;
    return (wallet as RigWallet).privateKey;
  }
}

class RigSettingsStore extends Fake implements SettingsStore {
  @override
  FiatCurrency fiatCurrency = FiatCurrency.usd;

  @override
  Node getCurrentNode(WalletType walletType, {int? chainId}) =>
      Node(uri: "node-for-chain-$chainId.invalid", type: walletType);

  @override
  TransactionPriority? getPriority(WalletType walletType, {int? chainId}) => null;
}

class RigAppStore extends Fake implements AppStore {
  @override
  AnyWallet? wallet;

  @override
  final SettingsStore settingsStore = RigSettingsStore();
}

class _RigWalletKitService extends Fake implements WalletKitService {
  _RigWalletKitService(this.walletKit);

  @override
  final ReownWalletKit walletKit;
}

class RigSheets extends Fake implements BottomSheetService {
  final shown = <Widget>[];
  final answers = Queue<FutureOr<WCBottomSheetResult?>>();

  @override
  final ValueNotifier<BottomSheetQueueItemModel?> currentSheet = ValueNotifier(null);

  final _signingSheetShown = StreamController<WCSigningRequestSheet>.broadcast();

  Future<WCSigningRequestSheet> get nextSigningSheet => _signingSheetShown.stream.first;

  Iterable<WCSigningRequestSheet> get signingSheets => shown.whereType<WCSigningRequestSheet>();

  List<String> get messages =>
      shown.whereType<BottomSheetMessageDisplayWidget>().map((sheet) => sheet.message).toList();

  Iterable<GoBackModalWidget> get goBackModals => shown.whereType<GoBackModalWidget>();

  final dismissibleByWidget = <Widget, bool>{};

  final unscripted = <WCSigningRequestSheet>[];

  @override
  Future<dynamic> queueBottomSheet({
    required Widget widget,
    bool isModalDismissible = false,
    int closeAfter = 0,
  }) async {
    shown.add(widget);
    dismissibleByWidget[widget] = isModalDismissible;
    if (widget is! WCSigningRequestSheet) {
      return null;
    }

    _signingSheetShown.add(widget);
    if (answers.isEmpty) {
      unscripted.add(widget);
      return WCBottomSheetResult.reject;
    }

    return answers.removeFirst();
  }

  void reset() {
    shown.clear();
    answers.clear();
    unscripted.clear();
    dismissibleByWidget.clear();
  }
}

class RigRelay extends Fake implements IRelayClient {
  final published = <({String topic, String message})>[];

  void Function(String topic, String message)? onPublished;

  @override
  final Event<MessageEvent> onRelayClientMessage = Event<MessageEvent>();

  @override
  final Event<MessageEvent> onLinkModeMessage = Event<MessageEvent>();

  @override
  final Event<EventArgs> onRelayClientConnect = Event<EventArgs>();

  @override
  final Event<EventArgs> onRelayClientDisconnect = Event<EventArgs>();

  @override
  final Event<ErrorEvent> onRelayClientError = Event<ErrorEvent>();

  @override
  final Event<SubscriptionEvent> onSubscriptionCreated = Event<SubscriptionEvent>();

  @override
  final Event<SubscriptionDeletionEvent> onSubscriptionDeleted = Event<SubscriptionDeletionEvent>();

  @override
  final Event<EventArgs> onSubscriptionSync = Event<EventArgs>();

  @override
  final Event<EventArgs> onSubscriptionResubscribed = Event<EventArgs>();

  @override
  bool isConnected = true;

  int connectCalls = 0;
  int disconnectCalls = 0;

  @override
  Future<void> init() async {}

  @override
  Future<void> connect({String? relayUrl}) async {
    connectCalls += 1;
    isConnected = true;
  }

  @override
  Future<void> disconnect() async {
    disconnectCalls += 1;
    isConnected = false;
  }

  @override
  Future<void> publish({
    required String topic,
    required String message,
    required PublishOptions options,
  }) async {
    published.add((topic: topic, message: message));
    onPublished?.call(topic, message);
  }

  @override
  Future<String> subscribe({required SubscribeOptions options}) async => options.topic;

  @override
  Future<void> unsubscribe({required String topic}) async {}
}

class _SwitchableConnectivity implements IConnectivity {
  @override
  final ValueNotifier<bool> isOnline = ValueNotifier(true);

  @override
  Future<void> init() async {}

  @override
  Future<void> dispose() async {}
}

class _NoAttestation implements IVerify {
  @override
  Future<void> init({String? verifyUrl}) async {}

  @override
  Future<AttestationResponse?> resolve({required String attestationId}) async => null;

  @override
  Validation getValidation(AttestationResponse? attestation, Uri? metadataUri) =>
      Validation.UNKNOWN;
}

class WireReply {
  WireReply(Map<String, dynamic> json)
    : id = json["id"] as int,
      result = json["result"],
      errorCode = (json["error"] as Map<String, dynamic>?)?["code"] as int?,
      errorMessage = (json["error"] as Map<String, dynamic>?)?["message"] as String?;

  final int id;
  final Object? result;
  final int? errorCode;
  final String? errorMessage;

  @override
  String toString() => "WireReply(id: $id, result: $result, error: $errorCode $errorMessage)";
}

class WcServiceRig {
  WcServiceRig._(this.kit, this._relay);

  static const dappUrl = "https://dapp.example";
  static const dappRedirect = "dappscheme://return";

  static final sheets = RigSheets();

  static Future<WcServiceRig> start() async {
    S.current = const S();

    final relay = RigRelay();
    final core = ReownCore(projectId: "rig", memoryStore: true)
      ..relayClient = relay
      ..connectivity = _SwitchableConnectivity()
      ..verify = _NoAttestation();
    final kit = ReownWalletKit(
      core: core,
      metadata: const PairingMetadata(name: "rig", description: "rig", url: "", icons: []),
    );

    await core.storage.init();
    await core.crypto.init();
    await core.expirer.init();
    await core.pairing.init();
    await core.linkModeStore.init();
    await kit.reOwnSign.init();

    final rig = WcServiceRig._(kit, relay);
    relay.onPublished = rig._acknowledge;

    await getIt.reset();
    sheets.reset();
    getIt
      ..registerSingleton<BottomSheetService>(sheets)
      ..registerSingleton<AppStore>(rig.appStore)
      ..registerSingleton<WalletKitService>(_RigWalletKitService(kit));

    return rig;
  }

  final ReownWalletKit kit;
  final RigRelay _relay;
  final appStore = RigAppStore();
  final keyService = RigKeyService();

  final openedUrls = <String>[];

  bool doesDappAcknowledge = true;

  int _nextRequestId = 1000;

  set isOnline(bool isOnline) => kit.core.connectivity.isOnline.value = isOnline;

  Future<void> _acknowledge(String topic, String message) async {
    final decoded = await kit.core.crypto.decode(topic, message);
    final json = jsonDecode(decoded!) as Map<String, dynamic>;
    if (!json.containsKey("method") || !doesDappAcknowledge) {
      return;
    }

    final ack = await kit.core.crypto.encode(topic, {
      "id": json["id"],
      "jsonrpc": "2.0",
      "result": true,
    });
    _broadcast(topic, ack!);
  }

  void _broadcast(String topic, String message) => _relay.onRelayClientMessage.broadcast(
    MessageEvent(topic, message, DateTime.now().millisecondsSinceEpoch, TransportType.relay),
  );

  Future<void> addSession(
    String topic, {
    required List<String> accounts,
    List<String> methods = const [],
    String? redirect,
  }) async {
    await kit.core.crypto.setSymKey(
      kit.core.crypto.getUtils().generateRandomBytes32(),
      overrideTopic: topic,
    );
    final expiry = ReownCoreUtils.calculateExpiry(ReownConstants.SEVEN_DAYS);
    final namespaces = <String, Namespace>{};
    for (final account in accounts) {
      final namespace = account.split(":").first;
      final existing = namespaces[namespace];
      namespaces[namespace] = Namespace(
        accounts: [...?existing?.accounts, account],
        methods: methods,
        events: const ["chainChanged", "accountsChanged"],
      );
    }

    await kit.sessions.set(
      topic,
      SessionData(
        topic: topic,
        pairingTopic: "pairing-of-$topic",
        relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
        expiry: expiry,
        acknowledged: true,
        controller: "rig-controller",
        namespaces: namespaces,
        self: const ConnectionMetadata(
          publicKey: "rig-self",
          metadata: PairingMetadata(name: "rig", description: "rig", url: "", icons: []),
        ),
        peer: ConnectionMetadata(
          publicKey: "rig-peer",
          metadata: PairingMetadata(
            name: "Example dApp",
            description: "",
            url: dappUrl,
            icons: const [],
            redirect: redirect == null ? null : Redirect(native: redirect),
          ),
        ),
      ),
    );
    await kit.core.expirer.set(topic, expiry);
  }

  Future<int> deliver(String topic, String chainId, String method, Object? params) async =>
      (await deliverTogether(topic, chainId, method, [params])).single;

  Future<List<int>> deliverTogether(
    String topic,
    String chainId,
    String method,
    List<Object?> paramsPerRequest,
  ) async {
    final ids = <int>[];
    final messages = <String>[];
    for (final params in paramsPerRequest) {
      final id = _nextRequestId++;
      final message = await kit.core.crypto.encode(topic, {
        "id": id,
        "jsonrpc": "2.0",
        "method": MethodConstants.WC_SESSION_REQUEST,
        "params": {
          "request": {"method": method, "params": params},
          "chainId": chainId,
        },
      });
      ids.add(id);
      messages.add(message!);
    }

    for (final message in messages) {
      _broadcast(topic, message);
    }

    return ids;
  }

  Future<void> settle() async {
    int activity() => _relay.published.length + sheets.shown.length + openedUrls.length;

    var seen = -1;
    while (seen != activity()) {
      seen = activity();
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
  }

  Future<List<WireReply>> replies(String topic) async {
    final replies = <WireReply>[];
    for (final entry in _relay.published.where((entry) => entry.topic == topic)) {
      final decoded = await kit.core.crypto.decode(topic, entry.message);
      final json = jsonDecode(decoded!) as Map<String, dynamic>;
      if (!json.containsKey("method")) {
        replies.add(WireReply(json));
      }
    }

    return replies;
  }

  Future<List<String>> publishedKinds(String topic) async {
    final kinds = <String>[];
    for (final entry in _relay.published.where((entry) => entry.topic == topic)) {
      final decoded = await kit.core.crypto.decode(topic, entry.message);
      final json = jsonDecode(decoded!) as Map<String, dynamic>;
      kinds.add(json["method"] as String? ?? "reply");
    }

    return kinds;
  }

  Future<List<Map<String, dynamic>>> walletRequests(String topic) async {
    final requests = <Map<String, dynamic>>[];
    for (final entry in _relay.published.where((entry) => entry.topic == topic)) {
      final decoded = await kit.core.crypto.decode(topic, entry.message);
      final json = jsonDecode(decoded!) as Map<String, dynamic>;
      if (json.containsKey("method")) {
        requests.add(json);
      }
    }

    return requests;
  }

  Future<void> expireRequest(int requestId) =>
      kit.core.expirer.set(requestId.toString(), ReownCoreUtils.calculateExpiry(-1));

  void recordOpenedUrls({bool canOpen = true}) {
    const channel = MethodChannel("plugins.flutter.io/url_launcher");
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async {
        if (call.method == "canLaunch") {
          return canOpen;
        }
        if (call.method == "launch") {
          openedUrls.add((call.arguments as Map)["url"] as String);
          return canOpen;
        }
        return null;
      },
    );
  }
}
