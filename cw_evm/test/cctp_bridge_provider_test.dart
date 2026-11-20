import "dart:async";
import "dart:convert";
import "dart:io";
import "dart:typed_data";

import "package:cw_core/amount/money.dart";
import "package:cw_core/bridge_transfer_status.dart";
import "package:cw_core/erc20_token.dart";
import "package:cw_core/utils/proxy_wrapper.dart";
import "package:cw_core/utils/tor/disabled.dart";
import "package:cw_evm/cctp/cctp_bridge_provider.dart";
import "package:cw_evm/cctp/cctp_config.dart";
import "package:cw_evm/contract/oft.dart" show addressToBytes32;
import "package:cw_evm/contract/token_messenger_v2.dart";
import "package:cw_evm/evm_chain_wallet.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hex/hex.dart";

/// Answers every request made inside [answer] with [body] instead of calling Circle.
class _CircleApi {
  _CircleApi(this.body, {this.statusCode = 200});

  final String body;
  final int statusCode;
  final requested = <String>[];

  Future<T> answer<T>(Future<T> Function() request) =>
      HttpOverrides.runZoned(request, createHttpClient: (_) => _CircleApiClient(this));
}

class _CircleApiClient extends Fake implements HttpClient {
  _CircleApiClient(this.circle);

  final _CircleApi circle;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    circle.requested.add(url.toString());
    return _CircleApiRequest(circle);
  }

  @override
  void close({bool force = false}) {}
}

class _CircleApiHeaders extends Fake implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void forEach(void Function(String name, List<String> values) action) {}
}

class _CircleApiRequest extends Fake implements HttpClientRequest {
  _CircleApiRequest(this.circle);

  final _CircleApi circle;

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  int contentLength = -1;

  @override
  bool persistentConnection = true;

  @override
  final HttpHeaders headers = _CircleApiHeaders();

  @override
  Future<void> addStream(Stream<List<int>> stream) => stream.drain<void>();

  @override
  Future<HttpClientResponse> close() async => _CircleApiResponse(circle);
}

class _CircleApiResponse extends StreamView<List<int>> implements HttpClientResponse {
  _CircleApiResponse(_CircleApi circle)
      : statusCode = circle.statusCode,
        super(Stream.value(utf8.encode(circle.body)));

  @override
  final int statusCode;

  @override
  int get contentLength => -1;

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => false;

  @override
  String get reasonPhrase => "";

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  HttpHeaders get headers => _CircleApiHeaders();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Wallet extends Fake implements EVMChainWallet {}

void main() {
  setUpAll(() => CakeTor.instance = CakeTorDisabled());

  test("depositForBurnWithHook call data matches what TokenMessengerV2 accepts", () {
    // Produced by `cast calldata` and executed on a fork of Ethereum mainnet, where the
    // DepositForBurn event showed these exact values.
    const expected = "0x779b432d"
        "0000000000000000000000000000000000000000000000000000000000989680"
        "0000000000000000000000000000000000000000000000000000000000000006"
        "000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb92266"
        "000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
        "0000000000000000000000000000000000000000000000000000000000000000"
        "000000000000000000000000000000000000000000000000000000000000eb53"
        "00000000000000000000000000000000000000000000000000000000000003e8"
        "0000000000000000000000000000000000000000000000000000000000000100"
        "0000000000000000000000000000000000000000000000000000000000000020"
        "636374702d666f72776172640000000000000000000000000000000000000000";

    final dataHex = encodeDepositForBurnWithHook(
      amount: BigInt.from(10000000),
      destinationDomain: CctpConfig.getDomain(8453)!,
      mintRecipient: addressToBytes32("0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"),
      burnToken: CctpConfig.usdcTokenAddressByChainId[1]!,
      destinationCaller: Uint8List(32),
      maxFee: BigInt.from(60243),
      minFinalityThreshold: 1000,
      hookData: HEX.decode(CctpConfig.forwardingHookData),
    );

    expect(dataHex, expected);
  });

  test("quote adds the rounded-up Fast Transfer fee to the medium forward fee", () async {
    // GET https://iris-api.circle.com/v2/burn/USDC/fees/6/0?forward=true on 2026-11-18, with the
    // Standard Transfer entry moved to the front.
    final circle = _CircleApi(
      '[{"finalityThreshold":2000,"minimumFee":0,'
      '"forwardFee":{"low":763612,"med":984192,"high":1204772}},'
      '{"finalityThreshold":1000,"minimumFee":1.3,'
      '"forwardFee":{"low":763612,"med":984192,"high":1204772}}]',
    );

    final usdc = Erc20Token(
      name: "USD Coin",
      symbol: "USDC",
      contractAddress: CctpConfig.usdcTokenAddressByChainId[8453]!,
      decimal: 6,
    );

    final quote = await circle.answer(
      () => CctpBridgeProvider().quoteTransfer(
        wallet: _Wallet(),
        token: usdc,
        sourceChainId: 8453,
        destinationChainId: 1,
        amount: BigInt.from(12345678),
        recipientAddress: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
      ),
    );

    // 1.3 bps of 12.345678 USDC is 1604.93814 subunits.
    expect(quote.fee, Money(BigInt.from(1605 + 984192), usdc));
    expect(quote.receiveAmount, Money(BigInt.from(12345678 - 1605 - 984192), usdc));
    expect(circle.requested, ["https://iris-api.circle.com/v2/burn/USDC/fees/6/0?forward=true"]);
  });

  group("getTransferStatus", () {
    const sourceTxHash = "0x0bb37ef659a57985087247ecc425ada9af687e7bd0aa46d984f66acdd29888ad";

    String messages(String fields) => '{"messages":[{"eventNonce":"0x720ec109",'
        '"cctpVersion":2,$fields}],"sourceTxHash":"$sourceTxHash"}';

    Future<BridgeTransferStatus?> statusOfBaseTransfer(_CircleApi circle) => circle.answer(
          () => CctpBridgeProvider()
              .getTransferStatus(sourceChainId: 8453, sourceTxHash: sourceTxHash),
        );

    test("is delivered once Circle has forwarded the mint", () async {
      // GET https://iris-api.circle.com/v2/messages/6?transactionHash=0x0bb37ef6…888ad on
      // 2026-11-18, without the message, attestation and decoded message.
      final circle = _CircleApi(
        messages(
          '"status":"complete","delayReason":null,"forwardState":"COMPLETE",'
          '"forwardTxHash":"0x8ae844b96b9033c2cb6fd3402c8e4bbc69798fbf74c5f81edf9b79a3ae2aaa70",'
          '"destinationMintTxHash":'
          '"0x8ae844b96b9033c2cb6fd3402c8e4bbc69798fbf74c5f81edf9b79a3ae2aaa70"',
        ),
      );

      final status = (await statusOfBaseTransfer(circle))!;

      expect(status.isDelivered, isTrue);
      expect(status.isFailed, isFalse);
      expect(
        circle.requested,
        ["https://iris-api.circle.com/v2/messages/6?transactionHash=$sourceTxHash"],
      );
    });

    test("is still on its way while the forward is pending", () async {
      final status = (await statusOfBaseTransfer(
        _CircleApi(
          messages(
            '"status":"complete","delayReason":null,"forwardState":"PENDING",'
            '"forwardTxHash":"0x8ae844b96b9033c2cb6fd3402c8e4bbc69798fbf74c5f81edf9b79a3ae2aaa70"',
          ),
        ),
      ))!;

      expect(status.isDelivered, isFalse);
      expect(status.isFailed, isFalse);
    });

    test("is failed when Circle gives up on the forward", () async {
      final status = (await statusOfBaseTransfer(
        _CircleApi(messages('"status":"complete","delayReason":null,"forwardState":"FAILED"')),
      ))!;

      expect(status.isDelivered, isFalse);
      expect(status.isFailed, isTrue);
    });

    test("is unknown until Circle has indexed the burn", () async {
      final circle =
          _CircleApi('{"error":"Message not found for provided parameters"}', statusCode: 404);

      expect(await statusOfBaseTransfer(circle), isNull);
    });
  });
}
