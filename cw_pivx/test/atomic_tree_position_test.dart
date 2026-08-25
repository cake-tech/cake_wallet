import 'package:flutter_test/flutter_test.dart';
import 'package:cw_pivx/src/sapling/utils/atomic_tree_position.dart';

void main() {
  group('AtomicTreePosition', () {
    test('initializes to zero', () {
      final position = AtomicTreePosition();
      expect(position.current, equals(0));
    });

    test('initialize sets position', () {
      final position = AtomicTreePosition();
      position.initialize(1000);
      expect(position.current, equals(1000));
    });

    test('reset returns to zero', () {
      final position = AtomicTreePosition();
      position.initialize(1000);
      position.reset();
      expect(position.current, equals(0));
    });

    test('reservePositions returns start position and increments', () async {
      final position = AtomicTreePosition();

      final start1 = await position.reservePositions(10);
      expect(start1, equals(0));
      expect(position.current, equals(10));

      final start2 = await position.reservePositions(5);
      expect(start2, equals(10));
      expect(position.current, equals(15));
    });

    test('concurrent reservations do not overlap', () async {
      final position = AtomicTreePosition();

      // Reserve positions concurrently
      final futures = List.generate(100, (i) async {
        return await position.reservePositions(10);
      });

      final results = await Future.wait(futures);

      // Verify we got 1000 unique positions
      final allPositions = <int>{};
      for (final start in results) {
        for (int i = 0; i < 10; i++) {
          allPositions.add(start + i);
        }
      }

      // All positions should be unique
      expect(allPositions.length, equals(1000));
      expect(position.current, equals(1000));

      // Positions should be 0-999
      expect(allPositions.toList()..sort(), equals(List.generate(1000, (i) => i)));
    });

    test('high concurrency stress test', () async {
      final position = AtomicTreePosition();

      // Simulate very high concurrency (500 concurrent reservations)
      final futures = List.generate(500, (i) async {
        // Variable sized reservations (1-20)
        final count = (i % 20) + 1;
        return await position.reservePositions(count);
      });

      final results = await Future.wait(futures);

      // Calculate expected total
      final expectedTotal = List.generate(500, (i) => (i % 20) + 1).reduce((a, b) => a + b);
      expect(position.current, equals(expectedTotal));

      // Verify no overlaps by checking all positions are unique
      final allPositions = <int>{};
      for (int i = 0; i < results.length; i++) {
        final start = results[i];
        final count = (i % 20) + 1;
        for (int j = 0; j < count; j++) {
          final pos = start + j;
          expect(allPositions.contains(pos), false,
            reason: 'Position $pos was already assigned! Start: $start, Count: $count');
          allPositions.add(pos);
        }
      }

      expect(allPositions.length, equals(expectedTotal));
    });

    test('sequential reservations maintain order', () async {
      final position = AtomicTreePosition();
      final reserved = <int>[];

      for (int i = 0; i < 50; i++) {
        final start = await position.reservePositions(5);
        reserved.add(start);
      }

      // Verify positions increment by 5 each time
      for (int i = 1; i < reserved.length; i++) {
        expect(reserved[i], equals(reserved[i-1] + 5));
      }
    });

    test('single position reservation', () async {
      final position = AtomicTreePosition();

      final pos1 = await position.reservePositions(1);
      final pos2 = await position.reservePositions(1);
      final pos3 = await position.reservePositions(1);

      expect(pos1, equals(0));
      expect(pos2, equals(1));
      expect(pos3, equals(2));
      expect(position.current, equals(3));
    });

    test('large block reservation', () async {
      final position = AtomicTreePosition();

      // Reserve a large block (simulating a block with many outputs)
      final start = await position.reservePositions(1000);
      expect(start, equals(0));
      expect(position.current, equals(1000));

      // Next reservation should start after
      final start2 = await position.reservePositions(1);
      expect(start2, equals(1000));
    });

    test('interleaved concurrent and sequential operations', () async {
      final position = AtomicTreePosition();

      // Start with sequential
      await position.reservePositions(10);

      // Then concurrent
      final concurrentFutures = List.generate(10, (_) => position.reservePositions(5));
      final concurrentResults = await Future.wait(concurrentFutures);

      // Then sequential again
      final seqResult = await position.reservePositions(10);

      expect(position.current, equals(10 + 50 + 10)); // 70 total
      expect(seqResult, equals(60)); // Should start at 60
    });
  });
}
