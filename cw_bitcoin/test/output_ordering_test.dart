import 'dart:math';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cw_bitcoin/output_ordering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('orderOutputs', () {
    test('none preserves the given order', () {
      final outputs = [0, 1, 2, 3, 4];
      expect(orderOutputs(outputs, BitcoinOrdering.none), outputs);
    });

    test('does not mutate the input list', () {
      final outputs = [0, 1, 2, 3, 4];
      orderOutputs(outputs, BitcoinOrdering.shuffle, rng: Random(1));
      expect(outputs, [0, 1, 2, 3, 4]);
    });

    test('returns a new list instance', () {
      final outputs = [0, 1, 2];
      expect(identical(orderOutputs(outputs, BitcoinOrdering.none), outputs), isFalse);
    });

    test('shuffle preserves the multiset of outputs', () {
      final outputs = [0, 1, 2, 3, 4, 5, 6, 7];
      final shuffled = orderOutputs(outputs, BitcoinOrdering.shuffle, rng: Random(7));
      expect(shuffled.length, outputs.length);
      expect(shuffled.toSet(), outputs.toSet());
    });

    test('shuffle is deterministic for a given seed', () {
      final outputs = [0, 1, 2, 3, 4, 5];
      final a = orderOutputs(outputs, BitcoinOrdering.shuffle, rng: Random(42));
      final b = orderOutputs(outputs, BitcoinOrdering.shuffle, rng: Random(42));
      expect(a, b);
    });

    test('shuffle does not keep the change output deterministically last', () {
      // Last element (99) models the change output, appended last today.
      final outputs = [0, 1, 2, 3, 99];
      final changePositions = <int>{};
      for (var seed = 0; seed < 50; seed++) {
        final shuffled = orderOutputs(outputs, BitcoinOrdering.shuffle, rng: Random(seed));
        changePositions.add(shuffled.indexOf(99));
      }
      // Across seeds the change lands in more than one position, and not always last.
      expect(changePositions.length, greaterThan(1));
      expect(changePositions, isNot(equals({outputs.length - 1})));
    });
  });
}
