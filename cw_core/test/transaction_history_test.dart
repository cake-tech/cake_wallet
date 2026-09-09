import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:flutter_test/flutter_test.dart';

class _Tx extends TransactionInfo {
  _Tx(String id, {DateTime? at})
      : super(
          id: id,
          amount: Money.fromInt(1, CryptoCurrency.btc),
          direction: TransactionDirection.incoming,
          date: at ?? DateTime(2026, 1, 1),
        ) {
    isPending = false;
  }
}

class _History extends TransactionHistory<_Tx> {}


/// Collects everything the history announces, the way a consumer would after
/// buffering a burst.
Future<List<HistoryChange>> drain(_History history, void Function() body) async {
  final collected = <HistoryChange>[];
  final subscription = history.changes.listen(collected.add);
  body();
  // Let the broadcast controller deliver.
  await Future<void>.delayed(Duration.zero);
  await subscription.cancel();
  return collected;
}

void main() {
  group('history keys', () {
    // Zcash used to key its map 'tx_<hash>' while the item's own id was the
    // bare hash. The change journal carries the stored key, and the UI matches
    // rows by item id, so every update announced a key no row could be found
    // under and appended another copy instead of replacing it.
    test('a stale map key cannot become the stored key', () async {
      final history = _History();
      final changes = await drain(
        history,
        () => history.addMany({'tx_a': _Tx('a'), 'tx_b': _Tx('b')}),
      );

      expect(history.transactions.keys, ['a', 'b']);
      expect(changes.map((change) => (change as ItemAdded).id), ['a', 'b']);
    });

    test('re-adding the same transaction replaces it and reports an update',
        () async {
      final history = _History()..addOne(_Tx('a'));
      final changes = await drain(history, () => history.addOne(_Tx('a')));

      expect(history.transactions, hasLength(1));
      expect(changes.single, isA<ItemUpdated>());
    });
  });

  group('TransactionHistoryBase', () {
    test('exposes a read-only map', () {
      final history = _History()..addOne(_Tx('a'));

      expect(history.transactions.length, 1);
      expect(() => history.transactions.remove('a'), throwsUnsupportedError);
      expect(() => history.transactions['b'] = _Tx('b'), throwsUnsupportedError);
    });

    test('distinguishes a first insert from a replacement', () async {
      final history = _History();

      expect(await drain(history, () => history.addOne(_Tx('a'))), [isA<ItemAdded>()]);
      expect(await drain(history, () => history.addOne(_Tx('a'))), [isA<ItemUpdated>()]);
    });

    test('announces removals, and stays quiet for absent ids', () async {
      final history = _History()..addOne(_Tx('a'));

      expect(await drain(history, () => history.remove('a')), [isA<ItemRemoved>()]);
      expect(await drain(history, () => history.remove('a')), isEmpty);
    });

    test('emits one event for clear() rather than one per entry', () async {
      final history = _History()..addMany({for (var i = 0; i < 500; i++) '$i': _Tx('$i')});

      final changes = await drain(history, history.clear);

      expect(changes, [isA<HistoryCleared>()]);
      expect(history.transactions, isEmpty);
    });

    test('clear() on an empty history says nothing', () async {
      expect(await drain(_History(), () {}), isEmpty);
      expect(await drain(_History(), _History().clear), isEmpty);
    });

    test('markUpdated announces in-place mutation, which is otherwise invisible', () async {
      final tx = _Tx('a');
      final history = _History()..addOne(tx);

      final changes = await drain(history, () {
        tx.confirmations = 3;
        history.markUpdated(['a']);
      });

      expect(changes, [isA<ItemUpdated>()]);
      expect((changes.single as ItemUpdated).id, 'a');
    });

    test('markUpdated ignores ids it does not hold', () async {
      final history = _History();
      expect(await drain(history, () => history.markUpdated(['nope'])), isEmpty);
    });

    test('markLoaded fires once and flips hasLoaded', () async {
      final history = _History();
      expect(history.hasLoaded, isFalse);

      expect(await drain(history, history.markLoaded), [isA<HistoryLoaded>()]);
      expect(history.hasLoaded, isTrue);
      expect(await drain(history, history.markLoaded), isEmpty);
    });

    test('an empty load still reports as loaded', () async {
      // The case that makes HistoryLoaded necessary: a wallet with no
      // transactions produces no item events at all.
      final history = _History();
      final changes = await drain(history, history.markLoaded);

      expect(changes, [isA<HistoryLoaded>()]);
      expect(history.transactions, isEmpty);
    });

    test('removeWhere announces each removal and leaves the rest', () async {
      final history = _History()
        ..addMany({'a': _Tx('a'), 'b': _Tx('b'), 'c': _Tx('c')});

      final changes = await drain(
        history,
        () => history.removeWhere((id, _) => id != 'b'),
      );

      expect(changes, everyElement(isA<ItemRemoved>()));
      expect(changes.length, 2);
      expect(history.transactions.keys, ['b']);
    });

    test('the journal is ordered and not deduplicated', () async {
      final history = _History();

      final changes = await drain(history, () {
        history.addOne(_Tx('a'));
        history.addOne(_Tx('a'));
        history.remove('a');
      });

      expect(changes, [isA<ItemAdded>(), isA<ItemUpdated>(), isA<ItemRemoved>()]);
    });

    test('nothing is emitted after dispose', () async {
      final history = _History();
      await history.dispose();

      // Must not throw on a closed controller.
      expect(() => history.addOne(_Tx('a')), returnsNormally);
      expect(history.transactions.length, 1);
    });
  });
}
