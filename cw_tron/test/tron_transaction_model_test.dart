import "package:cw_tron/tron_transaction_model.dart";
import "package:flutter_test/flutter_test.dart";

// Wallet TCFuFnoos25WL99j9y3u92LR67mVwrTvrQ and the USDT contract TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t.
const _owner = "41191882614f605dd84703252b196c0c006b5482f8";
const _usdtContract = "41a614f803b6fd780986a42c78ec9c7f77e6ded13c";

// Real TronGrid entries of TCFuFnoos25WL99j9y3u92LR67mVwrTvrQ.
const _unlimitedApprove = {
  "ret": [
    {"contractRet": "SUCCESS", "fee": 9976400},
  ],
  "txID": "fc20c9c9489842cf105c56c80e9fce540e55f1158d68459bc625332bae5b9806",
  "block_timestamp": 1769113440000,
  "raw_data": {
    "contract": [
      {
        "parameter": {
          "value": {
            "data": "095ea7b3000000000000000000000000bbbd3bd87c268b8030bc2edae7021830af599ed2"
                "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
            "owner_address": _owner,
            "contract_address": _usdtContract,
          },
          "type_url": "type.googleapis.com/protocol.TriggerSmartContract",
        },
        "type": "TriggerSmartContract",
      },
    ],
  },
};

const _usdtTransfer = {
  "ret": [
    {"contractRet": "SUCCESS", "fee": 6428500},
  ],
  "txID": "0584051e5208526f48d05965a4e15c48f6ec84c23c71441ed6e38a8a49c17faf",
  "block_timestamp": 1768779375000,
  "raw_data": {
    "contract": [
      {
        "parameter": {
          "value": {
            "data": "a9059cbb000000000000000000000000ca5125c5947162497b1b924d6c5e282282e3351f"
                "00000000000000000000000000000000000000000000000000000000139c2440",
            "owner_address": _owner,
            "contract_address": _usdtContract,
          },
          "type_url": "type.googleapis.com/protocol.TriggerSmartContract",
        },
        "type": "TriggerSmartContract",
      },
    ],
  },
};

const _trxTransfer = {
  "ret": [
    {"contractRet": "SUCCESS", "fee": 0},
  ],
  "txID": "a5bf8fb4aa16496e53ad36fcfbe3f49c92c0e0cc0caffc97d3cc2fe8a9e16ede",
  "block_timestamp": 1791643617000,
  "raw_data": {
    "contract": [
      {
        "parameter": {
          "value": {
            "amount": 1,
            "owner_address": "415576b7edd2a7cb0ebb6f794d7f2c28aa5dc85a82",
            "to_address": _owner,
          },
          "type_url": "type.googleapis.com/protocol.TransferContract",
        },
        "type": "TransferContract",
      },
    ],
  },
};

TronTransactionModel _contractCall(String? data, {Object? callValue}) =>
    TronTransactionModel.fromJson({
      "ret": [
        {"contractRet": "SUCCESS", "fee": 1},
      ],
      "txID": "test",
      "block_timestamp": 1,
      "raw_data": {
        "contract": [
          {
            "parameter": {
              "value": {
                if (data != null) "data": data,
                if (callValue != null) "call_value": callValue,
                "owner_address": _owner,
                "contract_address": _usdtContract,
              },
            },
            "type": "TriggerSmartContract",
          },
        ],
      },
    });

String _word(String hex) => hex.padLeft(64, "0");

void main() {
  group("TronTransactionModel", () {
    test("decodes the receiver and token amount of a TRC20 transfer", () {
      final transaction = TronTransactionModel.fromJson(_usdtTransfer);

      expect(transaction.isTrc20TransferCall, isTrue);
      expect(transaction.amount, BigInt.from(329000000));
      expect(transaction.to, "TUQxi3DkhbrL9qL5EHEfAmkZbsPBGP1UnH");
      expect(transaction.from, _owner);
      expect(transaction.contractAddress, _usdtContract);
    });

    test("reads an unlimited approve as a TRX call to the contract instead of throwing", () {
      final transaction = TronTransactionModel.fromJson(_unlimitedApprove);

      expect(transaction.isError, isFalse);
      expect(transaction.isTrc20TransferCall, isFalse);
      expect(transaction.amount, BigInt.zero);
      expect(transaction.to, _usdtContract);
      expect(transaction.fee, 9976400);
    });

    test("decodes transfer amounts of 2^255 and above", () {
      final maxUint256 = (BigInt.one << 256) - BigInt.one;
      final transaction = _contractCall(
        "a9059cbb${_word("ca5125c5947162497b1b924d6c5e282282e3351f")}${"f" * 64}",
      );

      expect(transaction.isTrc20TransferCall, isTrue);
      expect(transaction.amount, maxUint256);
    });

    test("decodes 0x-prefixed, upper-case transfer calldata", () {
      final transaction = _contractCall(
        "0xA9059CBB${_word("CA5125C5947162497B1B924D6C5E282282E3351F")}${_word("139C2440")}",
      );

      expect(transaction.isTrc20TransferCall, isTrue);
      expect(transaction.amount, BigInt.from(329000000));
      expect(transaction.to, "TUQxi3DkhbrL9qL5EHEfAmkZbsPBGP1UnH");
    });

    test("reads other contract calls as the TRX sent with them", () {
      final deposit = _contractCall("d0e30db0", callValue: 5000000);
      final withdraw = _contractCall("2e1a7d4d${_word("3e8")}");
      final noCalldata = _contractCall(null, callValue: 7);
      final truncatedTransfer =
          _contractCall("a9059cbb${_word("ca5125c5947162497b1b924d6c5e282282e3351f")}");

      for (final transaction in [deposit, withdraw, noCalldata, truncatedTransfer]) {
        expect(transaction.isTrc20TransferCall, isFalse);
        expect(transaction.to, _usdtContract);
      }
      expect(deposit.amount, BigInt.from(5000000));
      expect(withdraw.amount, BigInt.zero);
      expect(noCalldata.amount, BigInt.from(7));
      expect(truncatedTransfer.amount, BigInt.zero);
    });

    test("parses call_value sent as a string", () {
      expect(_contractCall("d0e30db0", callValue: "42").amount, BigInt.from(42));
    });

    test("keeps TRX transfers unchanged", () {
      final transaction = TronTransactionModel.fromJson(_trxTransfer);

      expect(transaction.isTrc20TransferCall, isFalse);
      expect(transaction.contractAddress, isNull);
      expect(transaction.amount, BigInt.one);
      expect(transaction.to, _owner);
      expect(transaction.from, "415576b7edd2a7cb0ebb6f794d7f2c28aa5dc85a82");
    });
  });
}
