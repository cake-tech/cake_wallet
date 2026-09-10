import "dart:convert";

import "package:blockchain_utils/blockchain_utils.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/services/chain_service/tron/tron_transaction_summary.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";
import "package:on_chain/tron/tron.dart";

final owner = TronAddress("TCaucrAr4itZrmpjK1Pg4CVS7bym2QiFG4");
final recipient = TronAddress("TLyqzVGLV1srkB7dToTAEqgDSfPtXRJZYH");
final spender = TronAddress("TDPAjxBZZkzVJ45CJKi7TY7jJHxGgKk5fr");
final usdtContract = TronAddress("TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t");
final walletTokens = {usdtContract.toAddress(): CryptoCurrency.usdttrc20};

const transferSelector = "a9059cbb";
const approveSelector = "095ea7b3";
final maxUint256 = (BigInt.one << 256) - BigInt.one;

const referenceRawDataHex =
    "0a02885b2208baa1c278fd0a309f4090c1dbe5e7325aae01081f12a9010a31747970652e676f6f676c65617069"
    "732e636f6d2f70726f746f636f6c2e54726967676572536d617274436f6e747261637412740a15411cb0b7348e"
    "ded93b8d0816bbeb819fc1d7a51f31121541a614f803b6fd780986a42c78ec9c7f77e6ded13c2244095ea7b300"
    "00000000000000000000001cb0b7348eded93b8d0816bbeb819fc1d7a51f310000000000000000000000000000"
    "0000000000000000000000000000000000007082f4d7e5e73290018084af5f";
const referenceTxID = "66e79c6993f29b02725da54ab146ffb0453ee6a43b4083568ad9585da305374a";
final referenceRawData = <String, dynamic>{
  "contract": [
    {
      "parameter": {
        "value": {
          "data": "095ea7b30000000000000000000000001cb0b7348eded93b8d0816bbeb819fc1d7a51f310000"
              "000000000000000000000000000000000000000000000000000000000000",
          "owner_address": "411cb0b7348eded93b8d0816bbeb819fc1d7a51f31",
          "contract_address": "41a614f803b6fd780986a42c78ec9c7f77e6ded13c",
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

const tronWebKey = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";
const tronWebAddress = "TZ1EafTG8FRtE6ef3H2dhaucDdjv36fzPY";
const tronWebSignatures = {
  "hello tron": "0xb3f52f1aa00596407eec8ab2787501eb8d350257678005bafdad3ba3e00e18590225837a33f19"
      "39b45cc4a4c9b19247aceb95df1ca8772dc1d028a50808bfb501b",
  "ünïcödé 🎂 → Tron": "0x5b0669c613dca083edc07e6dc9825eb12a1a26468bee89ec09b8469a8faed0bd0b70ee"
      "16d3190c9c64071fe68a1becf568a28bbe6c1ff81aeb71e45361e36e5c1c",
};

List<int> trc20Call(String selector, TronAddress to, BigInt amount) => [
      ...BytesUtils.fromHexString(selector),
      ...List<int>.filled(12, 0),
      ...BytesUtils.fromHexString(to.toHex().substring(2)),
      ...BytesUtils.fromHexString(amount.toRadixString(16).padLeft(64, "0")),
    ];

TransactionRaw rawOf(TronBaseContract contract, {BigInt? feeLimit}) => TransactionRaw(
      refBlockBytes: BytesUtils.fromHexString("885b"),
      refBlockHash: BytesUtils.fromHexString("baa1c278fd0a309f"),
      expiration: BigInt.from(1745849082000),
      timestamp: BigInt.from(1745849022978),
      feeLimit: feeLimit,
      contract: [
        TransactionContract(
          type: contract.contractType,
          parameter: Any(typeUrl: contract.typeURL, value: contract),
        ),
      ],
    );

TronTransactionSummary summaryOfCall(
  String selector,
  TronAddress to,
  BigInt amount, {
  BigInt? feeLimit,
  BigInt? callValue,
}) =>
    TronTransactionSummary.of(
      rawOf(
        TriggerSmartContract(
          ownerAddress: owner,
          contractAddress: usdtContract,
          data: trc20Call(selector, to, amount),
          callValue: callValue,
        ),
        feeLimit: feeLimit,
      ),
      walletTokens,
    );

void main() {
  setUpAll(() => S.current = const S());

  group("TRC20 calls", () {
    test("a transfer names the operation and labels the counterparty as the recipient", () {
      final summary = summaryOfCall(transferSelector, recipient, BigInt.from(5000000));

      expect(summary.text.split("\n").first, S.current.send);
      expect(summary.text, contains("${S.current.value}: 5 USDT"));
      expect(summary.text, contains("${S.current.to}: ${recipient.toAddress()}"));
      expect(summary.text, isNot(contains(S.current.wc_approved_address)));
      expect(summary.ownerAddress, owner.toAddress());
    });

    test("an approve names the operation and labels the counterparty as the spender", () {
      final summary = summaryOfCall(approveSelector, spender, maxUint256);

      expect(summary.text.split("\n").first, S.current.approve_tokens);
      expect(summary.text, contains("${S.current.wc_approved_address}: ${spender.toAddress()}"));
      expect(summary.text, isNot(contains("${S.current.to}: ")));
      expect(summary.text, contains(S.current.wc_unlimited));
    });

    test("approve and transfer do not read the same", () {
      final transfer = summaryOfCall(transferSelector, recipient, BigInt.from(5000000));
      final approve = summaryOfCall(approveSelector, spender, BigInt.from(5000000));

      expect(transfer.text.split("\n").first, isNot(approve.text.split("\n").first));
    });

    test("an allowance below the sentinel keeps its exact amount", () {
      final summary = summaryOfCall(approveSelector, spender, BigInt.from(5000000));

      expect(summary.text, contains("${S.current.value}: 5 USDT"));
      expect(summary.text, isNot(contains(S.current.wc_unlimited)));
    });

    test("call data that is not a clean 68 byte TRC20 call is never decoded", () {
      final short = trc20Call(transferSelector, recipient, BigInt.from(5000000))..removeLast();
      final dirtyPadding = trc20Call(transferSelector, recipient, BigInt.from(5000000));
      dirtyPadding[5] = 1;

      for (final data in [short, dirtyPadding, <int>[], BytesUtils.fromHexString("a9059cbb")]) {
        final summary = TronTransactionSummary.of(
          rawOf(
            TriggerSmartContract(
              ownerAddress: owner,
              contractAddress: usdtContract,
              data: data,
            ),
          ),
          walletTokens,
        );

        expect(summary.text, contains(S.current.wc_call_data));
        expect(summary.text, isNot(contains(recipient.toAddress())));
      }
    });

    test("attached TRX drops the token decoding and leaves one value line", () {
      final summary = summaryOfCall(
        transferSelector,
        recipient,
        BigInt.from(5000000),
        callValue: BigInt.from(1500000),
      );

      expect("${S.current.value}:".allMatches(summary.text).length, 1);
      expect(summary.text, contains("${S.current.value}: 1.5 TRX"));
      expect(summary.text, contains(S.current.wc_call_data));
      expect(summary.text, isNot(contains(S.current.send)));
    });
  });

  group("fee limit", () {
    test("a contract call without a fee limit shows the zero the node reads", () {
      final summary = summaryOfCall(transferSelector, recipient, BigInt.from(5000000));

      expect(
        summary.rows.any((row) => row.title == S.current.wc_max_network_fee && row.text == "0 TRX"),
        isTrue,
      );
    });

    test("a TRX transfer without a fee limit shows no fee row", () {
      final summary = TronTransactionSummary.of(
        rawOf(
          TransferContract(
            ownerAddress: owner,
            toAddress: recipient,
            amount: BigInt.from(1500000),
          ),
        ),
        walletTokens,
      );

      expect(summary.text, contains("${S.current.value}: 1.5 TRX"));
      expect(summary.rows.any((row) => row.title == S.current.wc_max_network_fee), isFalse);
    });
  });

  group("TronWeb interoperability", () {
    test("raw_data re-serializes to the raw_data_hex TronWeb sent", () {
      final rawTransaction = TransactionRaw.fromJson(referenceRawData);

      expect(BytesUtils.toHexString(rawTransaction.toBuffer()), referenceRawDataHex);
      expect(rawTransaction.txID, referenceTxID);
    });

    test("signPersonalMessage matches TronWeb signMessageV2", () {
      final key = TronPrivateKey(tronWebKey);

      expect(key.publicKey().toAddress().toAddress(), tronWebAddress);

      for (final vector in tronWebSignatures.entries) {
        expect("0x${key.signPersonalMessage(utf8.encode(vector.key))}", vector.value);
      }
    });
  });
}
