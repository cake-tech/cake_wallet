import "dart:async";
import "dart:convert";
import "dart:typed_data";

import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart";
import "package:cake_wallet/src/screens/wallet_connect/services/bottom_sheet_service.dart";
import "package:cake_wallet/src/screens/wallet_connect/services/chain_service/eth/evm_chain_id.dart";
import "package:cake_wallet/src/screens/wallet_connect/services/chain_service/eth/evm_chain_service.dart";
import "package:cake_wallet/src/screens/wallet_connect/services/key_service/wallet_connect_key_service.dart";
import "package:cake_wallet/store/dashboard/fiat_conversion_store.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/node.dart";
import "package:cw_core/transaction_priority.dart";
import "package:cw_core/utils/proxy_wrapper.dart";
import "package:cw_core/utils/tor/disabled.dart";
import "package:cw_core/wallet_base.dart";
import "package:eth_sig_util/eth_sig_util.dart";
import "package:flutter_test/flutter_test.dart";
import "package:reown_walletkit/reown_walletkit.dart";

import "stubs.dart";
import "wc_service_rig.dart";

const _chains = {
  1: ChainInfo(chainId: 1, name: "Ethereum", shortCode: "eth", currency: CryptoCurrency.eth),
  137: ChainInfo(
    chainId: 137,
    name: "Polygon",
    shortCode: "pol",
    currency: CryptoCurrency.maticpoly,
  ),
};

class _RigEvm extends Fake implements EVM {
  _RigEvm(this.client);

  Web3Client? client;
  final selectedChainByWallet = <WalletBase, int>{};
  int privateKeyReads = 0;
  final selectChainCalls = <String>[];
  Error? selectChainError;

  @override
  String getCaip2ByChainId(int chainId) => "eip155:$chainId";

  @override
  ChainInfo? getChainInfoByChainId(int chainId) => _chains[chainId];

  @override
  int? getSelectedChainId(WalletBase wallet) => selectedChainByWallet[wallet];

  @override
  Future<void> selectChain(WalletBase wallet, int chainId, {required Node node}) async {
    final error = selectChainError;
    if (error != null) {
      throw error;
    }

    selectChainCalls.add("${wallet.name}->$chainId via ${node.uriRaw}");
    selectedChainByWallet[wallet] = chainId;
  }

  @override
  Web3Client? getWeb3Client(WalletBase wallet) => client;

  @override
  ChainInfo? getCurrentChain(WalletBase wallet) => _chains[selectedChainByWallet[wallet]];

  @override
  String getPublicKey(WalletBase wallet) => (wallet as RigWallet).address;

  @override
  String getPrivateKey(WalletBase wallet) {
    privateKeyReads += 1;
    return (wallet as RigWallet).privateKey;
  }

  @override
  TransactionPriority getDefaultTransactionPriority() => EVMChainTransactionPriority.medium;

  @override
  Future<EvmWalletConnectFeeQuote?> getWCBufferedFeeQuote(
    WalletBase wallet,
    TransactionPriority priority,
  ) async => null;
}

class _ScriptedNode extends RpcService {
  _ScriptedNode() : super("http://scripted-node.invalid");

  final calls = <String>[];
  final broadcasts = <String>[];

  Exception? failure;

  @override
  Future<RPCResponse> call(String function, [List<dynamic>? params]) async {
    calls.add(function);
    final error = failure;
    if (error != null) {
      throw error;
    }

    switch (function) {
      case "eth_gasPrice":
        return const RPCResponse(1, "0x3b9aca00");
      case "eth_estimateGas":
        return const RPCResponse(1, "0x5208");
      case "eth_getTransactionCount":
        return const RPCResponse(1, "0x7");
      case "eth_sendRawTransaction":
        broadcasts.add(params!.first as String);
        return const RPCResponse(1, _transactionHash);
    }

    throw StateError("the scripted node has no answer for $function");
  }
}

const _transactionHash = "0xfeedfacefeedfacefeedfacefeedfacefeedfacefeedfacefeedfacefeedface";

const _keyA = "ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
const _addressA = "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266";
const _keyB = "59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d";
const _addressB = "0x70997970c51812dc3a010c7d01b50e0d17dc79c8";

const _recipient = "0x1111111111111111111111111111111111111111";
const _oneEther = "0xde0b6b3a7640000";
const _topic = "topic-of-wallet-a";
const _evmChains = ["eip155:1", "eip155:137"];
const _evmMethods = [
  "personal_sign",
  "eth_sign",
  "eth_signTypedData",
  "eth_signTypedData_v3",
  "eth_signTypedData_v4",
  "eth_signTransaction",
  "eth_sendTransaction",
  "wallet_switchEthereumChain",
  "wallet_addEthereumChain",
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late WcServiceRig rig;
  late _ScriptedNode node;
  late _RigEvm evmProxy;
  late RigWallet walletA;
  late RigWallet walletB;

  setUp(() async {
    rig = await WcServiceRig.start();
    node = _ScriptedNode();
    evmProxy = _RigEvm(Web3Client.custom(node));
    evm = evmProxy;

    walletA = RigWallet("Wallet A", address: _addressA, privateKey: _keyA, chains: _evmChains);
    walletB = RigWallet("Wallet B", address: _addressB, privateKey: _keyB, chains: _evmChains);
    evmProxy.selectedChainByWallet[walletA] = 1;
    evmProxy.selectedChainByWallet[walletB] = 1;
    rig.appStore.wallet = walletA;

    for (final chain in [EVMChainId.ethereum, EVMChainId.polygon]) {
      EvmChainServiceImpl(
        reference: chain,
        appStore: rig.appStore,
        wcKeyService: KeyServiceImpl(),
        bottomSheetService: WcServiceRig.sheets,
        walletKit: rig.kit,
        fiatConversionStore: FiatConversionStore(rig.appStore.settingsStore),
      );
    }

    await rig.addSession(_topic, accounts: ["eip155:1:$_addressA"], methods: _evmMethods);
  });

  final sheets = WcServiceRig.sheets;

  tearDown(() => expect(sheets.unscripted, isEmpty, reason: "a sheet the test did not expect"));

  String utf8Hex(String text) =>
      "0x${utf8.encode(text).map((b) => b.toRadixString(16).padLeft(2, "0")).join()}";

  Map<String, dynamic> transfer({String to = _recipient, String value = _oneEther}) => {
    "from": _addressA,
    "to": to,
    "value": value,
    "gas": "0x5208",
    "maxFeePerGas": "0x77359400",
    "maxPriorityFeePerGas": "0x3b9aca00",
    "nonce": "0x1",
  };

  String typedData({required int domainChainId, Object contents = "hello"}) => jsonEncode({
    "types": {
      "EIP712Domain": [
        {"name": "name", "type": "string"},
        {"name": "chainId", "type": "uint256"},
      ],
      "Mail": [
        {"name": "contents", "type": "string"},
      ],
    },
    "primaryType": "Mail",
    "domain": {"name": "Rig Mail", "chainId": domainChainId},
    "message": {"contents": contents},
  });

  Future<Completer<WCBottomSheetResult?>> openSheet(
    String method,
    Object? params, {
    String topic = _topic,
    String chainId = "eip155:1",
  }) async {
    final answer = Completer<WCBottomSheetResult?>();
    sheets.answers.add(answer.future);
    final isShown = sheets.nextSigningSheet;
    await rig.deliver(topic, chainId, method, params);
    await isShown;
    return answer;
  }

  Future<WireReply> onlyReply({String topic = _topic}) async => (await rig.replies(topic)).single;

  String signerOfMessage(Object? signature, String text) => EthSigUtil.recoverPersonalSignature(
    signature: signature! as String,
    message: Uint8List.fromList(utf8.encode(text)),
  );

  group("replies the engine accepts", () {
    test("an approved switch tells the dApp the new chain as a string result", () async {
      sheets.answers.add(WCBottomSheetResult.one);
      await rig.deliver(_topic, "eip155:1", "wallet_switchEthereumChain", [
        {"chainId": "0x89"},
      ]);
      await rig.settle();

      final reply = await onlyReply();
      expect(
        reply.errorCode,
        isNull,
        reason: "the engine turns a non-string EVM result into -32602",
      );
      expect(reply.result, "0x89");
      expect(evmProxy.selectChainCalls, ["Wallet A->137 via node-for-chain-137.invalid"]);
    });

    test("an approved personal_sign is signed by the wallet the sheet named", () async {
      sheets.answers.add(WCBottomSheetResult.one);
      await rig.deliver(_topic, "eip155:1", "personal_sign", [utf8Hex("hello"), _addressA]);
      await rig.settle();

      final sheet = sheets.signingSheets.single;
      expect(rowLines(sheet.decoded.rows), [row(S.current.wc_message_label, "hello")]);
      expect(sheet.address, _addressA);
      expect(sheet.walletName, "Wallet A");
      expect(signerOfMessage((await onlyReply()).result, "hello"), _addressA);
    });

    test("approved typed data is signed by the wallet over the payload shown", () async {
      final payload = typedData(domainChainId: 1);
      sheets.answers.add(WCBottomSheetResult.one);
      await rig.deliver(_topic, "eip155:1", "eth_signTypedData_v4", [_addressA, payload]);
      await rig.settle();

      final signer = EthSigUtil.recoverSignature(
        signature: (await onlyReply()).result! as String,
        message: TypedDataUtil.hashMessage(jsonData: payload, version: TypedDataVersion.V4),
      );
      expect(signer, _addressA);
    });
  });

  group("each handler works on the request it was called for", () {
    test("two transactions that arrive together are each shown and answered once", () async {
      const otherRecipient = "0x2222222222222222222222222222222222222222";
      sheets.answers.addAll([WCBottomSheetResult.one, WCBottomSheetResult.one]);
      final ids = await rig.deliverTogether(_topic, "eip155:1", "eth_sendTransaction", [
        [transfer(value: "0x1")],
        [transfer(to: otherRecipient)],
      ]);
      await rig.settle();

      expect(sheets.signingSheets.map((sheet) => rowLines(sheet.decoded.rows)), [
        [row(S.current.wc_amount, "0.000000000000000001 ETH"), row(S.current.to, _recipient)],
        [row(S.current.wc_amount, "1 ETH"), row(S.current.to, otherRecipient)],
      ]);
      expect((await rig.replies(_topic)).map((reply) => reply.id), ids);
      expect(node.broadcasts.toSet(), hasLength(2), reason: "one broadcast per request");
    });
  });

  group("the rows of a transaction sheet", () {
    Future<WCDecodedRequest> shown(Map<String, dynamic> transaction) async {
      sheets.answers.add(WCBottomSheetResult.reject);
      await rig.deliver(_topic, "eip155:1", "eth_sendTransaction", [transaction]);
      await rig.settle();
      return sheets.signingSheets.single.decoded;
    }

    test("a wrap names the contract it pays and the value sent", () async {
      const weth = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2";

      final wrap = await shown({...transfer(to: weth), "data": "0xd0e30db0"});
      expect(rowLines(wrap.rows), [row(S.current.to, weth), row(S.current.wc_value, "1 ETH")]);
    });

    test("a call that is not read shows its value once and its calldata as the raw view", () async {
      final call = await shown({...transfer(), "data": "0xdeadbeef"});
      expect(rowLines(call.rows), [
        row(S.current.wc_contract, _recipient),
        row(S.current.wc_value, "1 ETH"),
      ]);
      expect(call.rawFallback, "0xdeadbeef");
    });
  });

  group("the wallet is checked again after the sheet", () {
    final requests = <String, Object? Function()>{
      "personal_sign": () => [utf8Hex("hello"), _addressA],
      "eth_signTypedData_v4": () => [_addressA, typedData(domainChainId: 1)],
      "eth_signTransaction": () => [transfer()],
      "eth_sendTransaction": () => [transfer()],
      "wallet_switchEthereumChain": () => [
        {"chainId": "0x89"},
      ],
    };

    for (final request in requests.entries) {
      test("${request.key}: another wallet opened under the sheet gets nothing signed", () async {
        final answer = await openSheet(request.key, request.value());
        rig.appStore.wallet = walletB;
        answer.complete(WCBottomSheetResult.one);
        await rig.settle();

        final reply = await onlyReply();
        expect(reply.errorCode, 4100);
        expect(reply.result, isNull);
        expect(sheets.messages, [S.current.wc_request_for_different_wallet]);
        expect(evmProxy.privateKeyReads, 0, reason: "no key may be read for this request");
        expect(node.calls, isEmpty, reason: "nothing may reach the node");
        expect(evmProxy.selectChainCalls, isEmpty);
        expect(await rig.walletRequests(_topic), isEmpty, reason: "the session must not change");
      });

      test("${request.key}: a request that expired under the sheet is dropped", () async {
        final answer = await openSheet(request.key, request.value());
        await rig.expireRequest(rig.kit.pendingRequests.getAll().single.id);
        answer.complete(WCBottomSheetResult.one);
        await rig.settle();

        expect(sheets.messages, [S.current.wc_request_expired]);
        expect(await rig.replies(_topic), isEmpty);
        expect(evmProxy.privateKeyReads, 0);
        expect(node.calls, isEmpty);
        expect(evmProxy.selectChainCalls, isEmpty);
        expect(await rig.walletRequests(_topic), isEmpty);
      });

      test("${request.key}: a session the dApp deleted under the sheet is dropped", () async {
        final answer = await openSheet(request.key, request.value());
        await rig.kit.sessions.delete(_topic);
        answer.complete(WCBottomSheetResult.one);
        await rig.settle();

        expect(sheets.messages, [S.current.wc_request_expired]);
        expect(await rig.replies(_topic), isEmpty);
        expect(evmProxy.privateKeyReads, 0);
        expect(node.calls, isEmpty);
        expect(evmProxy.selectChainCalls, isEmpty);
      });
    }

    test("a network change under a transaction sheet refuses it", () async {
      final answer = await openSheet("eth_sendTransaction", [transfer()]);
      evmProxy.selectedChainByWallet[walletA] = 137;
      answer.complete(WCBottomSheetResult.one);
      await rig.settle();

      final reply = await onlyReply();
      expect(reply.errorCode, 4901);
      expect(sheets.messages, [S.current.wc_request_for_other_network("Ethereum")]);
      expect(node.broadcasts, isEmpty);
      expect(evmProxy.privateKeyReads, 0);
    });

    test("no key is read before the sheet is answered", () async {
      final answer = await openSheet("eth_sendTransaction", [transfer()]);
      expect(evmProxy.privateKeyReads, 0);

      answer.complete(WCBottomSheetResult.one);
      await rig.settle();
      expect(evmProxy.privateKeyReads, 1);
    });
  });

  group("a request on a session chain the wallet is not on", () {
    const twoChainTopic = "topic-with-two-chains";

    setUp(() async {
      await rig.addSession(
        twoChainTopic,
        accounts: ["eip155:1:$_addressA", "eip155:137:$_addressA"],
        methods: _evmMethods,
      );
    });

    test("asks to switch, then shows the transaction on that network", () async {
      sheets.answers.addAll([WCBottomSheetResult.one, WCBottomSheetResult.one]);
      await rig.deliver(twoChainTopic, "eip155:137", "eth_sendTransaction", [transfer()]);
      await rig.settle();

      final shown = sheets.signingSheets.toList();
      expect(shown, hasLength(2));
      expect(shown.first.decoded.actionTitle, S.current.wc_action_switch_chain);
      expect(shown.first.address, _addressA);
      expect(shown.first.decoded.actionSubtitle, S.current.wc_switch_to_continue("Polygon"));
      expect(rowLines(shown.last.decoded.rows), [
        row(S.current.wc_amount, "1 POL"),
        row(S.current.to, _recipient),
      ]);
      expect(evmProxy.selectChainCalls, ["Wallet A->137 via node-for-chain-137.invalid"]);

      final events = await rig.walletRequests(twoChainTopic);
      expect(events.single["params"], {
        "chainId": "eip155:137",
        "event": {"name": "chainChanged", "data": 137},
      });
      expect((await onlyReply(topic: twoChainTopic)).result, _transactionHash);
      expect(node.broadcasts.single, startsWith("0x02f8738189"), reason: "signed for chain 137");
    });

    test("two requests that arrive together ask for the switch once", () async {
      sheets.answers.addAll(List.filled(3, WCBottomSheetResult.one));
      await rig.deliverTogether(twoChainTopic, "eip155:137", "eth_sendTransaction", [
        [transfer(value: "0x1")],
        [transfer()],
      ]);
      await rig.settle();

      expect(sheets.signingSheets.map((sheet) => sheet.decoded.actionTitle), [
        S.current.wc_action_switch_chain,
        S.current.wc_action_send,
        S.current.wc_action_send,
      ]);
      expect(evmProxy.selectChainCalls, hasLength(1));
      expect(await rig.walletRequests(twoChainTopic), hasLength(1), reason: "one chainChanged");
      expect((await rig.replies(twoChainTopic)).map((reply) => reply.result), [
        _transactionHash,
        _transactionHash,
      ]);
    });

    test(
      "another wallet opened under the first switch sheet stops the request behind it",
      () async {
        final answer = Completer<WCBottomSheetResult?>();
        sheets.answers.add(answer.future);
        final isShown = sheets.nextSigningSheet;
        await rig.deliverTogether(twoChainTopic, "eip155:137", "eth_sendTransaction", [
          [transfer(value: "0x1")],
          [transfer()],
        ]);
        await isShown;
        rig.appStore.wallet = walletB;
        answer.complete(WCBottomSheetResult.one);
        await rig.settle();

        expect(sheets.signingSheets, hasLength(1), reason: "no switch sheet for the other wallet");
        expect((await rig.replies(twoChainTopic)).map((reply) => reply.errorCode), [4100, 4100]);
        expect(evmProxy.selectChainCalls, isEmpty);
      },
    );

    test("after a declined switch the next request asks again for itself", () async {
      sheets.answers.addAll([
        WCBottomSheetResult.reject,
        WCBottomSheetResult.one,
        WCBottomSheetResult.one,
      ]);
      final ids = await rig.deliverTogether(twoChainTopic, "eip155:137", "eth_sendTransaction", [
        [transfer(value: "0x1")],
        [transfer()],
      ]);
      await rig.settle();

      final replies = {for (final reply in await rig.replies(twoChainTopic)) reply.id: reply};
      expect(replies[ids.first]!.errorCode, 5000);
      expect(replies[ids.last]!.result, _transactionHash);
      expect(sheets.signingSheets.map((sheet) => sheet.decoded.actionTitle), [
        S.current.wc_action_switch_chain,
        S.current.wc_action_switch_chain,
        S.current.wc_action_send,
      ]);
    });

    test("a dApp that does not acknowledge chainChanged does not hold up the request", () async {
      rig.doesDappAcknowledge = false;
      sheets.answers.addAll([WCBottomSheetResult.one, WCBottomSheetResult.one]);
      await rig.deliver(twoChainTopic, "eip155:137", "eth_sendTransaction", [transfer()]);
      await rig.settle();

      expect(sheets.signingSheets, hasLength(2));
      expect((await onlyReply(topic: twoChainTopic)).result, _transactionHash);
    });

    test("typed data goes through the same switch first", () async {
      final payload = typedData(domainChainId: 137);
      sheets.answers.addAll([WCBottomSheetResult.one, WCBottomSheetResult.one]);
      await rig.deliver(twoChainTopic, "eip155:137", "eth_signTypedData_v4", [_addressA, payload]);
      await rig.settle();

      expect(
        sheets.signingSheets.map((sheet) => sheet.decoded.actionTitle).first,
        S.current.wc_action_switch_chain,
      );
      expect(sheets.signingSheets, hasLength(2));
      expect(evmProxy.selectedChainByWallet[walletA], 137);
      expect((await onlyReply(topic: twoChainTopic)).errorCode, isNull);
    });

    test("declining the switch rejects the request and moves nothing", () async {
      sheets.answers.add(WCBottomSheetResult.reject);
      await rig.deliver(twoChainTopic, "eip155:137", "eth_sendTransaction", [transfer()]);
      await rig.settle();

      final reply = await onlyReply(topic: twoChainTopic);
      expect(reply.errorCode, 5000);
      expect(reply.errorMessage, "User rejected.");
      expect(sheets.signingSheets, hasLength(1), reason: "the transaction sheet must not follow");
      expect(evmProxy.selectChainCalls, isEmpty);
      expect(node.calls, isEmpty);
    });

    test("a switch that fails is reported and nothing is signed", () async {
      evmProxy.selectChainError = StateError("node for chain 137 is down");
      sheets.answers.add(WCBottomSheetResult.one);
      await rig.deliver(twoChainTopic, "eip155:137", "eth_sendTransaction", [transfer()]);
      await rig.settle();

      final reply = await onlyReply(topic: twoChainTopic);
      expect(reply.errorCode, 4901);
      expect(reply.errorMessage, "The wallet could not switch to the requested chain.");
      expect(sheets.messages, [S.current.wc_switch_chain_failed]);
      expect(sheets.signingSheets, hasLength(1));
      expect(evmProxy.privateKeyReads, 0);
    });
  });

  group("wallet_switchEthereumChain", () {
    test("a chain the session has and the wallet is on succeeds without a sheet", () async {
      await rig.deliver(_topic, "eip155:1", "wallet_switchEthereumChain", [
        {"chainId": "0x1"},
      ]);
      await rig.settle();

      expect((await onlyReply()).result, "0x1");
      expect(sheets.shown, isEmpty);
      expect(evmProxy.selectChainCalls, isEmpty);
    });

    test("the sheet names the wallet that would change network and the method asked", () async {
      sheets.answers.add(WCBottomSheetResult.reject);
      await rig.deliver(_topic, "eip155:1", "wallet_switchEthereumChain", [
        {"chainId": "0x89"},
      ]);
      await rig.settle();

      final sheet = sheets.signingSheets.single;
      expect(sheet.walletName, "Wallet A");
      expect(sheet.address, _addressA);
      expect(rowValue(sheet.infoRows, S.current.method), "wallet_switchEthereumChain");
    });

    test("the wallet's own chain still needs the sheet when the session lacks it", () async {
      evmProxy.selectedChainByWallet[walletA] = 137;
      sheets.answers.add(WCBottomSheetResult.one);
      await rig.deliver(_topic, "eip155:1", "wallet_switchEthereumChain", [
        {"chainId": "0x89"},
      ]);
      await rig.settle();

      expect(sheets.signingSheets, hasLength(1));
      expect(rig.kit.sessions.get(_topic)!.namespaces["eip155"]!.accounts, [
        "eip155:1:$_addressA",
        "eip155:137:$_addressA",
      ]);
      expect((await onlyReply()).result, "0x89");
    });

    test("the session is updated before the reply, and chainChanged follows it", () async {
      sheets.answers.add(WCBottomSheetResult.one);
      await rig.deliver(_topic, "eip155:1", "wallet_switchEthereumChain", [
        {"chainId": "0x89"},
      ]);
      await rig.settle();

      expect(await rig.publishedKinds(_topic), ["wc_sessionUpdate", "reply", "wc_sessionEvent"]);
    });

    test("an unsupported chain is refused with 4902 and one message", () async {
      await rig.deliver(_topic, "eip155:1", "wallet_switchEthereumChain", [
        {"chainId": "0x539"},
      ]);
      await rig.settle();

      final reply = await onlyReply();
      expect(reply.errorCode, 4902);
      expect(reply.errorMessage, isNot(matches(RegExp("user rejected", caseSensitive: false))));
      expect(sheets.shown, hasLength(1), reason: "one message, no second modal on top");
      expect(sheets.messages, [S.current.wc_warning_chain_not_supported]);
    });

    test("a dApp that never acknowledges the session update does not block the switch", () async {
      rig.doesDappAcknowledge = false;
      sheets.answers.add(WCBottomSheetResult.one);
      await rig.deliver(_topic, "eip155:1", "wallet_switchEthereumChain", [
        {"chainId": "0x89"},
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 3500));

      expect((await onlyReply()).result, "0x89");
      expect(evmProxy.selectChainCalls, hasLength(1));
    });
  });

  group("wallet_addEthereumChain", () {
    test("a built-in chain takes the switch path", () async {
      sheets.answers.add(WCBottomSheetResult.one);
      await rig.deliver(_topic, "eip155:1", "wallet_addEthereumChain", [
        {"chainId": "0x89", "chainName": "Polygon"},
      ]);
      await rig.settle();

      expect(sheets.signingSheets.single.decoded.actionTitle, S.current.wc_action_switch_chain);
      expect((await onlyReply()).result, "0x89");
      expect(evmProxy.selectedChainByWallet[walletA], 137);
      expect(
        rig.kit.sessions.get(_topic)!.namespaces["eip155"]!.accounts,
        contains("eip155:137:$_addressA"),
      );
    });

    test("the sheet shows the method the dApp asked for, and the wallet's address", () async {
      sheets.answers.add(WCBottomSheetResult.reject);
      await rig.deliver(_topic, "eip155:1", "wallet_addEthereumChain", [
        {"chainId": "0x89", "chainName": "Polygon"},
      ]);
      await rig.settle();

      final sheet = sheets.signingSheets.single;
      expect(rowValue(sheet.infoRows, S.current.method), "wallet_addEthereumChain");
      expect(sheet.title, S.current.wc_approve_request_title);
      expect(sheet.address, _addressA);
    });

    test("a chain the session has and the wallet is on succeeds without a sheet", () async {
      await rig.deliver(_topic, "eip155:1", "wallet_addEthereumChain", [
        {"chainId": "0x1", "chainName": "Ethereum"},
      ]);
      await rig.settle();

      expect((await onlyReply()).result, "0x1");
      expect(sheets.shown, isEmpty);
    });

    test("an unknown chain is refused with 4200 and one message", () async {
      await rig.deliver(_topic, "eip155:1", "wallet_addEthereumChain", [
        {"chainId": "0x539", "chainName": "Local"},
      ]);
      await rig.settle();

      expect((await onlyReply()).errorCode, 4200);
      expect(sheets.shown, hasLength(1));
      expect(sheets.messages, [S.current.wc_warning_add_chain_not_supported]);
    });
  });

  group("refusals before any sheet", () {
    for (final field in [
      "value",
      "gas",
      "gasPrice",
      "maxFeePerGas",
      "maxPriorityFeePerGas",
      "nonce",
    ]) {
      test("a $field without the 0x prefix is refused, not read as hex", () async {
        await rig.deliver(_topic, "eip155:1", "eth_sendTransaction", [
          transfer()..[field] = "21000",
        ]);
        await rig.settle();

        expect((await onlyReply()).errorCode, 11002);
        expect(sheets.signingSheets, isEmpty);
      });
    }

    test("a quantity sent as a JSON number is refused", () async {
      await rig.deliver(_topic, "eip155:1", "eth_sendTransaction", [transfer()..["gas"] = 21000]);
      await rig.settle();

      final reply = await onlyReply();
      expect(reply.errorCode, 11002);
      expect(reply.errorMessage, Errors.getSdkError(Errors.MALFORMED_REQUEST_PARAMS).message);
      expect(sheets.signingSheets, isEmpty);
      expect(sheets.messages, [S.current.wc_request_malformed]);
    });

    test("a gas limit too large to be one is refused, not replaced by an estimate", () async {
      await rig.deliver(_topic, "eip155:1", "eth_sendTransaction", [
        transfer()..["gas"] = "0xffffffffffffffffffff",
      ]);
      await rig.settle();

      expect((await onlyReply()).errorCode, 11002);
      expect(sheets.signingSheets, isEmpty);
      expect(node.calls, isEmpty);
    });

    test("a gas of null is an absent one, the node estimates it", () async {
      sheets.answers.add(WCBottomSheetResult.reject);
      await rig.deliver(_topic, "eip155:1", "eth_sendTransaction", [transfer()..["gas"] = null]);
      await rig.settle();

      expect(sheets.signingSheets, hasLength(1));
      expect(node.calls, contains("eth_estimateGas"));
    });

    test("typed data that does not match its types is refused with the reason", () async {
      await rig.deliver(_topic, "eip155:1", "eth_signTypedData_v4", [
        _addressA,
        typedData(domainChainId: 1, contents: 7),
      ]);
      await rig.settle();

      final reply = await onlyReply();
      expect(reply.errorCode, 11002);
      expect(reply.errorMessage, "The typed data is malformed and could not be read.");
      expect(sheets.shown, hasLength(1));
      expect(sheets.messages, [S.current.wc_warning_typed_data_invalid]);
    });

    test("typed data for another chain is refused with one message", () async {
      await rig.deliver(_topic, "eip155:1", "eth_signTypedData_v4", [
        _addressA,
        typedData(domainChainId: 137),
      ]);
      await rig.settle();

      expect((await onlyReply()).errorCode, 11002);
      expect(sheets.shown, hasLength(1));
      expect(sheets.messages, [S.current.wc_typed_data_wrong_chain("137")]);
    });

    const nodeFailure = "Connection refused, uri=http://node.invalid/v3/USER-PRIVATE-NODE-KEY";

    test("a node that cannot be reached for the gas estimate leaks nothing to the dApp", () async {
      node.failure = Exception(nodeFailure);
      await rig.deliver(_topic, "eip155:1", "eth_sendTransaction", [transfer()..remove("gas")]);
      await rig.settle();

      final reply = await onlyReply();
      expect(reply.errorMessage, "The wallet could not prepare the transaction.");
      expect(reply.errorCode, -32000);
      expect(sheets.shown, hasLength(1));
      expect(sheets.messages, [S.current.wc_transaction_prepare_failed]);
    });

    test("a node that cannot be reached for the gas price leaks nothing to the dApp", () async {
      node.failure = Exception(nodeFailure);
      await rig.deliver(_topic, "eip155:1", "eth_sendTransaction", [
        transfer()
          ..remove("maxFeePerGas")
          ..remove("maxPriorityFeePerGas"),
      ]);
      await rig.settle();

      expect(node.calls, ["eth_gasPrice"]);
      expect((await onlyReply()).errorMessage, "The wallet could not prepare the transaction.");
      expect(sheets.messages, [S.current.wc_transaction_prepare_failed]);
    });

    test("a node error on the gas estimate is passed on as the node sent it", () async {
      node.failure = const RPCError(3, "execution reverted: not enough allowance", null);
      await rig.deliver(_topic, "eip155:1", "eth_sendTransaction", [transfer()..remove("gas")]);
      await rig.settle();

      final reply = await onlyReply();
      expect(reply.errorCode, 3);
      expect(reply.errorMessage, "execution reverted: not enough allowance");
      expect(sheets.messages, [S.current.wc_transaction_prepare_failed]);
    });

    test("a node that cannot be reached at broadcast leaks nothing to the dApp", () async {
      final answer = await openSheet("eth_sendTransaction", [transfer()]);
      node.failure = Exception(nodeFailure);
      answer.complete(WCBottomSheetResult.one);
      await rig.settle();

      final reply = await onlyReply();
      expect(reply.errorCode, 11002);
      expect(reply.errorMessage, isNot(contains("USER-PRIVATE-NODE-KEY")));
    });

    test("personal_sign params sent address first still show and sign the message", () async {
      sheets.answers.add(WCBottomSheetResult.one);
      await rig.deliver(_topic, "eip155:1", "personal_sign", [_addressA, utf8Hex("hello")]);
      await rig.settle();

      final sheet = sheets.signingSheets.single;
      expect(rowLines(sheet.decoded.rows), [row(S.current.wc_message_label, "hello")]);
      expect(sheet.address, _addressA);
      expect(signerOfMessage((await onlyReply()).result, "hello"), _addressA);
    });

    test("a personal_sign that names no account shows the wallet that signs it", () async {
      sheets.answers.add(WCBottomSheetResult.one);
      await rig.deliver(_topic, "eip155:1", "personal_sign", [utf8Hex("hello")]);
      await rig.settle();

      expect(sheets.signingSheets.single.address, _addressA);
      expect(signerOfMessage((await onlyReply()).result, "hello"), _addressA);
    });

    test("a signing request naming another account is refused", () async {
      await rig.deliver(_topic, "eip155:1", "personal_sign", [_addressB, utf8Hex("hello")]);
      await rig.settle();

      expect((await onlyReply()).errorCode, 4100);
      expect(sheets.signingSheets, isEmpty);
    });
  });

  group("the dApp is told why in English, the user in the app's language", () {
    const twoChainTopic = "topic-with-two-chains";

    setUp(() async {
      S.current = const $de();
      await rig.addSession(
        twoChainTopic,
        accounts: ["eip155:1:$_addressA", "eip155:137:$_addressA"],
        methods: _evmMethods,
      );
    });

    void expectRefusal(
      WireReply reply, {
      required int code,
      required String told,
      required String shown,
    }) {
      expect(reply.errorCode, code);
      expect(reply.errorMessage, told);
      expect(sheets.messages, [shown]);
      expect(shown, isNot(told));
    }

    test("an unsupported chain", () async {
      await rig.deliver(_topic, "eip155:1", "wallet_switchEthereumChain", [
        {"chainId": "0x539"},
      ]);
      await rig.settle();

      expect(
        S.current.wc_warning_chain_not_supported,
        isNot(const S().wc_warning_chain_not_supported),
      );
      expectRefusal(
        await onlyReply(),
        code: 4902,
        told: "The wallet does not support this chain.",
        shown: S.current.wc_warning_chain_not_supported,
      );
    });

    test("a chain that cannot be added", () async {
      await rig.deliver(_topic, "eip155:1", "wallet_addEthereumChain", [
        {"chainId": "0x539", "chainName": "Local"},
      ]);
      await rig.settle();

      expectRefusal(
        await onlyReply(),
        code: 4200,
        told: "The wallet only has its built-in chains, this one was not added.",
        shown: S.current.wc_warning_add_chain_not_supported,
      );
    });

    test("typed data that does not match its types", () async {
      await rig.deliver(_topic, "eip155:1", "eth_signTypedData_v4", [
        _addressA,
        typedData(domainChainId: 1, contents: 7),
      ]);
      await rig.settle();

      expectRefusal(
        await onlyReply(),
        code: 11002,
        told: "The typed data is malformed and could not be read.",
        shown: S.current.wc_warning_typed_data_invalid,
      );
    });

    test("typed data for another chain", () async {
      await rig.deliver(_topic, "eip155:1", "eth_signTypedData_v4", [
        _addressA,
        typedData(domainChainId: 137),
      ]);
      await rig.settle();

      expectRefusal(
        await onlyReply(),
        code: 11002,
        told: "The typed data is for chain 137, not for the chain of this request.",
        shown: S.current.wc_typed_data_wrong_chain("137"),
      );
    });

    test("a network change under the sheet", () async {
      final answer = await openSheet("eth_sendTransaction", [transfer()]);
      evmProxy.selectedChainByWallet[walletA] = 137;
      answer.complete(WCBottomSheetResult.one);
      await rig.settle();

      expectRefusal(
        await onlyReply(),
        code: 4901,
        told: "The wallet is no longer on the chain of this request.",
        shown: S.current.wc_request_for_other_network("Ethereum"),
      );
    });

    test("a switch that fails", () async {
      evmProxy.selectChainError = StateError("node for chain 137 is down");
      sheets.answers.add(WCBottomSheetResult.one);
      await rig.deliver(twoChainTopic, "eip155:137", "eth_sendTransaction", [transfer()]);
      await rig.settle();

      expectRefusal(
        await onlyReply(topic: twoChainTopic),
        code: 4901,
        told: "The wallet could not switch to the requested chain.",
        shown: S.current.wc_switch_chain_failed,
      );
    });
  });

  test("without a client from the wallet the service builds one and keeps it", () {
    CakeTor.instance = CakeTorDisabled();
    evmProxy.client = null;
    final service = EvmChainServiceImpl(
      reference: EVMChainId.ethereum,
      appStore: rig.appStore,
      wcKeyService: KeyServiceImpl(),
      bottomSheetService: WcServiceRig.sheets,
      walletKit: rig.kit,
      fiatConversionStore: FiatConversionStore(rig.appStore.settingsStore),
    );

    expect(service.ethClient, same(service.ethClient));
  });

  test("the network fee carries its fiat value from the store the service was given", () async {
    final prices = FiatConversionStore(rig.appStore.settingsStore)
      ..prices[CryptoCurrency.eth] = 2000;
    EvmChainServiceImpl(
      reference: EVMChainId.ethereum,
      appStore: rig.appStore,
      wcKeyService: KeyServiceImpl(),
      bottomSheetService: WcServiceRig.sheets,
      walletKit: rig.kit,
      fiatConversionStore: prices,
    );
    sheets.answers.add(WCBottomSheetResult.reject);
    await rig.deliver(_topic, "eip155:1", "eth_sendTransaction", [transfer()]);
    await rig.settle();

    final fee = sheets.signingSheets.single.infoRows.singleWhere(
      (shown) => shown.label == S.current.wc_max_network_fee,
    );
    expect(fee.value, "0.000042 ETH");
    expect(fee.fiatValue, "~ 0.08 USD");
  });

  group("a rejection", () {
    final requests = <String, Object? Function()>{
      "personal_sign": () => [utf8Hex("hello"), _addressA],
      "eth_sign": () => [_addressA, utf8Hex("hello")],
      "eth_signTypedData": () => [_addressA, typedData(domainChainId: 1)],
      "eth_signTypedData_v3": () => [_addressA, typedData(domainChainId: 1)],
      "eth_signTypedData_v4": () => [_addressA, typedData(domainChainId: 1)],
      "eth_signTransaction": () => [transfer()],
      "eth_sendTransaction": () => [transfer()],
      "wallet_switchEthereumChain": () => [
        {"chainId": "0x89"},
      ],
    };

    for (final request in requests.entries) {
      test("${request.key} is answered with the one user-rejected error and no modal", () async {
        sheets.answers.add(WCBottomSheetResult.reject);
        await rig.deliver(_topic, "eip155:1", request.key, request.value());
        await rig.settle();

        final reply = await onlyReply();
        expect(reply.errorCode, 5000);
        expect(reply.errorMessage, "User rejected.");
        expect(sheets.shown, hasLength(1), reason: "only the sheet the user rejected");
        expect(evmProxy.privateKeyReads, 0);
      });
    }
  });

  group("going back to the dApp", () {
    const redirectTopic = "topic-with-redirect";

    setUp(() async {
      await rig.addSession(
        redirectTopic,
        accounts: ["eip155:1:$_addressA"],
        methods: _evmMethods,
        redirect: WcServiceRig.dappRedirect,
      );
    });

    final repliesWithoutDecision = <String, (String, Object?)>{
      "a malformed request": ("eth_sendTransaction", ["not a transaction"]),
      "an unsupported chain": (
        "wallet_switchEthereumChain",
        [
          {"chainId": "0x539"},
        ],
      ),
      "a switch to the chain already in use": (
        "wallet_switchEthereumChain",
        [
          {"chainId": "0x1"},
        ],
      ),
    };

    for (final request in repliesWithoutDecision.entries) {
      test("${request.key} is answered without opening the dApp", () async {
        rig.recordOpenedUrls();
        await rig.deliver(redirectTopic, "eip155:1", request.value.$1, request.value.$2);
        await rig.settle();

        expect(await rig.replies(redirectTopic), hasLength(1));
        expect(rig.openedUrls, isEmpty);
      });
    }

    test("an approved request opens the dApp", () async {
      rig.recordOpenedUrls();
      sheets.answers.add(WCBottomSheetResult.one);
      await rig.deliver(redirectTopic, "eip155:1", "personal_sign", [utf8Hex("hello"), _addressA]);
      await rig.settle();

      expect(rig.openedUrls, [WcServiceRig.dappRedirect]);
      expect(sheets.goBackModals, isEmpty);
    });

    test("a dApp link that cannot be opened ends in the go-back modal", () async {
      rig.recordOpenedUrls(canOpen: false);
      sheets.answers.add(WCBottomSheetResult.one);
      await rig.deliver(redirectTopic, "eip155:1", "personal_sign", [utf8Hex("hello"), _addressA]);
      await rig.settle();

      expect(sheets.goBackModals.single.isSuccess, isTrue);
    });

    test("a reply that cannot be sent shows a dismissible error and sends nothing", () async {
      final answer = await openSheet("personal_sign", [utf8Hex("hello"), _addressA]);
      rig.isOnline = false;
      answer.complete(WCBottomSheetResult.one);
      await rig.settle();

      expect(await rig.replies(_topic), isEmpty, reason: "the engine must not send the error text");
      final modal = sheets.goBackModals.single;
      expect(modal.isSuccess, isFalse);
      expect(modal.message, S.current.please_try_again_later);
      expect(sheets.dismissibleByWidget[modal], isTrue);
    });
  });

  test("a broadcast whose reply cannot be sent says it was sent, not to try again", () async {
    final answer = await openSheet("eth_sendTransaction", [transfer()]);
    rig.isOnline = false;
    answer.complete(WCBottomSheetResult.one);
    await rig.settle();

    expect(node.broadcasts, hasLength(1));
    expect(await rig.replies(_topic), isEmpty);
    final modal = sheets.goBackModals.single;
    expect(modal.title, S.current.transaction_sent);
    expect(modal.message, isNull);
    expect(modal.isSuccess, isTrue);
  });

  test("a rejection that cannot be sent shows nothing more", () async {
    final answer = await openSheet("personal_sign", [utf8Hex("hello"), _addressA]);
    rig.isOnline = false;
    answer.complete(WCBottomSheetResult.reject);
    await rig.settle();

    expect(await rig.replies(_topic), isEmpty);
    expect(sheets.shown, hasLength(1), reason: "only the sheet the user rejected");
  });

  group("eth_signTransaction", () {
    test(
      "an EIP-1559 result is the typed transaction eth_sendTransaction would broadcast",
      () async {
        sheets.answers.addAll([WCBottomSheetResult.one, WCBottomSheetResult.one]);
        await rig.deliver(_topic, "eip155:1", "eth_signTransaction", [transfer()]);
        await rig.settle();
        await rig.deliver(_topic, "eip155:1", "eth_sendTransaction", [transfer()]);
        await rig.settle();

        final signed = (await rig.replies(_topic)).first.result! as String;
        expect(signed, startsWith("0x02"));
        expect(signed, node.broadcasts.single);
      },
    );
  });
}
