import 'package:cake_wallet/exchange/trade.dart';
import 'package:cw_core/db/sqlite.dart' as sqlite;
import 'package:sqflite/sqflite.dart';
import 'pegaroute_trade_record.dart';
import 'package:collection/collection.dart';

/// Pegaroute call sites use these writes, never generic Trade.save/REPLACE.
/// This does not fix Cake's generic save/delete or arbitrary cross-provider SQL.
class PegarouteTradeStore {
  PegarouteTradeStore([Database? database]) : _database = database;
  final Database? _database;
  Database get database => _database ?? sqlite.db!;

  Future<Trade> create(Trade trade) async {
    final captured = PegarouteTradeRecord.fromSqliteRow(trade.toSqliteMap());
    final record = PegarouteTradeRecord.read(captured);
    if (captured.internalId != 0 ||
        record.attempt != null ||
        record.approvals.isNotEmpty || record.refund != null ||
        captured.txId != null ||
        captured.outputTransaction != null ||
        captured.isRefund == true ||
        captured.stateRaw != 'created') {
      throw StateError('Not a fresh deposit');
    }
    final row = captured.toSqliteMap()..['tradeId'] = null;
    captured.internalId =
        await database.insert(Trade.tableName, row, conflictAlgorithm: ConflictAlgorithm.abort);
    Trade.onChanged.add(null);
    return captured;
  }

  Future<Trade> read(String id) async {
    final rows = await database.query(Trade.tableName, where: 'id = ?', whereArgs: [id]);
    if (rows.length != 1) throw StateError('Missing Pegaroute deposit');
    final trade = PegarouteTradeRecord.fromSqliteRow(rows.single);
    PegarouteTradeRecord.read(trade);
    return trade;
  }

  static void same(Trade expected, Trade current) {
    final before = PegarouteTradeRecord.read(expected);
    final after = PegarouteTradeRecord.read(current);
    if (expected.internalId != current.internalId ||
        before.binding != after.binding) throw StateError('Pegaroute order replaced or changed');
  }

  static void eligible(Trade trade) {
    final record = PegarouteTradeRecord.read(trade);
    if (record.attempt != null ||
        (trade.txId ?? '').isNotEmpty ||
        (trade.outputTransaction ?? '').isNotEmpty ||
        trade.isRefund == true ||
        trade.stateRaw != 'created' ||
        (trade.expiredAt != null && !DateTime.now().isBefore(trade.expiredAt!))) {
      throw StateError('Pegaroute deposit already attempted, expired or progressed');
    }
  }

  Future<Trade> latest(Trade expected) async {
    final captured = PegarouteTradeRecord.fromSqliteRow(expected.toSqliteMap());
    final current = await read(captured.id);
    same(captured, current);
    return current;
  }

  Future<Trade> claim(Trade expected, String attempt, {String? hash}) => _update(expected, (trade) {
        eligible(trade);
        final record = PegarouteTradeRecord.read(trade);
        if (record.approvals.values.any((value) => (value as Map)['state'] != 'confirmed')) {
          throw StateError('Approval has not confirmed');
        }
        trade.routerData = record.claimed(attempt, hash: hash).encode();
      });

  Future<Trade> claimApproval(Trade expected, String step, String attempt, String hash) {
    final before = PegarouteTradeRecord.read(expected).approvals;
    return _update(expected, (trade) {
      eligible(trade);
      final record = PegarouteTradeRecord.read(trade);
      if (!const DeepCollectionEquality().equals(before, record.approvals) ||
          record.approvals.containsKey(step) ||
          record.approvals.values.any((value) => (value as Map)['state'] != 'confirmed')) {
        throw StateError('Approval already attempted or changed');
      }
      trade.routerData = record.withApproval(step,
          {'id': attempt, 'hash': hash, 'state': 'claimed'}).encode();
    });
  }

  Future<Trade> approvalProgress(Trade expected, String step, String attempt,
      String hash, String state) => _update(expected, (trade) {
    final record = PegarouteTradeRecord.read(trade);
    final evidence = record.approvals[step];
    if (evidence is! Map || evidence['id'] != attempt || evidence['hash'] != hash ||
        !const {'submitted', 'confirmed', 'failed'}.contains(state)) {
      throw StateError('Approval attempt/hash mismatch');
    }
    if (const {'confirmed', 'failed'}.contains(evidence['state'])) {
      if (evidence['state'] != state) throw StateError('Approval outcome changed');
      return;
    }
    trade.routerData = record.withApproval(step,
        {'id': attempt, 'hash': hash, 'state': state}).encode();
  });

  Future<Trade> submitted(Trade expected, String attempt, String hash) =>
      _update(expected, (trade) {
        final record = PegarouteTradeRecord.read(trade);
        if (record.attempt != attempt ||
            (record.proposedHash != null && record.proposedHash != hash) ||
            hash.isEmpty ||
            ((trade.txId ?? '').isNotEmpty && trade.txId != hash)) {
          throw StateError('Funding attempt/hash mismatch');
        }
        trade.txId = hash;
      });

  /// Observations update only mutable progress, after validation against captured
  /// immutable intent. Reload/merge happens INSIDE the transaction, preserving claims.
  Future<Trade> observe(Trade expected,
          {required String state,
          String? sourceHash,
          String? outputHash,
          String? receiveAmount,
          bool refund = false,
          Map<String, dynamic>? refundObservation}) =>
      _update(expected, (trade) {
        const ranks = {
          'created': 0,
          'confirming': 1,
          'exchanging': 2,
          'sending': 3,
          'success': 4,
          'failed': 4,
          'refunded': 4
        };
        final rank = ranks[state];
        final oldRank = ranks[trade.stateRaw];
        if (rank == null || oldRank == null) throw StateError('Unknown deposit state');
        final record = PegarouteTradeRecord.read(trade);
        if (sourceHash != null && sourceHash.isNotEmpty) {
          if ((record.proposedHash != null && record.proposedHash != sourceHash) ||
              ((trade.txId ?? '').isNotEmpty && trade.txId != sourceHash)) {
            throw StateError('Conflicting source hash');
          }
          trade.txId = sourceHash;
        }
        if (outputHash != null && outputHash.isNotEmpty) {
          if ((trade.outputTransaction ?? '').isNotEmpty && trade.outputTransaction != outputHash) {
            throw StateError('Conflicting payout hash');
          }
          trade.outputTransaction = outputHash;
        }
        if (refund) trade.isRefund = true;
        if (refundObservation != null) {
          final previous = record.refund;
          const refundRanks = {'pending': 0, 'broadcasting': 1, 'completed': 2};
          if (previous != null && previous['txHash'] != null &&
              refundObservation['txHash'] != null && previous['txHash'] != refundObservation['txHash']) {
            throw StateError('Refund hash changed');
          }
          final latestWins = previous == null ||
              refundRanks[refundObservation['status']]! >= refundRanks[previous['status']]!;
          final merged = latestWins
              ? <String, dynamic>{...?previous, ...refundObservation}
              : <String, dynamic>{...refundObservation, ...previous};
          // Missing optional evidence in a later poll never erases a known hash
          // or completion time; a stale poll may still supply previously absent evidence.
          trade.routerData = record.withRefund(merged).encode();
        }
        if (rank < oldRank || (oldRank == 4 && state != trade.stateRaw)) return;
        trade.stateRaw = state;
        if (receiveAmount != null) trade.receiveAmount = receiveAmount;
      });

  Future<Trade> _update(Trade expected, void Function(Trade) update) async {
    // Capture BEFORE awaiting: Trade is a mutable Cake model.
    final captured = PegarouteTradeRecord.fromSqliteRow(expected.toSqliteMap());
    PegarouteTradeRecord.read(captured);
    final result = await database.transaction((txn) async {
      final rows = await txn.query(Trade.tableName,
          where: 'tradeId = ? AND id = ? AND providerRaw = 17',
          whereArgs: [captured.internalId, captured.id]);
      if (rows.length != 1) throw StateError('Missing Pegaroute order');
      final current = PegarouteTradeRecord.fromSqliteRow(rows.single);
      same(captured, current);
      final previous = current.routerData;
      update(current);
      PegarouteTradeRecord.read(current);
      final count = await txn.update(
          Trade.tableName,
          {
            'routerData': current.routerData,
            'txId': current.txId,
            'outputTransaction': current.outputTransaction,
            'receiveAmount': current.receiveAmount,
            'stateRaw': current.stateRaw,
            'isRefund': current.isRefund == true ? 1 : 0,
          },
          where: 'tradeId = ? AND id = ? AND providerRaw = 17 AND routerData = ?',
          whereArgs: [captured.internalId, captured.id, previous]);
      if (count != 1) throw StateError('Pegaroute update lost race');
      return current;
    });
    Trade.onChanged.add(null);
    return result;
  }
}
