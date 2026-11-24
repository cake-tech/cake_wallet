import "dart:io";

import "package:cake_wallet/core/address_resolver/ens/ens_record.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/utils/proxy_wrapper.dart";
import "package:cw_core/utils/tor/disabled.dart";
import "package:cw_core/wallet_base.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";
import "package:web3dart/json_rpc.dart";
import "package:web3dart/web3dart.dart";

class _MockEvm extends Mock implements EVM {}

class _MockWallet extends Mock implements WalletBase {}

class _MockHttpClient extends Mock implements HttpClient {}

class _WalletNode extends RpcService {
  _WalletNode(this._reply) : super("wallet-node");

  final String _reply;
  var calls = 0;

  @override
  Future<RPCResponse> call(String function, [List<dynamic>? params]) async =>
      RPCResponse(++calls, _reply);
}

void main() {
  late _MockEvm mockEvm;
  late _MockHttpClient httpClient;
  late List<Uri> opened;
  late int closed;

  setUpAll(() {
    CakeTor.instance = CakeTorDisabled();
    registerFallbackValue(_MockWallet());
    registerFallbackValue(Uri());
  });

  setUp(() {
    mockEvm = _MockEvm();
    when(() => mockEvm.getWeb3Client(any())).thenReturn(null);
    evm = mockEvm;

    opened = [];
    closed = 0;
    httpClient = _MockHttpClient();
    when(() => httpClient.openUrl(any(), any())).thenAnswer((call) {
      opened.add(call.positionalArguments[1] as Uri);
      throw const SocketException("offline");
    });
    when(() => httpClient.close(force: any(named: "force"))).thenAnswer((_) => closed++);
  });

  _MockWallet walletOn(int? chainId) {
    final wallet = _MockWallet();
    when(() => wallet.chainId).thenReturn(chainId);
    return wallet;
  }

  Future<String> lookup(WalletBase? wallet) => HttpOverrides.runZoned(
        () => EnsRecord.fetchEnsAddress("vitalik.eth", CryptoCurrency.eth, wallet: wallet),
        createHttpClient: (_) => httpClient,
      );

  void expectOneFallbackRequest() {
    expect(opened, [Uri.parse("https://ethereum-rpc.publicnode.com")]);
    expect(closed, 1);
  }

  test("resolves through the wallet's node when the wallet is on Ethereum mainnet", () async {
    const answer = "0x1111111111111111111111111111111111111111";
    String word(String hex) => hex.padLeft(64, "0");
    final node =
        _WalletNode("0x${word("40")}${word("0")}${word("20")}${word(answer.substring(2))}");
    when(() => mockEvm.getWeb3Client(any())).thenReturn(Web3Client.custom(node));

    expect(await lookup(walletOn(1)), answer);
    expect(node.calls, 1);
    expect(opened, isEmpty);
  });

  test("uses the mainnet fallback while a mainnet wallet has no client", () async {
    expect(await lookup(walletOn(1)), "");
    expectOneFallbackRequest();
  });

  test("uses the mainnet fallback without the EVM proxy", () async {
    evm = null;
    expect(await lookup(walletOn(1)), "");
    expectOneFallbackRequest();
  });

  for (final chainId in [137, 8453, 42161, 56, 4663, null]) {
    test("uses the mainnet fallback for a wallet on chain $chainId", () async {
      expect(await lookup(walletOn(chainId)), "");
      expectOneFallbackRequest();
      verifyNever(() => mockEvm.getWeb3Client(any()));
    });
  }

  test("uses the mainnet fallback without a wallet", () async {
    expect(await lookup(null), "");
    expectOneFallbackRequest();
    verifyNever(() => mockEvm.getWeb3Client(any()));
  });
}
