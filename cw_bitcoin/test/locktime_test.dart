import 'package:cw_bitcoin/locktime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('antiFeeSnipingLocktime', () {
    test('returns 0 when not synced', () {
      expect(antiFeeSnipingLocktime(chainTip: 800000, synced: false), 0);
    });

    test('returns 0 when chainTip <= 0', () {
      expect(antiFeeSnipingLocktime(chainTip: 0, synced: true), 0);
    });

    test('returns the current tip when synced', () {
      expect(antiFeeSnipingLocktime(chainTip: 800000, synced: true), 800000);
    });
  });

  group('locktimeToBytes', () {
    test('encodes 0 as four zero bytes', () {
      expect(locktimeToBytes(0), [0, 0, 0, 0]);
    });

    test('encodes a block height little-endian', () {
      expect(locktimeToBytes(800000), [0x00, 0x35, 0x0C, 0x00]);
    });

    test('encodes max 32-bit value', () {
      expect(locktimeToBytes(0xFFFFFFFF), [0xFF, 0xFF, 0xFF, 0xFF]);
    });
  });
}
