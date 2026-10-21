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

// Rows captured from api.trongrid.io and apilist.tronscanapi.com for the same transactions.
const gridTrxTransfer = {
  "ret": [
    {"contractRet": "SUCCESS", "fee": 0},
  ],
  "txID": "8f9858970853f9d97c7ac7e4a6ae14e83bcd2a6d942225884392c87b2b595e3d",
  "block_timestamp": 1775113647000,
  "raw_data": {
    "contract": [
      {
        "parameter": {
          "value": {
            "amount": 1000000,
            "owner_address": "41c48b923f5a53c7edb5ae5583d12cdf5b3edc0a17",
            "to_address": "410583a68a3bcd86c25ab1bee482bac04a216b0261",
          },
          "type_url": "type.googleapis.com/protocol.TransferContract",
        },
        "type": "TransferContract",
      },
    ],
  },
};

const scanTrxTransfer = {
  "hash": "8f9858970853f9d97c7ac7e4a6ae14e83bcd2a6d942225884392c87b2b595e3d",
  "timestamp": 1775113647000,
  "ownerAddress": "TTtSeEtTFRHyXu17TgKKNJucbWba2k8tTu",
  "toAddress": "TAUN6FwrnwwmaEqYcckffC7wYmbaS6cBiX",
  "contractType": 1,
  "confirmed": true,
  "contractRet": "SUCCESS",
  "contractData": {
    "amount": 1000000,
    "owner_address": "TTtSeEtTFRHyXu17TgKKNJucbWba2k8tTu",
    "to_address": "TAUN6FwrnwwmaEqYcckffC7wYmbaS6cBiX",
  },
  "cost": {"net_fee": 0, "fee": 0, "energy_fee": 0, "net_usage": 267},
  "amount": "1000000",
};

const trc20TransferData = "a9059cbb0000000000000000000000412a68baf67f1c497d9a4a609276a90dcd6ea77444"
    "0000000000000000000000000000000000000000000000007facf7419d980000";

const gridTrc20Call = {
  "ret": [
    {"contractRet": "SUCCESS", "fee": 2896950},
  ],
  "txID": "c762c9c47613f2b1d44d9e1a20ad429a4be0c12c62d96d4cefbb322b65ee5489",
  "block_timestamp": 1750130163000,
  "raw_data": {
    "contract": [
      {
        "parameter": {
          "value": {
            "data": trc20TransferData,
            "owner_address": "410583a68a3bcd86c25ab1bee482bac04a216b0261",
            "contract_address": "4183c91bfde3e6d130e286a3722f171ae49fb25047",
          },
          "type_url": "type.googleapis.com/protocol.TriggerSmartContract",
        },
        "type": "TriggerSmartContract",
      },
    ],
  },
};

const scanTrc20Call = {
  "hash": "c762c9c47613f2b1d44d9e1a20ad429a4be0c12c62d96d4cefbb322b65ee5489",
  "timestamp": 1750130163000,
  "ownerAddress": "TAUN6FwrnwwmaEqYcckffC7wYmbaS6cBiX",
  "toAddress": "TMz2SWatiAtZVVcH2ebpsbVtYwUPT9EdjH",
  "contractType": 31,
  "confirmed": true,
  "contractRet": "SUCCESS",
  "contractData": {
    "data": trc20TransferData,
    "owner_address": "TAUN6FwrnwwmaEqYcckffC7wYmbaS6cBiX",
    "contract_address": "TMz2SWatiAtZVVcH2ebpsbVtYwUPT9EdjH",
  },
  "cost": {"net_fee": 0, "fee": 2896950, "energy_fee": 2896950, "net_usage": 345},
  "amount": "0",
};

const scanTrc10Transfer = {
  "hash": "7b843fc26d87d1583d909710dd7e3f07cab76affff9fd35746bfa7f7293eb6ff",
  "timestamp": 1782880338000,
  "ownerAddress": "TRX5YXo3M8XVUoxsmhx1hZdtBmT5rN7TjH",
  "toAddress": "TAUN6FwrnwwmaEqYcckffC7wYmbaS6cBiX",
  "contractType": 2,
  "confirmed": true,
  "contractRet": "SUCCESS",
  "contractData": {
    "amount": 970000,
    "asset_name": "1005141",
    "owner_address": "TRX5YXo3M8XVUoxsmhx1hZdtBmT5rN7TjH",
    "to_address": "TAUN6FwrnwwmaEqYcckffC7wYmbaS6cBiX",
  },
  "cost": {"net_fee": 0, "fee": 0, "energy_fee": 0, "net_usage": 281},
  "amount": "970000",
};

const scanUndelegate = {
  "hash": "f05323cc2b5d0a25f61f2befed44864494fbd9149a19e08a2abe58aafc30dba2",
  "timestamp": 1775724123000,
  "ownerAddress": "THUjNNpPxH7nz3ScL1ZTRoxjyBkzFAxcrs",
  "toAddress": "TAUN6FwrnwwmaEqYcckffC7wYmbaS6cBiX",
  "contractType": 58,
  "confirmed": true,
  "contractRet": "SUCCESS",
  "contractData": {
    "balance": 7061000000,
    "resource": "ENERGY",
    "receiver_address": "TAUN6FwrnwwmaEqYcckffC7wYmbaS6cBiX",
    "owner_address": "THUjNNpPxH7nz3ScL1ZTRoxjyBkzFAxcrs",
  },
  "cost": {"net_fee": 283000, "fee": 283000, "energy_fee": 0, "net_usage": 0},
  "amount": "0",
};

const gridTrc20Transfer = {
  "transaction_id": "b5abdf3be3510755feab4e14b663fce9678a48ad717ac73e861672dfba2286c4",
  "token_info": {
    "symbol": "OCOS",
    "address": "TQ4VkSbKXB3YUDoD6PZSYmpeuFj6QzCf39",
    "decimals": 18,
    "name": "OCOS UK",
  },
  "block_timestamp": 1784578860000,
  "from": "TCeKLAgA3mQhrWLtLZJHBiFXbcnh55qrcV",
  "to": "TAUN6FwrnwwmaEqYcckffC7wYmbaS6cBiX",
  "type": "Transfer",
  "value": "550000000000000000000",
};

const scanTrc20Transfer = {
  "transaction_id": "b5abdf3be3510755feab4e14b663fce9678a48ad717ac73e861672dfba2286c4",
  "block_ts": 1784578860000,
  "from_address": "TCeKLAgA3mQhrWLtLZJHBiFXbcnh55qrcV",
  "to_address": "TAUN6FwrnwwmaEqYcckffC7wYmbaS6cBiX",
  "contract_address": "TQ4VkSbKXB3YUDoD6PZSYmpeuFj6QzCf39",
  "quant": "550000000000000000000",
  "event_type": "Transfer",
  "confirmed": true,
  "contractRet": "SUCCESS",
  "tokenInfo": {
    "tokenId": "TQ4VkSbKXB3YUDoD6PZSYmpeuFj6QzCf39",
    "tokenAbbr": "OCOS",
    "tokenName": "OCOS UK",
    "tokenDecimal": 18,
    "tokenType": "trc20",
  },
  "contract_type": "trc20",
};

Map<String, Object?> walletFields(TronTransactionModel model) => {
      "isError": model.isError,
      "type": model.contracts?.first.type,
      "from": model.from,
      "to": model.to,
      "amount": model.amount,
      "fee": model.fee,
      "date": model.date,
      "contractAddress": model.contractAddress,
      "isTrc20TransferCall": model.isTrc20TransferCall,
    };

TronTransactionModel contractCall(String? data) => TronTransactionModel(
      contracts: [
        Contract(
          parameter: Parameter(
            value: Value(contractAddress: "4183c91bfde3e6d130e286a3722f171ae49fb25047", data: data),
          ),
        ),
      ],
    );

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

  group("TronTransactionModel.fromTronScanJson", () {
    test("TRX transfer reads the same as the TronGrid row", () {
      final fields = walletFields(TronTransactionModel.fromTronScanJson(scanTrxTransfer));

      expect(fields, walletFields(TronTransactionModel.fromJson(gridTrxTransfer)));
      expect(fields["type"], "TransferContract");
      expect(fields["from"], "41c48b923f5a53c7edb5ae5583d12cdf5b3edc0a17");
      expect(fields["to"], "410583a68a3bcd86c25ab1bee482bac04a216b0261");
      expect(fields["amount"], BigInt.from(1000000));
      expect(fields["fee"], 0);
      expect(fields["date"], DateTime.fromMillisecondsSinceEpoch(1775113647000));
      expect(fields["isTrc20TransferCall"], isFalse);
    });

    test("TRC20 transfer call reads the same as the TronGrid row", () {
      final fields = walletFields(TronTransactionModel.fromTronScanJson(scanTrc20Call));

      expect(fields, walletFields(TronTransactionModel.fromJson(gridTrc20Call)));
      expect(fields["type"], "TriggerSmartContract");
      expect(fields["from"], "410583a68a3bcd86c25ab1bee482bac04a216b0261");
      expect(fields["to"], "TDqSquXBgUCLYvYC4XZgrprLK589dkhSCf");
      expect(fields["amount"], BigInt.parse("9200000000000000000"));
      expect(fields["fee"], 2896950);
      expect(fields["contractAddress"], "4183c91bfde3e6d130e286a3722f171ae49fb25047");
      expect(fields["isTrc20TransferCall"], isTrue);
    });

    test("TRC10 transfer carries the type name the wallet filters on", () {
      final model = TronTransactionModel.fromTronScanJson(scanTrc10Transfer);

      expect(model.contracts?.first.type, "TransferAssetContract");
      expect(model.amount, BigInt.from(970000));
      expect(model.contracts?.first.parameter?.value?.assetName, "1005141");
    });

    test("resource undelegation has a fee but no recipient or amount", () {
      final model = TronTransactionModel.fromTronScanJson(scanUndelegate);

      expect(model.contracts?.first.type, "UnDelegateResourceContract");
      expect(model.from, "41525e4afdb1a3891f276bfb12de592e949bb734c2");
      expect(model.to, isNull);
      expect(model.amount, BigInt.zero);
      expect(model.fee, 283000);
      expect(model.isError, isFalse);
    });

    test("failed call is an error", () {
      final row = {...scanTrxTransfer, "contractRet": "OUT_OF_ENERGY"};

      expect(TronTransactionModel.fromTronScanJson(row).isError, isTrue);
    });

    test("row without contractType throws instead of parsing", () {
      final row = {...scanTrxTransfer}..remove("contractType");

      expect(() => TronTransactionModel.fromTronScanJson(row), throwsA(isA<TypeError>()));
    });

    test("row with an address that is not base58 throws instead of parsing", () {
      final row = {
        ...scanTrxTransfer,
        "contractData": {"amount": 1000000, "owner_address": "not an address"},
      };

      expect(() => TronTransactionModel.fromTronScanJson(row), throwsA(isA<Exception>()));
    });
  });

  group("TronTRC20TransactionModel.fromTronScanJson", () {
    test("reads the same as the TronGrid row", () {
      final scan = TronTRC20TransactionModel.fromTronScanJson(scanTrc20Transfer);
      final grid = TronTRC20TransactionModel.fromJson(gridTrc20Transfer);

      expect(scan.hash, grid.hash);
      expect(scan.from, "TCeKLAgA3mQhrWLtLZJHBiFXbcnh55qrcV");
      expect(scan.to, "TAUN6FwrnwwmaEqYcckffC7wYmbaS6cBiX");
      expect(scan.amount, BigInt.parse("550000000000000000000"));
      expect(scan.amount, grid.amount);
      expect(scan.currency.symbol, "OCOS");
      expect(scan.currency.decimals, 18);
      expect(scan.date, DateTime.fromMillisecondsSinceEpoch(1784578860000));
      expect(scan.date, grid.date);
      expect(scan.fee, 0);
    });

    test("row with a numeric quant throws instead of parsing", () {
      final row = {...scanTrc20Transfer, "quant": 550};

      expect(() => TronTRC20TransactionModel.fromTronScanJson(row), throwsA(isA<TypeError>()));
    });
  });

  group("isTrc20TransferCall", () {
    test("transfer calldata", () {
      expect(contractCall(trc20TransferData).isTrc20TransferCall, isTrue);
    });

    test("0x prefixed transfer calldata", () {
      expect(contractCall("0x$trc20TransferData").isTrc20TransferCall, isTrue);
    });

    test("approve calldata", () {
      final approveData = "095ea7b3${trc20TransferData.substring(8)}";

      expect(contractCall(approveData).isTrc20TransferCall, isFalse);
    });

    test("transfer selector without its arguments", () {
      expect(contractCall("a9059cbb").isTrc20TransferCall, isFalse);
      expect(contractCall(trc20TransferData.substring(0, 72)).isTrc20TransferCall, isFalse);
    });

    test("no calldata", () {
      expect(contractCall(null).isTrc20TransferCall, isFalse);
    });
  });
}
