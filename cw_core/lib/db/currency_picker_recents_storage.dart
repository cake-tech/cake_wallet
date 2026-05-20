import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/db/sqlite.dart';
import 'package:cw_core/utils/print_verbose.dart';

abstract class CurrencyPickerRecentsStorage {
  static const _table = 'CurrencyPickerRecents';

  static String _keyFor(CryptoCurrency c) => '${c.name}|${c.tag ?? ''}';

  static Future<void> recordRecent({
    required CryptoCurrency currency,
    required String context,
  }) async {
    final database = db;
    if (database == null) return;
    try {
      await database.rawInsert(
        '''
INSERT INTO $_table (currency_key, context, last_used_at)
VALUES (?, ?, ?)
ON CONFLICT(currency_key, context) DO UPDATE SET last_used_at = excluded.last_used_at
''',
        [_keyFor(currency), context, DateTime.now().millisecondsSinceEpoch],
      );
    } catch (e, s) {
      printV('CurrencyPickerRecentsStorage.recordRecent failed: $e\n$s');
    }
  }

  static Future<List<CryptoCurrency>> loadRecents({
    required String context,
    required List<CryptoCurrency> resolveFrom,
    int limit = 6,
  }) async {
    final database = db;
    if (database == null) return const [];
    try {
      final rows = await database.query(
        _table,
        columns: ['currency_key'],
        where: 'context = ?',
        whereArgs: [context],
        orderBy: 'last_used_at DESC',
        limit: limit,
      );
      final byKey = <String, CryptoCurrency>{
        for (final c in resolveFrom) _keyFor(c): c,
      };
      return [
        for (final row in rows)
          if (byKey[row['currency_key'] as String] != null)
            byKey[row['currency_key'] as String]!,
      ];
    } catch (e, s) {
      printV('CurrencyPickerRecentsStorage.loadRecents failed: $e\n$s');
      return const [];
    }
  }
}

class CurrencyPickerContexts {
  static const swapDeposit = 'swap_deposit';
  static const swapReceive = 'swap_receive';
  static const send = 'send';
  static const receive = 'receive';
}
