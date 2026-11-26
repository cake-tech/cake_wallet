import "dart:async";
import "dart:convert";

import "package:blockchain_utils/blockchain_utils.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/services/bottom_sheet_service.dart";
import "package:cake_wallet/src/screens/wallet_connect/services/chain_service/tron/tron_chain_id.dart";
import "package:cake_wallet/src/screens/wallet_connect/services/chain_service/tron/tron_chain_service.dart";
import "package:cake_wallet/tron/tron.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/tron_token.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:on_chain/tron/tron.dart";

import "stubs.dart";
import "wc_service_rig.dart";

const _keyA = "ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
const _keyB = "59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d";

const _topic = "topic-of-tron-wallet-a";
const _methods = ["tron_signMessage", "tron_signTransaction"];

const _usdtContract = "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t";
const _spender = "TDPAjxBZZkzVJ45CJKi7TY7jJHxGgKk5fr";
const _approveSelector = "095ea7b3";

class _RigTron extends Fake implements Tron {
  _RigTron(this.usdt, {this.defaults = const []});

  final TronToken usdt;
  final List<TronToken> defaults;

  @override
  List<CryptoCurrency> getTronTokenCurrencies(WalletBase wallet) => [usdt];

  @override
  List<TronToken> getDefaultTronTokens() => defaults;

  @override
  String getTokenAddress(CryptoCurrency asset) => (asset as TronToken).contractAddress;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final chain = TronChainId.mainnet.chain();
  final addressA = TronPrivateKey(_keyA).publicKey().toAddress().toAddress();
  final addressB = TronPrivateKey(_keyB).publicKey().toAddress().toAddress();
  final sheets = WcServiceRig.sheets;

  late WcServiceRig rig;

  TronToken walletUsdt({bool isEnabled = true, bool isPotentialScam = false}) => TronToken(
    name: "Tether USD",
    symbol: "USDT",
    contractAddress: _usdtContract,
    decimal: 6,
    enabled: isEnabled,
    isPotentialScam: isPotentialScam,
  );

  setUp(() async {
    rig = await WcServiceRig.start();
    tron = _RigTron(walletUsdt());
    rig.appStore.wallet = RigWallet(
      "Tron A",
      address: addressA,
      privateKey: _keyA,
      chains: [chain],
      type: WalletType.tron,
    );

    TronChainService(
      reference: TronChainId.mainnet,
      appStore: rig.appStore,
      wcKeyService: rig.keyService,
      bottomSheetService: sheets,
      walletKit: rig.kit,
    );

    await rig.addSession(_topic, accounts: ["$chain:$addressA"], methods: _methods);
  });

  tearDown(() => expect(sheets.unscripted, isEmpty, reason: "a sheet the test did not expect"));

  Map<String, dynamic> message(String text) => {"message": text, "address": addressA};

  String signatureByA(String text) =>
      "0x${TronPrivateKey(_keyA).signPersonalMessage(utf8.encode(text))}";

  Map<String, dynamic> approveRawData(BigInt amount) => {
    "contract": [
      {
        "parameter": {
          "value": {
            "data":
                "$_approveSelector${TronAddress(_spender).toHex().substring(2).padLeft(64, "0")}"
                "${amount.toRadixString(16).padLeft(64, "0")}",
            "owner_address": TronAddress(addressA).toHex(),
            "contract_address": TronAddress(_usdtContract).toHex(),
          },
          "type_url": "type.googleapis.com/protocol.TriggerSmartContract",
        },
        "type": "TriggerSmartContract",
      },
    ],
    "ref_block_bytes": "885b",
    "ref_block_hash": "baa1c278fd0a309f",
    "expiration": 1745849082000,
    "fee_limit": 200000000,
    "timestamp": 1745849022978,
  };

  Map<String, dynamic> approve(BigInt amount) => {
    "address": addressA,
    "transaction": {"raw_data": approveRawData(amount)},
  };

  final unlimited = (BigInt.one << 256) - BigInt.one;

  final requests = <String, Object? Function()>{
    "tron_signMessage": () => message("hello"),
    "tron_signTransaction": () => approve(BigInt.from(5000000)),
  };

  Future<Completer<WCBottomSheetResult?>> openSheet(String method, Object? params) async {
    final answer = Completer<WCBottomSheetResult?>();
    sheets.answers.add(answer.future);
    final isShown = sheets.nextSigningSheet;
    await rig.deliver(_topic, chain, method, params);
    await isShown;
    return answer;
  }

  Future<WireReply> onlyReply() async => (await rig.replies(_topic)).single;

  test("an approved message is signed by the wallet the sheet named", () async {
    sheets.answers.add(WCBottomSheetResult.one);
    await rig.deliver(_topic, chain, "tron_signMessage", message("hello"));
    await rig.settle();

    final sheet = sheets.signingSheets.single;
    expect(rowLines(sheet.decoded.rows), [row(S.current.wc_message_label, "hello")]);
    expect(sheet.address, addressA);
    expect((await onlyReply()).result, {"signature": signatureByA("hello")});
  });

  test("two messages that arrive together each get their own signature", () async {
    sheets.answers.addAll([WCBottomSheetResult.one, WCBottomSheetResult.one]);
    final ids = await rig.deliverTogether(_topic, chain, "tron_signMessage", [
      message("first message"),
      message("second message"),
    ]);
    await rig.settle();

    final replies = await rig.replies(_topic);
    expect(replies.map((reply) => reply.id), ids);
    expect(replies.map((reply) => reply.result), [
      {"signature": signatureByA("first message")},
      {"signature": signatureByA("second message")},
    ]);
  });

  test("an unlimited approve reaches the sheet with the summary's warning", () async {
    sheets.answers.add(WCBottomSheetResult.reject);
    await rig.deliver(_topic, chain, "tron_signTransaction", approve(unlimited));
    await rig.settle();

    final decoded = sheets.signingSheets.single.decoded;
    expect(decoded.actionTitle, S.current.approve_tokens);
    expect(decoded.warnings, [S.current.wc_warning_unlimited_approval]);
  });

  test("a bounded approve of a wallet token carries no warning", () async {
    sheets.answers.add(WCBottomSheetResult.reject);
    await rig.deliver(_topic, chain, "tron_signTransaction", approve(BigInt.from(5000000)));
    await rig.settle();

    expect(sheets.signingSheets.single.decoded.warnings, isEmpty);
  });

  final tokensTheWalletDoesNotVouchFor = {
    "flagged as a possible scam": walletUsdt(isPotentialScam: true),
    "the user disabled": walletUsdt(isEnabled: false),
  };
  for (final token in tokensTheWalletDoesNotVouchFor.entries) {
    test("a wallet token ${token.key} is shown as an unknown token", () async {
      tron = _RigTron(token.value);
      sheets.answers.add(WCBottomSheetResult.reject);
      await rig.deliver(_topic, chain, "tron_signTransaction", approve(BigInt.from(5000000)));
      await rig.settle();

      final decoded = sheets.signingSheets.single.decoded;
      expect(decoded.warnings, [S.current.wc_warning_unknown_token]);
      expect(rowValue(decoded.rows, S.current.value), S.current.wc_raw_amount("5000000"));
    });
  }

  test("a default token is named even when the wallet has it disabled", () async {
    tron = _RigTron(walletUsdt(isEnabled: false), defaults: [walletUsdt()]);
    sheets.answers.add(WCBottomSheetResult.reject);
    await rig.deliver(_topic, chain, "tron_signTransaction", approve(BigInt.from(5000000)));
    await rig.settle();

    final decoded = sheets.signingSheets.single.decoded;
    expect(decoded.warnings, isEmpty);
    expect(rowValue(decoded.rows, S.current.value), "5 USDT");
  });

  test("an approved transaction comes back signed by the wallet over the bytes shown", () async {
    final rawData = approveRawData(BigInt.from(5000000));
    final rawBytes = TransactionRaw.fromJson(rawData).toBuffer();
    sheets.answers.add(WCBottomSheetResult.one);
    await rig.deliver(_topic, chain, "tron_signTransaction", approve(BigInt.from(5000000)));
    await rig.settle();

    final result = (await onlyReply()).result! as Map<String, dynamic>;
    expect(result["raw_data_hex"], BytesUtils.toHexString(rawBytes));
    expect(result["signature"], [BytesUtils.toHexString(TronPrivateKey(_keyA).sign(rawBytes))]);
  });

  for (final request in requests.entries) {
    test("${request.key}: another wallet opened under the sheet gets nothing signed", () async {
      final answer = await openSheet(request.key, request.value());
      rig.appStore.wallet = RigWallet(
        "Tron B",
        address: addressB,
        privateKey: _keyB,
        chains: [chain],
        type: WalletType.tron,
      );
      answer.complete(WCBottomSheetResult.one);
      await rig.settle();

      final reply = await onlyReply();
      expect(reply.errorCode, 4100);
      expect(reply.result, isNull);
      expect(sheets.messages, [S.current.wc_request_for_different_wallet]);
      expect(rig.keyService.privateKeyReads, 0);
    });

    test("${request.key}: a request that expired under the sheet is dropped", () async {
      final answer = await openSheet(request.key, request.value());
      await rig.expireRequest(rig.kit.pendingRequests.getAll().single.id);
      answer.complete(WCBottomSheetResult.one);
      await rig.settle();

      expect(sheets.messages, [S.current.wc_request_expired]);
      expect(await rig.replies(_topic), isEmpty);
      expect(rig.keyService.privateKeyReads, 0);
    });

    test("${request.key}: a session the dApp deleted under the sheet is dropped", () async {
      final answer = await openSheet(request.key, request.value());
      await rig.kit.sessions.delete(_topic);
      answer.complete(WCBottomSheetResult.one);
      await rig.settle();

      expect(sheets.messages, [S.current.wc_request_expired]);
      expect(await rig.replies(_topic), isEmpty);
      expect(rig.keyService.privateKeyReads, 0);
    });
  }

  test("a rejection is answered with user rejected and no modal", () async {
    sheets.answers.add(WCBottomSheetResult.reject);
    await rig.deliver(_topic, chain, "tron_signMessage", message("hello"));
    await rig.settle();

    final reply = await onlyReply();
    expect(reply.errorCode, 5000);
    expect(reply.errorMessage, "User rejected.");
    expect(sheets.shown, hasLength(1));
  });

  test("an expiration too large to serialize is refused as malformed", () async {
    final rawData = approveRawData(BigInt.from(5000000));
    rawData["expiration"] = (BigInt.one << 64).toString();

    await rig.deliver(_topic, chain, "tron_signTransaction", {
      "address": addressA,
      "transaction": {"raw_data": rawData},
    });
    await rig.settle();

    final reply = await onlyReply();
    expect(reply.errorCode, 11002);
    expect(reply.errorMessage, "Malformed request parameters.");
    expect(sheets.signingSheets, isEmpty);
    expect(sheets.messages, [S.current.wc_request_malformed]);
  });

  test("a refusal shows one message and does not open the dApp, an approval does", () async {
    const redirectTopic = "topic-with-redirect";
    await rig.addSession(
      redirectTopic,
      accounts: ["$chain:$addressA"],
      methods: _methods,
      redirect: WcServiceRig.dappRedirect,
    );
    rig.recordOpenedUrls();

    await rig.deliver(redirectTopic, chain, "tron_signMessage", {"message": 7});
    await rig.settle();
    expect((await rig.replies(redirectTopic)).single.errorCode, 11002);
    expect(sheets.shown, hasLength(1));
    expect(sheets.messages, [S.current.wc_request_malformed]);
    expect(rig.openedUrls, isEmpty);

    sheets.answers.add(WCBottomSheetResult.one);
    await rig.deliver(redirectTopic, chain, "tron_signMessage", message("hello"));
    await rig.settle();
    expect(rig.openedUrls, [WcServiceRig.dappRedirect]);
  });
}
