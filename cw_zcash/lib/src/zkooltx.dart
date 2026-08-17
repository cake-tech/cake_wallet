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

enum NotePool { transparent, sapling, orchard, ironwood }

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
    if (ts != 0) {
      return DateTime.fromMillisecondsSinceEpoch(ts);
    }
    if (height == 0) {
      return DateTime.now();
    }
    return ZcashHeight.getTimeByBlockHeight(height);
  }

  String? get to => _txAccount.outputs.firstOrNull?.address;
  Iterable<String> get outputAddresses =>
      _txAccount.outputs.map((final o) => o.address).whereType<String>();
  Iterable<({String address, int pool, BigInt value})> get outputsWithAddress => _txAccount.outputs
      .where((final o) => o.address.isNotEmpty)
      .map((final o) => (address: o.address, pool: o.pool, value: o.value));
  Iterable<int> get spendPools => _txAccount.spends.map((final s) => s.pool);
  Iterable<int> get notePools => _txAccount.notes.map((final n) => n.pool);
  String? get memo => _txAccount.memos.firstOrNull?.memo;

  BigInt get transparentOrSaplingSpent {
    if (_txAccount.spends.isEmpty) {
      return BigInt.zero;
    }
    return _txAccount.spends
        .where(
          (final s) => s.pool == NotePool.transparent.index || s.pool == NotePool.sapling.index,
        )
        .fold(BigInt.zero, (final a, final s) => a + s.value);
  }

  BigInt get orchardReceived {
    final fromNotes = _txAccount.notes
        .where((final n) => n.pool == NotePool.orchard.index)
        .fold(BigInt.zero, (final a, final n) => a + n.value);
    if (fromNotes > BigInt.zero) {
      return fromNotes;
    }
    return _txAccount.outputs
        .where((final o) => o.pool == NotePool.orchard.index)
        .fold(BigInt.zero, (final a, final o) => a + o.value);
  }

  BigInt get ironwoodReceived {
    final fromNotes = _txAccount.notes
        .where((final n) => n.pool == NotePool.ironwood.index)
        .fold(BigInt.zero, (final a, final n) => a + n.value);
    if (fromNotes > BigInt.zero) {
      return fromNotes;
    }
    return _txAccount.outputs
        .where((final o) => o.pool == NotePool.ironwood.index)
        .fold(BigInt.zero, (final a, final o) => a + o.value);
  }

  BigInt get orchardSpent => _txAccount.spends
      .where((final s) => s.pool == NotePool.orchard.index)
      .fold(BigInt.zero, (final a, final s) => a + s.value);

  String get txHash {
    final reversed = Uint8List.fromList(_txAccount.txid.reversed.toList());
    final txId = uint8ListToHex(reversed);
    return txId;
  }

  BigInt get value => _value.abs();

  BigInt get fee => BigInt.from(_tx.fee);


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
      
      "tpe": _tx.tpe,
      "zsaValue": _tx.zsaValue,
      "assetDisplay": _tx.assetDisplay,
    },
    "txaccount": {
      "id": _txAccount.id,
      "account": _txAccount.account,
      "txid": base64.encode(_txAccount.txid),
      "height": _txAccount.height,
      "time": _txAccount.time,
      "notes": _txAccount.notes
          .map(
            (final note) => {
              "id": note.id,
              "pool": note.pool,
              "height": note.height,
              "tx": note.tx,
              "scope": note.scope,
              "value": note.value.toString(),
              "locked": note.locked,
            },
          )
          .toList(),
      "spends": _txAccount.spends
          .map(
            (final spend) => {
              "id": spend.id,
              "pool": spend.pool,
              "height": spend.height,
              "value": spend.value.toString(),
              "assetDisplay": spend.assetDisplay,
            },
          )
          .toList(),
      "outputs": _txAccount.outputs
          .map(
            (final output) => {
              "id": output.id,
              "pool": output.pool,
              "height": output.height,
              "value": output.value.toString(),
              "address": output.address,
            },
          )
          .toList(),
      "memos": _txAccount.memos
          .map(
            (final memo) => {
              "note": memo.note,
              "pool": memo.pool,
              "output": memo.output,
              "memo": memo.memo,
            },
          )
          .toList(),
    },
  };

  static int _asInt(final dynamic value, {final int fallback = 0}) {
    if (value == null) {
      return fallback;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.parse(value.toString());
  }

  static Uint8List _txidFromJson(final dynamic raw) {
    return _bytesFromJson(raw, fieldName: "txid");
  }

  static Uint8List _bytesFromJson(final dynamic raw, {required final String fieldName}) {
    if (raw == null) {
      return Uint8List(0);
    }
    if (raw is Uint8List) {
      return raw;
    }
    if (raw is List) {
      return Uint8List.fromList(List<int>.from(raw));
    }
    if (raw is String) {
      return base64.decode(raw);
    }
    throw FormatException("Invalid $fieldName in ZkoolTx json: $raw");
  }

  static List<T> _listFromJson<T>(final dynamic raw, final T Function(Map<String, dynamic>) parse) {
    if (raw is! List) {
      return const [];
    }
    return raw.map((final entry) => parse(Map<String, dynamic>.from(entry as Map))).toList();
  }

  static ZkoolTx fromJson(final Map<String, dynamic> json) {
    final txJson = Map<String, dynamic>.from((json["tx"] as Map?)?.cast<String, dynamic>() ?? json);
    final txAccountJson = Map<String, dynamic>.from(
      (json["txaccount"] as Map?)?.cast<String, dynamic>() ?? json,
    );

    return ZkoolTx(
      zkool_account.Tx(
        id: _asInt(txJson["id"]),
        txid: _txidFromJson(txJson["txid"]),
        height: _asInt(txJson["height"]),
        time: _asInt(txJson["time"]),
        value: _asInt(txJson["value"]),
        fee: _asInt(txJson["fee"]),
        tpe: txJson["tpe"] == null ? null : _asInt(txJson["tpe"]),
        zsaValue: _asInt(txJson["zsaValue"]),
        assetDisplay: txJson["assetDisplay"] as String? ?? "",
        isUserMemo: txJson["isUserMemo"] as bool? ?? false,
      ),
      zkool_account.TxAccount(
        id: _asInt(txAccountJson["id"]),
        account: _asInt(txAccountJson["account"]),
        txid: _txidFromJson(txAccountJson["txid"]),
        height: _asInt(txAccountJson["height"]),
        time: _asInt(txAccountJson["time"]),
        notes: _listFromJson(
          txAccountJson["notes"],
          (final a) => zkool_account.TxNote(
            id: _asInt(a["id"]),
            pool: _asInt(a["pool"]),
            height: _asInt(a["height"]),
            tx: _asInt(a["tx"]),
            value: BigInt.parse(a["value"].toString()),
            scope: _asInt(a["scope"]),
            locked: a["locked"] as bool? ?? false,
            assetDisplay: a["assetDisplay"] as String? ?? "",
          ),
        ),
        spends: _listFromJson(
          txAccountJson["spends"],
          (final a) => zkool_account.TxSpend(
            id: _asInt(a["id"]),
            pool: _asInt(a["pool"]),
            height: _asInt(a["height"]),
            value: BigInt.parse(a["value"].toString()),
            assetDisplay: a["assetDisplay"] as String? ?? "",
          ),
        ),
        outputs: _listFromJson(
          txAccountJson["outputs"],
          (final a) => zkool_account.TxOutput(
            id: _asInt(a["id"]),
            pool: _asInt(a["pool"]),
            height: _asInt(a["height"]),
            value: BigInt.parse(a["value"].toString()),
            address: a["address"] as String? ?? "",
          ),
        ),
        memos: _listFromJson(
          txAccountJson["memos"],
          (final a) => zkool_account.TxMemo(
            note: a["note"] == null ? null : _asInt(a["note"]),
            pool: _asInt(a["pool"]),
            output: a["output"] == null ? null : _asInt(a["output"]),
            memo: a["memo"] as String?,
            memoBytes: _bytesFromJson(a["memoBytes"], fieldName: "memoBytes"),
          ),
        ),
      ),
    );
  }
}
