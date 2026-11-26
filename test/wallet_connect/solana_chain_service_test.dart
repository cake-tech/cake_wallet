import "dart:async";
import "dart:convert";

import "package:blockchain_utils/blockchain_utils.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/services/bottom_sheet_service.dart";
import "package:cake_wallet/src/screens/wallet_connect/services/chain_service/solana/solana_chain_id.dart";
import "package:cake_wallet/src/screens/wallet_connect/services/chain_service/solana/solana_chain_service.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:on_chain/solana/solana.dart";

import "abi_hex.dart";
import "stubs.dart";
import "wc_service_rig.dart";

const _seedA = "1111111111111111111111111111111111111111111111111111111111111111";
const _seedB = "2222222222222222222222222222222222222222222222222222222222222222";
const _recipient = "23XoPQqGw9WMsLoqTu8HMzJLD6RnXsufbKyWPLJywsCT";
const _blockhash = "GHtXQBsoZHVnNFa9YevAzFr17DJjgHXk3ycTKD5xD3Zi";
const _systemProgram = "11111111111111111111111111111111";

const _topic = "topic-of-solana-wallet-a";
const _methods = ["solana_signMessage", "solana_signTransaction", "solana_signAllTransactions"];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final chain = SolanaChainId.mainnet.chain();
  final keyA = SolanaPrivateKey.fromSeedHex(_seedA);
  final addressA = keyA.publicKey().toAddress().address;
  final addressB = SolanaPrivateKey.fromSeedHex(_seedB).publicKey().toAddress().address;
  final sheets = WcServiceRig.sheets;

  late WcServiceRig rig;
  late RigWallet walletB;

  setUp(() async {
    rig = await WcServiceRig.start();
    rig.appStore.wallet = RigWallet(
      "Solana A",
      address: addressA,
      privateKey: _seedA,
      chains: [chain],
      type: WalletType.solana,
    );
    walletB = RigWallet(
      "Solana B",
      address: addressB,
      privateKey: _seedB,
      chains: [chain],
      type: WalletType.solana,
    );

    SolanaChainService(
      reference: SolanaChainId.mainnet,
      appStore: rig.appStore,
      wcKeyService: rig.keyService,
      bottomSheetService: sheets,
      walletKit: rig.kit,
    );

    await rig.addSession(_topic, accounts: ["$chain:$addressA"], methods: _methods);
  });

  tearDown(() => expect(sheets.unscripted, isEmpty, reason: "a sheet the test did not expect"));

  Map<String, dynamic> message(String text) => {
    "message": Base58Encoder.encode(utf8.encode(text)),
    "pubkey": addressA,
  };

  SolanaTransaction solTransfer(int lamports) => SolanaTransaction(
    payerKey: SolAddress(addressA),
    recentBlockhash: SolAddress(_blockhash),
    instructions: [
      TransactionInstruction.fromBytes(
        programId: SolAddress(_systemProgram),
        instructionBytes: [...u32Le(2), ...u64Le(BigInt.from(lamports))],
        keys: [
          AccountMeta(publicKey: SolAddress(addressA), isSigner: true, isWritable: true),
          AccountMeta(publicKey: SolAddress(_recipient), isSigner: false, isWritable: true),
        ],
      ),
    ],
  );

  String encoded(SolanaTransaction transaction) =>
      transaction.serializeString(encoding: TransactionSerializeEncoding.base64);

  final requests = <String, Object? Function()>{
    "solana_signMessage": () => message("hello"),
    "solana_signTransaction": () => {"transaction": encoded(solTransfer(1000))},
    "solana_signAllTransactions": () => {
      "transactions": [encoded(solTransfer(1000)), encoded(solTransfer(2000))],
    },
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

  bool isSignedByA(List<int> signedBytes, List<int> signature) =>
      keyA.publicKey().verify(message: signedBytes, signature: signature);

  List<int> signatureBytes(Object? result) =>
      Base58Decoder.decode((result! as Map<String, dynamic>)["signature"] as String);

  group("approved requests", () {
    test("a message is signed by the wallet the sheet named", () async {
      sheets.answers.add(WCBottomSheetResult.one);
      await rig.deliver(_topic, chain, "solana_signMessage", message("hello"));
      await rig.settle();

      final sheet = sheets.signingSheets.single;
      expect(rowLines(sheet.decoded.rows), [row(S.current.wc_message_label, "hello")]);
      expect(sheet.address, addressA);

      expect(isSignedByA(utf8.encode("hello"), signatureBytes((await onlyReply()).result)), isTrue);
    });

    test("a transaction is signed over the message that was decoded", () async {
      final transaction = solTransfer(1000);
      sheets.answers.add(WCBottomSheetResult.one);
      await rig.deliver(_topic, chain, "solana_signTransaction", {
        "transaction": encoded(transaction),
      });
      await rig.settle();

      final signature = signatureBytes((await onlyReply()).result);
      expect(isSignedByA(transaction.serializeMessage(), signature), isTrue);
    });

    test("every transaction of a batch comes back signed", () async {
      final transactions = [solTransfer(1000), solTransfer(2000)];
      sheets.answers.add(WCBottomSheetResult.one);
      await rig.deliver(_topic, chain, "solana_signAllTransactions", {
        "transactions": transactions.map(encoded).toList(),
      });
      await rig.settle();

      final result = (await onlyReply()).result! as Map<String, dynamic>;
      final signed = [
        for (final entry in result["transactions"] as List)
          SolanaTransaction.deserialize(base64.decode(entry as String)),
      ];
      expect(signed, hasLength(2));
      for (var i = 0; i < signed.length; i++) {
        expect(signed[i].serializeMessage(), transactions[i].serializeMessage());
        expect(isSignedByA(signed[i].serializeMessage(), signed[i].signatures.single), isTrue);
      }
    });

    test("two messages that arrive together each get their own signature", () async {
      sheets.answers.addAll([WCBottomSheetResult.one, WCBottomSheetResult.one]);
      final ids = await rig.deliverTogether(_topic, chain, "solana_signMessage", [
        message("first message"),
        message("second message"),
      ]);
      await rig.settle();

      final replies = await rig.replies(_topic);
      expect(replies.map((reply) => reply.id), ids);
      final first = signatureBytes(replies.first.result);
      final second = signatureBytes(replies.last.result);
      expect(isSignedByA(utf8.encode("first message"), first), isTrue);
      expect(isSignedByA(utf8.encode("second message"), second), isTrue);
    });
  });

  group("the wallet is checked again after the sheet", () {
    for (final request in requests.entries) {
      test("${request.key}: no key is read before the sheet is answered", () async {
        final answer = await openSheet(request.key, request.value());
        expect(rig.keyService.privateKeyReads, 0);

        answer.complete(WCBottomSheetResult.one);
        await rig.settle();
        expect(rig.keyService.privateKeyReads, 1);
      });

      test("${request.key}: another wallet opened under the sheet gets nothing signed", () async {
        final answer = await openSheet(request.key, request.value());
        rig.appStore.wallet = walletB;
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

      test("${request.key}: a rejection is answered with user rejected and no modal", () async {
        sheets.answers.add(WCBottomSheetResult.reject);
        await rig.deliver(_topic, chain, request.key, request.value());
        await rig.settle();

        final reply = await onlyReply();
        expect(reply.errorCode, 5000);
        expect(reply.errorMessage, "User rejected.");
        expect(sheets.shown, hasLength(1));
        expect(rig.keyService.privateKeyReads, 0);
      });
    }
  });

  group("refusals before any sheet", () {
    test("a message string above 10000 characters is refused", () async {
      final params = message("a" * 7400);
      expect((params["message"] as String).length, greaterThan(10000));

      await rig.deliver(_topic, chain, "solana_signMessage", params);
      await rig.settle();

      expect((await onlyReply()).errorCode, 11002);
      expect(sheets.signingSheets, isEmpty);
      expect(sheets.shown, hasLength(1));
      expect(sheets.messages, [S.current.wc_request_malformed]);
    });

    test("a long message under the limit still reaches the sheet", () async {
      final params = message("a" * 7000);
      expect((params["message"] as String).length, lessThan(10000));

      sheets.answers.add(WCBottomSheetResult.reject);
      await rig.deliver(_topic, chain, "solana_signMessage", params);
      await rig.settle();

      expect(sheets.signingSheets, hasLength(1));
    });

    test("a batch of a hundred transactions reaches the sheet", () async {
      sheets.answers.add(WCBottomSheetResult.reject);
      await rig.deliver(_topic, chain, "solana_signAllTransactions", {
        "transactions": List.filled(100, encoded(solTransfer(1000))),
      });
      await rig.settle();

      expect(sheets.signingSheets, hasLength(1));
    });

    test("a batch of a hundred and one is refused and the limit is named", () async {
      await rig.deliver(_topic, chain, "solana_signAllTransactions", {
        "transactions": List.filled(101, encoded(solTransfer(1000))),
      });
      await rig.settle();

      expect((await onlyReply()).errorCode, 11002);
      expect(sheets.signingSheets, isEmpty);
      expect(sheets.messages, [S.current.wc_too_many_transactions("100")]);
    });

    test("a batch over the limit is refused for its size, before its entries are read", () async {
      await rig.deliver(_topic, chain, "solana_signAllTransactions", {
        "transactions": List.filled(101, "AAAA"),
      });
      await rig.settle();

      expect(sheets.messages, [S.current.wc_too_many_transactions("100")]);
    });

    test("a batch with no transactions is refused before the sheet", () async {
      await rig.deliver(_topic, chain, "solana_signAllTransactions", {"transactions": <String>[]});
      await rig.settle();

      expect((await onlyReply()).errorCode, 11002);
      expect(sheets.signingSheets, isEmpty);
      expect(sheets.messages, [S.current.wc_request_malformed]);
    });

    test("a batch with one unreadable entry is refused before the sheet", () async {
      await rig.deliver(_topic, chain, "solana_signAllTransactions", {
        "transactions": [encoded(solTransfer(1000)), "AAAA"],
      });
      await rig.settle();

      expect((await onlyReply()).errorCode, 11002);
      expect(sheets.signingSheets, isEmpty);
      expect(sheets.shown, hasLength(1));
    });

    SolanaTransaction transferFromB() => SolanaTransaction(
      payerKey: SolAddress(addressB),
      recentBlockhash: SolAddress(_blockhash),
      instructions: [
        TransactionInstruction.fromBytes(
          programId: SolAddress(_systemProgram),
          instructionBytes: [...u32Le(2), ...u64Le(BigInt.from(1000))],
          keys: [
            AccountMeta(publicKey: SolAddress(addressB), isSigner: true, isWritable: true),
            AccountMeta(publicKey: SolAddress(addressA), isSigner: false, isWritable: true),
          ],
        ),
      ],
    );

    Future<void> expectRefusedAsForAnotherWallet() async {
      await rig.settle();

      final reply = await onlyReply();
      expect(reply.errorCode, 4100);
      expect(reply.result, isNull);
      expect(sheets.signingSheets, isEmpty);
      expect(sheets.messages, [S.current.wc_request_for_different_wallet]);
      expect(rig.keyService.privateKeyReads, 0);
    }

    test("a message for a pubkey that is not the wallet's is refused", () async {
      await rig.deliver(_topic, chain, "solana_signMessage", {
        ...message("hello"),
        "pubkey": addressB,
      });
      await expectRefusedAsForAnotherWallet();
    });

    test("a transaction for a pubkey that is not the wallet's is refused", () async {
      await rig.deliver(_topic, chain, "solana_signTransaction", {
        "transaction": encoded(solTransfer(1000)),
        "pubkey": addressB,
      });
      await expectRefusedAsForAnotherWallet();
    });

    test("a transaction the wallet is not a signer of is refused", () async {
      await rig.deliver(_topic, chain, "solana_signTransaction", {
        "transaction": encoded(transferFromB()),
      });
      await expectRefusedAsForAnotherWallet();
    });

    test("a batch with one transaction the wallet is not a signer of is refused", () async {
      await rig.deliver(_topic, chain, "solana_signAllTransactions", {
        "transactions": [encoded(solTransfer(1000)), encoded(transferFromB())],
      });
      await expectRefusedAsForAnotherWallet();
    });

    String withByteAfterMessage() => base64.encode([...solTransfer(1000).serialize(), 0]);

    final requestsWithByteAfterMessage = <String, Object? Function()>{
      "solana_signTransaction": () => {"transaction": withByteAfterMessage()},
      "solana_signAllTransactions": () => {
        "transactions": [withByteAfterMessage()],
      },
    };
    for (final request in requestsWithByteAfterMessage.entries) {
      test("${request.key}: a transaction with bytes after its message is refused", () async {
        await rig.deliver(_topic, chain, request.key, request.value());
        await rig.settle();

        expect((await onlyReply()).errorCode, 11002);
        expect(sheets.signingSheets, isEmpty);
        expect(sheets.messages, [S.current.wc_request_malformed]);
      });
    }

    test("a refusal does not open the dApp, an approval does", () async {
      const redirectTopic = "topic-with-redirect";
      await rig.addSession(
        redirectTopic,
        accounts: ["$chain:$addressA"],
        methods: _methods,
        redirect: WcServiceRig.dappRedirect,
      );
      rig.recordOpenedUrls();

      await rig.deliver(redirectTopic, chain, "solana_signTransaction", {"transaction": "AAAA"});
      await rig.settle();
      expect(await rig.replies(redirectTopic), hasLength(1));
      expect(rig.openedUrls, isEmpty);

      sheets.answers.add(WCBottomSheetResult.one);
      await rig.deliver(redirectTopic, chain, "solana_signMessage", message("hello"));
      await rig.settle();
      expect(rig.openedUrls, [WcServiceRig.dappRedirect]);
    });
  });
}
