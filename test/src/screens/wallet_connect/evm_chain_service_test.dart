import "package:cake_wallet/di.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/services/bottom_sheet_service.dart";
import "package:cake_wallet/src/screens/wallet_connect/services/chain_service/eth/evm_chain_service.dart";
import "package:cake_wallet/src/screens/wallet_connect/services/key_service/chain_key_model.dart";
import "package:cake_wallet/src/screens/wallet_connect/services/key_service/wallet_connect_key_service.dart";
import "package:cake_wallet/src/screens/wallet_connect/services/walletkit_service.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/transaction_history.dart";
import "package:cw_core/transaction_info.dart";
import "package:cw_core/wallet_base.dart";
import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";
import "package:reown_core/store/i_generic_store.dart";
import "package:reown_walletkit/reown_walletkit.dart";

class _MockAppStore extends Mock implements AppStore {}

class _MockWallet extends Mock
    implements WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> {}

class _MockKeyService extends Mock implements WalletConnectKeyService {}

class _MockBottomSheetService extends Mock implements BottomSheetService {}

class _MockWalletKit extends Mock implements ReownWalletKit {}

class _MockWalletKitService extends Mock implements WalletKitService {}

class _MockEvm extends Mock implements EVM {}

class _MockPendingRequests extends Mock implements IGenericStore<SessionRequest> {}

class _MockSessions extends Mock implements ISessions {}

void main() {
  const topic = "session-topic";
  const walletAddress = "0x52908400098527886e0f7030069857d2e4169ee7";
  const opChainId = 10;
  const ethereumChainId = 1;

  late _MockAppStore appStore;
  late _MockWallet wallet;
  late _MockWalletKit walletKit;
  late _MockPendingRequests pendingRequests;
  late EvmChainServiceImpl service;
  final realEvm = evm;

  SessionData session() => SessionData(
        topic: topic,
        pairingTopic: "pairing-topic",
        relay: Relay("irn"),
        expiry: 0,
        acknowledged: true,
        controller: "controller",
        namespaces: {
          "eip155": const Namespace(
            accounts: [
              "eip155:$opChainId:$walletAddress",
              "eip155:$ethereumChainId:$walletAddress"
            ],
            methods: ["eth_sendTransaction"],
            events: [],
          ),
        },
        self: const ConnectionMetadata(
          publicKey: "self",
          metadata: PairingMetadata(name: "Cake", description: "", url: "", icons: []),
        ),
        peer: const ConnectionMetadata(
          publicKey: "peer",
          metadata: PairingMetadata(name: "Dapp", description: "", url: "", icons: []),
        ),
      );

  SessionRequest sendRequest(String chainId) => SessionRequest(
        id: 7,
        topic: topic,
        method: "eth_sendTransaction",
        chainId: chainId,
        params: [
          {"from": walletAddress, "to": walletAddress, "value": "0x0"},
        ],
        verifyContext:
            const VerifyContext(origin: "", validation: Validation.UNKNOWN, verifyUrl: ""),
      );

  Future<JsonRpcError?> respondedError() async {
    final response = verify(
      () => walletKit.respondSessionRequest(topic: topic, response: captureAny(named: "response")),
    ).captured.single as JsonRpcResponse;
    return response.error;
  }

  setUpAll(() {
    S.current = const S();
    registerFallbackValue(const JsonRpcResponse(id: 0));
    registerFallbackValue(const SizedBox());
    registerFallbackValue(_MockWallet());

    final mockEvm = _MockEvm();
    when(() => mockEvm.getWeb3Client(any())).thenReturn(null);
    when(() => mockEvm.getChainInfoByChainId(any())).thenReturn(null);
    evm = mockEvm;
  });

  tearDownAll(() => evm = realEvm);

  setUp(() {
    appStore = _MockAppStore();
    wallet = _MockWallet();
    walletKit = _MockWalletKit();
    pendingRequests = _MockPendingRequests();
    final sessions = _MockSessions();
    final keyService = _MockKeyService();
    final bottomSheetService = _MockBottomSheetService();
    final walletKitService = _MockWalletKitService();

    when(() => appStore.wallet).thenReturn(wallet);
    when(() => wallet.currency).thenReturn(CryptoCurrency.eth);
    when(() => keyService.getKeysForChain(wallet)).thenReturn([
      ChainKeyModel(chains: const [], privateKey: "", publicKey: walletAddress),
    ]);
    when(() => walletKit.pendingRequests).thenReturn(pendingRequests);
    when(() => walletKit.sessions).thenReturn(sessions);
    when(() => sessions.get(topic)).thenReturn(session());
    when(
      () => walletKit.respondSessionRequest(
        topic: any(named: "topic"),
        response: any(named: "response"),
      ),
    ).thenAnswer((_) async {});
    when(
      () => walletKit.redirectToDapp(
        topic: any(named: "topic"),
        redirect: any(named: "redirect"),
      ),
    ).thenAnswer((_) async => true);
    when(
      () => bottomSheetService.queueBottomSheet(
        widget: any(named: "widget"),
        isModalDismissible: any(named: "isModalDismissible"),
        closeAfter: any(named: "closeAfter"),
      ),
    ).thenAnswer((_) async => null);
    when(() => walletKitService.walletKit).thenReturn(walletKit);

    getIt.allowReassignment = true;
    getIt.registerSingleton<BottomSheetService>(bottomSheetService);
    getIt.registerSingleton<WalletKitService>(walletKitService);

    service = EvmChainServiceImpl(
      appStore: appStore,
      wcKeyService: keyService,
      bottomSheetService: bottomSheetService,
      walletKit: walletKit,
    );
  });

  test("a send for the wallet's own added network passes the chain check", () async {
    when(() => wallet.chainId).thenReturn(opChainId);
    when(() => pendingRequests.getAll()).thenReturn([sendRequest("eip155:$opChainId")]);

    await service.ethSendTransaction(topic, null);

    final error = await respondedError();
    expect(error?.message, "The wallet is not connected to a node");
  });

  test("a send for another chain is refused as unsupported, not signed", () async {
    when(() => wallet.chainId).thenReturn(opChainId);
    when(() => pendingRequests.getAll()).thenReturn([sendRequest("eip155:$ethereumChainId")]);

    await service.ethSendTransaction(topic, null);

    final error = await respondedError();
    expect(error?.code, 5100);
    expect(error?.message, contains("eip155:$ethereumChainId"));
  });

  test("the same request is refused or let through by the wallet it reaches", () async {
    when(() => pendingRequests.getAll()).thenReturn([sendRequest("eip155:$opChainId")]);

    when(() => wallet.chainId).thenReturn(ethereumChainId);
    await service.ethSendTransaction(topic, null);
    expect((await respondedError())?.code, 5100);

    when(() => wallet.chainId).thenReturn(opChainId);
    await service.ethSendTransaction(topic, null);
    expect((await respondedError())?.message, "The wallet is not connected to a node");
  });

  test("a chain ID that is not a number is refused as unsupported", () async {
    when(() => wallet.chainId).thenReturn(opChainId);
    when(() => pendingRequests.getAll()).thenReturn([sendRequest("eip155:op")]);

    await service.ethSendTransaction(topic, null);

    expect((await respondedError())?.code, 5100);
  });
}
