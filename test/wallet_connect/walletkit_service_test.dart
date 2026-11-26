import "dart:async";
import "dart:convert";

import "package:cake_wallet/di.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/services/bottom_sheet_service.dart";
import "package:cake_wallet/src/screens/wallet_connect/services/walletkit_service.dart";
import "package:cake_wallet/store/dashboard/fiat_conversion_store.dart";
import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:reown_core/connectivity/i_connectivity.dart";
import "package:reown_core/heartbit/i_heartbeat.dart";
import "package:reown_walletkit/reown_walletkit.dart";
import "package:shared_preferences/shared_preferences.dart";

import "wc_service_rig.dart";

const _key = "ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
const _address = "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266";
const _otherKey = "59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d";
const _otherAddress = "0x70997970c51812dc3a010c7d01b50e0d17dc79c8";
const _symKey = "587d5484ce2a2a6ee3ba1962fdd7e8588e06200c46823bd18fbd67def96ad303";

class _CountingConnectivity implements IConnectivity {
  int disposeCalls = 0;

  @override
  final ValueNotifier<bool> isOnline = ValueNotifier(true);

  @override
  Future<void> init() async {}

  @override
  Future<void> dispose() async => disposeCalls += 1;
}

class _CountingHeartBeat implements IHeartBeat {
  int stopCalls = 0;

  @override
  int interval = 5;

  @override
  final Event<EventArgs> onPulse = Event<EventArgs>();

  @override
  void init() {}

  @override
  void stop() => stopCalls += 1;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sheets = WcServiceRig.sheets;
  late RigAppStore appStore;
  late RigKeyService keyService;
  late WalletKitService service;

  setUp(() async {
    S.current = const S();
    sheets.reset();
    SharedPreferences.setMockInitialValues({});

    appStore = RigAppStore()
      ..wallet = RigWallet("Wallet A", address: _address, privateKey: _key, chains: ["eip155:1"]);
    keyService = RigKeyService();
    service = WalletKitService(
      sheets,
      keyService,
      appStore,
      await SharedPreferences.getInstance(),
      FiatConversionStore(appStore.settingsStore),
    )..create();
  });

  Uri pairingLink(String expiryTimestamp) => Uri.parse(
    "wc:7f6e504bfad60b485450578e05678ed3e8e8c4751d3c6160be17160d63ec90f9@2"
    "?relay-protocol=irn&symKey=$_symKey&expiryTimestamp=$expiryTimestamp",
  );

  group("pairWithUri", () {
    test("a link that has expired is refused with the link message", () async {
      await service.pairWithUri(pairingLink("1"));

      expect(sheets.messages, [S.current.wc_connection_link_failed]);
    });

    test("an expiry beyond what a DateTime holds is not an uncaught error", () async {
      await service.pairWithUri(pairingLink("8640000000001"));

      expect(sheets.messages, hasLength(1));
    });

    test("a link whose query is not valid UTF-8 is refused with the link message", () async {
      final link = Uri.parse(
        "wc:7f6e504bfad60b485450578e05678ed3e8e8c4751d3c6160be17160d63ec90f9@2"
        "?relay-protocol=irn&symKey=%FF",
      );

      await service.pairWithUri(link);

      expect(sheets.messages, [S.current.wc_connection_link_failed]);
    });
  });

  group("a sign-in request", () {
    const requestId = 7001;
    late RigRelay relay;
    late String dappPublicKey;

    setUp(() async {
      relay = RigRelay();
      final core = service.walletKit.core as ReownCore
        ..relayClient = relay
        ..connectivity = _CountingConnectivity();
      await core.storage.init();
      await core.crypto.init();
      await core.expirer.init();
      await core.pairing.init();
      await core.linkModeStore.init();
      await service.walletKit.reOwnSign.init();
      dappPublicKey = await core.crypto.generateKeyPair();

      await getIt.reset();
      getIt
        ..registerSingleton<BottomSheetService>(sheets)
        ..registerSingleton<WalletKitService>(service);
    });

    int secondsFromNow(int seconds) => DateTime.now().millisecondsSinceEpoch ~/ 1000 + seconds;

    Future<void> deliver() async {
      final requester = ConnectionMetadata(
        publicKey: dappPublicKey,
        metadata: const PairingMetadata(
          name: "Example dApp",
          description: "",
          url: "https://dapp.example",
          icons: [],
        ),
      );
      const payload = SessionAuthPayload(
        chains: ["eip155:1"],
        domain: "dapp.example",
        nonce: "32891756",
        aud: "https://dapp.example/login",
        type: "eip4361",
        version: "1",
        iat: "2026-01-01T00:00:00.000Z",
      );
      await service.walletKit.sessionAuthRequests.set(
        requestId.toString(),
        PendingSessionAuthRequest(
          id: requestId,
          pairingTopic: "pairing-topic",
          requester: requester,
          expiryTimestamp: secondsFromNow(3600),
          authPayload: CacaoRequestPayload.fromSessionAuthPayload(payload),
          verifyContext: const VerifyContext(
            origin: "https://dapp.example",
            validation: Validation.UNKNOWN,
            verifyUrl: "",
          ),
        ),
      );
      service.walletKit.onSessionAuthRequest.broadcast(
        SessionAuthRequest(
          id: requestId,
          topic: "pairing-topic",
          requester: requester,
          authPayload: payload,
        ),
      );
    }

    Future<Completer<WCBottomSheetResult?>> openSheet() async {
      final answer = Completer<WCBottomSheetResult?>();
      sheets.answers.add(answer.future);
      final shown = sheets.nextSigningSheet;
      await deliver();
      await shown;
      return answer;
    }

    Future<void> settle() async {
      int activity() => relay.published.length + sheets.shown.length;

      var seen = -1;
      while (seen != activity()) {
        seen = activity();
        await Future<void>.delayed(const Duration(milliseconds: 150));
      }
    }

    Future<List<Map<String, dynamic>>> replies() async {
      final crypto = service.walletKit.core.crypto;
      final replies = <Map<String, dynamic>>[];
      for (final entry in relay.published) {
        final decoded = await crypto.decode(
          entry.topic,
          entry.message,
          options: DecodeOptions(receiverPublicKey: dappPublicKey),
        );
        replies.add(jsonDecode(decoded!) as Map<String, dynamic>);
      }

      return replies;
    }

    test("an approval for the wallet that is still open is signed with its key", () async {
      final answer = await openSheet();
      answer.complete(WCBottomSheetResult.one);
      await settle();

      expect(keyService.privateKeyReads, 1);
      final reply = (await replies()).single;
      expect(reply["id"], requestId);
      expect(reply["error"], isNull);
      final cacaos = (reply["result"] as Map<String, dynamic>)["cacaos"] as List<dynamic>;
      expect(cacaos, hasLength(1));
      expect(sheets.messages, isEmpty);
    });

    test("another wallet opened while the sheet is up is not asked for its key", () async {
      final answer = await openSheet();
      appStore.wallet = RigWallet(
        "Wallet B",
        address: _otherAddress,
        privateKey: _otherKey,
        chains: ["eip155:1"],
      );
      answer.complete(WCBottomSheetResult.one);
      await settle();

      expect(keyService.privateKeyReads, 0);
      expect(sheets.messages, [S.current.wc_request_for_different_wallet]);
      final reply = (await replies()).single;
      expect(reply["result"], isNull);
      expect((reply["error"] as Map<String, dynamic>)["code"], 4100);
    });

    test("a request that expired while the sheet was up is not signed", () async {
      final answer = await openSheet();
      final requests = service.walletKit.sessionAuthRequests;
      await requests.set(
        requestId.toString(),
        requests.get(requestId.toString())!.copyWith(expiryTimestamp: secondsFromNow(-1)),
      );
      answer.complete(WCBottomSheetResult.one);
      await settle();

      expect(keyService.privateKeyReads, 0);
      expect(sheets.messages, [S.current.wc_request_expired]);
      expect(relay.published, isEmpty);
    });

    test("a request the engine no longer holds is not signed", () async {
      final answer = await openSheet();
      await service.walletKit.sessionAuthRequests.delete(requestId.toString());
      answer.complete(WCBottomSheetResult.one);
      await settle();

      expect(keyService.privateKeyReads, 0);
      expect(sheets.messages, [S.current.wc_request_expired]);
      expect(relay.published, isEmpty);
    });
  });

  group("onDispose", () {
    late RigRelay relay;
    late _CountingConnectivity connectivity;
    late _CountingHeartBeat heartbeat;

    setUp(() {
      relay = RigRelay()..isConnected = false;
      connectivity = _CountingConnectivity();
      heartbeat = _CountingHeartBeat();
      (service.walletKit.core as ReownCore)
        ..relayClient = relay
        ..connectivity = connectivity
        ..heartbeat = heartbeat;
      WidgetsBinding.instance.addObserver(service.walletKit);
    });

    tearDown(() => WidgetsBinding.instance.removeObserver(service.walletKit));

    test("a disposed kit does not reconnect its relay when the app resumes", () async {
      await service.onDispose();
      relay.connectCalls = 0;

      WidgetsBinding.instance.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      expect(relay.connectCalls, 0);
    });

    test("a disposed kit stops its heartbeat and its connectivity listener", () async {
      await service.onDispose();

      expect(heartbeat.stopCalls, 1);
      expect(connectivity.disposeCalls, 1);
      expect(relay.disconnectCalls, 1);
    });
  });

  test("onDispose still disconnects a kit whose init never finished", () async {
    final relay = RigRelay();
    (service.walletKit.core as ReownCore).relayClient = relay;

    await service.onDispose();

    expect(relay.disconnectCalls, 1);
  });
}
