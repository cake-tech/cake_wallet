import 'dart:async';

import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_zcash/src/zcash_wallet_service.dart';
import 'package:zkool/src/rust/api/coin.dart' as zkool_coin;
import 'package:zkool/src/rust/api/mempool.dart' as zkool_mempool;

typedef ZcashMempoolRefreshCallback = void Function(Set<int> accountIds);

class ZcashMempoolService {
  ZcashMempoolService._();

  static final ZcashMempoolService instance = ZcashMempoolService._();

  zkool_mempool.Mempool? _mempool;
  final Map<String, zkool_mempool.MempoolTx> _txsById = {};

  zkool_mempool.Mempool get _mempoolInstance => _mempool ??= zkool_mempool.Mempool();

  ZcashMempoolRefreshCallback? onAccountsUpdated;

  bool _loopRunning = false;
  String? _nodeUrl;
  int? _lastBlockHeight;
  StreamSubscription<zkool_mempool.MempoolMsg>? _subscription;

  void removeTx(final String txId) {
    _txsById.remove(ZcashWalletService.normalizeTxId(txId));
  }

  void removeKnownTxs(final Iterable<String> txIds) {
    for (final txId in txIds) {
      removeTx(txId);
    }
  }

  List<zkool_mempool.MempoolTx> txsForAccount(final int accountId) => _txsById.values
      .where(
        (final tx) =>
            tx.notes.any((final n) => n.account == accountId) ||
            tx.amounts.any((final a) => a.account == accountId),
      )
      .toList();

  Future<void> ensureRunning(final zkool_coin.Coin c) async {
    if (c.url.isEmpty) {
      return;
    }
    if (_loopRunning && _nodeUrl == c.url) {
      return;
    }
    await stop();
    _nodeUrl = c.url;
    _loopRunning = true;
    unawaited(_runLoop(c));
  }

  Future<void> stop() async {
    _loopRunning = false;
    await _subscription?.cancel();
    _subscription = null;
    _txsById.clear();
    _lastBlockHeight = null;
    try {
      await _mempool?.cancel();
    } catch (e) {
      printV("mempool cancel: $e");
    }
    _mempool = null;
  }

  Future<void> _runLoop(final zkool_coin.Coin c) async {
    while (_loopRunning && _nodeUrl == c.url) {
      try {
        final completer = Completer<void>();
        _subscription = _mempoolInstance
            .run(c: c)
            .listen(
              (final msg) {
                if (!_loopRunning) {
                  return;
                }
                switch (msg) {
                  case zkool_mempool.MempoolMsg_BlockHeight(:final field0):
                    _onBlockHeight(field0);
                  case zkool_mempool.MempoolMsg_TxId(:final field0):
                    _onMempoolTx(field0);
                }
              },
              onDone: () {
                if (!completer.isCompleted) {
                  completer.complete();
                }
              },
              onError: (final e) {
                printV("mempool stream error: $e");
                if (!completer.isCompleted) {
                  completer.complete();
                }
              },
            );
        await completer.future;
      } catch (e) {
        printV("mempool loop error: $e");
      }
      if (_loopRunning) {
        await Future.delayed(const Duration(seconds: 5));
      }
    }
  }

  void _onBlockHeight(final int height) {
    final heightChanged = _lastBlockHeight != null && height > _lastBlockHeight!;
    _lastBlockHeight = height;
    if (!heightChanged) {
      return;
    }
    final affected = _allAffectedAccounts();
    _txsById.clear();
    onAccountsUpdated?.call(affected);
  }

  void _onMempoolTx(final zkool_mempool.MempoolTx tx) {
    final normalized = ZcashWalletService.normalizeTxId(tx.txid);
    _txsById[normalized] = tx;
    onAccountsUpdated?.call(_affectedAccountsForTx(tx));
  }

  Set<int> _allAffectedAccounts() => _txsById.values.expand(_affectedAccountsForTx).toSet();

  Set<int> _affectedAccountsForTx(final zkool_mempool.MempoolTx tx) => {
    ...tx.notes.map((final n) => n.account),
    ...tx.amounts.map((final a) => a.account),
  };
}
