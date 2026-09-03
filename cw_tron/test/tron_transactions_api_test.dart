import "package:cw_tron/tron_grid_api.dart";
import "package:cw_tron/tron_scan_api.dart";
import "package:flutter_test/flutter_test.dart";

class CannedTronScanApi extends TronScanApi {
  CannedTronScanApi(this.rows);

  final List<Map<String, dynamic>> rows;

  @override
  Future<List<Map<String, dynamic>>> fetchConfirmedRows(
    String path,
    String rowsKey,
    Map<String, String> query,
  ) async =>
      rows;
}

class CannedTronGridApi extends TronGridApi {
  CannedTronGridApi(this.page);

  final Map<String, dynamic> page;

  @override
  Future<Map<String, dynamic>> fetchPage(String path) async => page;
}

const scanTrxRow = {
  "hash": "scan-trx-row",
  "contractType": 1,
  "contractRet": "SUCCESS",
  "timestamp": 1775113647000,
  "cost": {"fee": 0},
  "contractData": {
    "amount": 1000000,
    "owner_address": "TTtSeEtTFRHyXu17TgKKNJucbWba2k8tTu",
    "to_address": "TAUN6FwrnwwmaEqYcckffC7wYmbaS6cBiX",
  },
};

const scanBrokenRow = {
  "hash": "scan-broken-row",
  "contractType": 1,
  "contractRet": "SUCCESS",
  "timestamp": 1775113647000,
  "contractData": {"owner_address": "not an address"},
};

const scanTrc20Row = {
  "transaction_id": "scan-transfer",
  "block_ts": 1784578860000,
  "from_address": "TCeKLAgA3mQhrWLtLZJHBiFXbcnh55qrcV",
  "to_address": "TAUN6FwrnwwmaEqYcckffC7wYmbaS6cBiX",
  "quant": "550",
  "event_type": "Transfer",
  "contractRet": "SUCCESS",
  "tokenInfo": {"tokenAbbr": "OCOS", "tokenDecimal": 18, "tokenType": "trc20"},
};

const scanTrc721Row = {
  "transaction_id": "scan-nft",
  "block_ts": 1784578860000,
  "quant": "12345",
  "event_type": "Transfer",
  "contractRet": "SUCCESS",
  "tokenInfo": {"tokenAbbr": "NFT", "tokenDecimal": 0, "tokenType": "trc721"},
};

const scanApprovalRow = {
  "transaction_id": "scan-approval",
  "block_ts": 1784578860000,
  "quant": "999",
  "event_type": "Approval",
  "contractRet": "SUCCESS",
  "tokenInfo": {"tokenAbbr": "OCOS", "tokenDecimal": 18, "tokenType": "trc20"},
};

const scanRevertRow = {
  "transaction_id": "scan-revert",
  "block_ts": 1784578860000,
  "quant": "7",
  "event_type": "Transfer",
  "contractRet": "REVERT",
  "tokenInfo": {"tokenAbbr": "OCOS", "tokenDecimal": 18, "tokenType": "trc20"},
};

const gridTransferRow = {
  "transaction_id": "grid-transfer",
  "type": "Transfer",
  "token_info": {"symbol": "OCOS", "decimals": 18},
  "block_timestamp": 1784578860000,
  "from": "TCeKLAgA3mQhrWLtLZJHBiFXbcnh55qrcV",
  "to": "TAUN6FwrnwwmaEqYcckffC7wYmbaS6cBiX",
  "value": "550",
};

const gridApprovalRow = {
  "transaction_id": "grid-approval",
  "type": "Approval",
  "token_info": {"symbol": "OCOS", "decimals": 18},
  "block_timestamp": 1784578860000,
  "from": "TCeKLAgA3mQhrWLtLZJHBiFXbcnh55qrcV",
  "to": "TAUN6FwrnwwmaEqYcckffC7wYmbaS6cBiX",
  "value": "115792089237316195423570985008687907853269984665640564039457584007913129639935",
};

void main() {
  group("TronScanApi.getTransactions", () {
    test("keeps parsable rows and skips a malformed one", () async {
      final txs = await CannedTronScanApi([scanTrxRow, scanBrokenRow]).getTransactions("TAddress");

      expect(txs.single.hash, "scan-trx-row");
    });

    test("throws when every row fails to parse", () {
      expect(
        CannedTronScanApi([scanBrokenRow]).getTransactions("TAddress"),
        throwsA(isA<Exception>()),
      );
    });

    test("no rows is a legitimate empty history", () async {
      expect(await CannedTronScanApi([]).getTransactions("TAddress"), isEmpty);
    });
  });

  group("TronScanApi.getTrc20Transactions", () {
    test("keeps only successful trc20 transfers", () async {
      final transfers = await CannedTronScanApi(
        [scanTrc20Row, scanTrc721Row, scanApprovalRow, scanRevertRow],
      ).getTrc20Transactions("TAddress");

      expect(transfers.single.hash, "scan-transfer");
    });

    test("throws when every row is filtered out", () {
      expect(
        CannedTronScanApi([scanTrc721Row, scanApprovalRow]).getTrc20Transactions("TAddress"),
        throwsA(isA<Exception>()),
      );
    });
  });

  group("TronGridApi.getTrc20Transactions", () {
    test("drops Approval events", () async {
      final transfers = await CannedTronGridApi({
        "data": [gridTransferRow, gridApprovalRow],
      }).getTrc20Transactions("TAddress");

      expect(transfers.single.hash, "grid-transfer");
      expect(transfers.single.amount, BigInt.from(550));
    });
  });
}
