import 'dart:convert';

import 'package:cake_wallet/entities/pending_conversion.dart';
import 'package:cake_wallet/entities/pending_conversion_matcher.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'pending_conversion_store.g.dart';

class PendingConversionStore = PendingConversionStoreBase with _$PendingConversionStore;

/// Backed by [SharedPreferences] (a plain JSON list) rather than a new Hive box/SQLite table -
/// entries here are few, short-lived (removed once the real transaction record shows up, or
/// otherwise harmless if they linger), and this needs no new adapter/typeId registration.
abstract class PendingConversionStoreBase with Store {
  PendingConversionStoreBase(this._sharedPreferences)
      : pending = ObservableList<PendingConversion>() {
    _load();
  }

  static const _prefsKey = "pending_conversions";

  final SharedPreferences _sharedPreferences;

  @observable
  ObservableList<PendingConversion> pending;

  void _load() {
    final raw = _sharedPreferences.getStringList(_prefsKey) ?? const <String>[];
    final loaded = raw
        .map((s) {
          try {
            return PendingConversion.fromJson(jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<PendingConversion>()
        .toList();
    pending = ObservableList.of(loaded);
  }

  Future<void> _persist() =>
      _sharedPreferences.setStringList(_prefsKey, pending.map((p) => jsonEncode(p.toJson())).toList());

  @action
  Future<void> add(PendingConversion conversion) async {
    pending.add(conversion);
    await _persist();
  }

  List<PendingConversion> forWallet(String walletId) =>
      pending.where((p) => p.walletId == walletId).toList();

  /// Removes every pending entry for [walletId] that [transactions] shows has now reached a real,
  /// terminal transaction record (see [PendingConversionMatcher]). Safe to call repeatedly (e.g.
  /// on every `transactions` change) - a no-op once nothing matches.
  @action
  Future<void> reconcile(String walletId, Iterable<TransactionInfo> transactions) async {
    final toRemove = pending
        .where((p) => p.walletId == walletId)
        .where((p) => transactions.any((tx) => PendingConversionMatcher.matches(p, tx)))
        .toList();
    if (toRemove.isEmpty) return;
    pending.removeWhere(toRemove.contains);
    await _persist();
  }
}
