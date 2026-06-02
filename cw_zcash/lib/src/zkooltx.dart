import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cw_core/get_height_by_date_zec.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_zcash/src/util/hex.dart';
import 'package:zkool/src/rust/api/account.dart' as zkool_account;

enum TxType {
  unknown,
  selfTransfer, // 0
  receive, // 1
  sent, // 2
  unshield, // 4
  shield, // 8
  transparentSelfTransfer, // 12
}

enum NotePool { transparent, sapling, orchard, unknown }

class ZkoolTx {
  ZkoolTx(final zkool_account.Tx tx, final zkool_account.TxAccount txAccount)
    : this._tx = tx,
      this._txAccount = txAccount;
  final zkool_account.Tx _tx;
  final zkool_account.TxAccount _txAccount;

  int get height => max(
    _tx.height,
    _txAccount.height,
  ); // sometimes returns 0 - higher number would be correct in this case

  DateTime get time {
    final ts = max(_tx.time, _txAccount.time) * 1000;
    if (ts == 0) {
      return ZcashHeight.getTimeByBlockHeight(height);
    }
    return DateTime.fromMillisecondsSinceEpoch(ts);
  }

  String? get to => _txAccount.outputs.firstOrNull?.address;
  Iterable<String> get outputAddresses =>
      _txAccount.outputs.map((final o) => o.address).whereType<String>();
  String? get memo => _txAccount.memos.firstOrNull?.memo;

  String get txHash {
    final reversed = Uint8List.fromList(_txAccount.txid.reversed.toList());
    final txId = uint8ListToHex(reversed);
    return txId;
  }

  BigInt get value => _value.abs();

  BigInt get fee => value - _calcValue;

  BigInt get _value {
    if (_tx.value != 0) {
      return BigInt.from(_tx.value);
    }

    return _calcValue;
  }

  /////////// calc is short for calculator (calculated in this case)
  BigInt get _calcValue {
        final noteSum = _txAccount.notes.isEmpty
        ? BigInt.from(0)
        : _txAccount.notes.map((final note) => note.value).reduce((final a, final b) => a + b);
    final outputSum = _txAccount.outputs.isEmpty
        ? BigInt.from(0)
        : _txAccount.outputs
              .map((final output) => output.value)
              .reduce((final a, final b) => a + b);
    final spentSum = _txAccount.spends.isEmpty
        ? BigInt.from(0)
        : _txAccount.spends.map((final spent) => spent.value).reduce((final a, final b) => a + b);

    return noteSum - outputSum - spentSum;
  }

  TransactionDirection get direction {
    switch (type) {
      case TxType.selfTransfer:
      case TxType.receive:
      case TxType.unshield:
      case TxType.shield:
      case TxType.transparentSelfTransfer:
        return TransactionDirection.incoming;
      case TxType.sent:
        return TransactionDirection.outgoing;
      case TxType.unknown:
        return _value > BigInt.from(0)
            ? TransactionDirection.incoming
            : TransactionDirection.outgoing;
    }
  }

  TxType get type {
    switch (_tx.tpe) {
      case 0:
        return TxType.selfTransfer;
      case 1:
        return TxType.receive;
      case 2:
        return TxType.sent;
      case 4:
        return TxType.unshield;
      case 8:
        return TxType.shield;
      case 12:
        return TxType.transparentSelfTransfer;
      default:
        return TxType.unknown;
    }
  }

  Map<String, dynamic> toJson() => {
    "tx": {
      "id": _tx.id,
      "txid": base64.encode(_tx.txid),
      "height": _tx.height,
      "time": _tx.time,
      "value": value.toInt(),
    },
    "txaccount": {
      "id": _txAccount.id,
      "account": _txAccount.account,
      "txid": base64.encode(_txAccount.txid),
      "height": _txAccount.height,
      "time": _txAccount.time,
      "notes": _txAccount.notes.map((final note) => {
        "id": note.id,
        "pool": note.pool,
        "height": note.height,
        "tx": note.tx,
        "scope": note.scope,
        "value": note.value.toString(),
        "locked": note.locked,
      }).toList(),
      "spends": _txAccount.spends.map((final spend) => {
        "id": spend.id,
        "pool": spend.pool,
        "height": spend.height,
        "value": spend.value.toString(),
      }).toList(),
      "outputs": _txAccount.outputs.map((final output) => {
        "id": output.id,
        "pool": output.pool,
        "height": output.height,
        "value": output.value.toString(),
        "address": output.address,
      }).toList(),
      "memos": _txAccount.memos.map((final memo) => {
        "note": memo.note,
        "pool": memo.pool,
        "output": memo.output,
        "memo": memo.memo,
      }).toList()
    },
  };

  static ZkoolTx fromJson(final Map<String, dynamic> json) => ZkoolTx(
    zkool_account.Tx(
      id: json["id"],
      txid: json["txid"],
      height: json["height"],
      time: json["time"],
      value: json["value"],
    ),
    zkool_account.TxAccount(
      id: json["txaccount"]["id"],
      account: json["txaccount"]["account"],
      txid: json["txaccount"]["txid"],
      height: json["txaccount"]["height"],
      time: json["txaccount"]["time"],
      notes: (json["txaccount"]["notes"] as List<Map<String, dynamic>>)
        .map((final a) => zkool_account.TxNote(
          id: a["id"],
          pool: a["pool"],
          height: a["height"],
          tx: a["tx"],
          value: BigInt.parse(a["value"]),
          scope: a["scope"],
          locked: a["locked"],
        ),
      ).toList(),
      spends: (json["txaccount"]["spends"] as List<Map<String, dynamic>>)
        .map((final a) => zkool_account.TxSpend(
          id: a["id"],
          pool: a["pool"],
          height: a["height"],
          value: BigInt.parse(a["value"]),
        ),
      ).toList(),
      outputs: (json["txaccount"]["outputs"] as List<Map<String, dynamic>>)
        .map((final a) => zkool_account.TxOutput(
          id: a["id"],
          pool: a["pool"],
          height: a["height"],
          value: BigInt.parse(a["value"]),
          address: a["address"],
        ),
      ).toList(),
      memos: (json["txaccount"]["memos"] as List<Map<String, dynamic>>)
        .map((final a) => zkool_account.TxMemo(
          note: a["note"],
          pool: a["pool"],
          output: a["output"],
          memo: a["memo"],
        ),
      ).toList(),
    ),
  );
}