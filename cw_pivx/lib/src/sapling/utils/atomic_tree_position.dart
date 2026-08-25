import 'package:synchronized/synchronized.dart';

/// Thread-safe, globally sequential position tracker for the Sapling commitment
/// tree. Positions must be gap-free and unique for Merkle-tree correctness, even
/// when sync batches run in parallel.
class AtomicTreePosition {
  int _position = 0;
  final Lock _lock = Lock();

  /// Atomically reserve [count] consecutive positions; returns the start of the
  /// reserved block. Concurrent calls never receive overlapping ranges.
  Future<int> reservePositions(int count) async {
    return await _lock.synchronized(() {
      final start = _position;
      _position += count;
      return start;
    });
  }

  /// Move the next position forward without allowing it to go backwards.
  Future<void> setAtLeast(int position) async {
    await _lock.synchronized(() {
      if (position > _position) {
        _position = position;
      }
    });
  }

  /// The NEXT position to be assigned; the last assigned is `current - 1`.
  int get current => _position;

  /// Restore the counter from persistent storage at wallet init only; do not
  /// call during sync.
  void initialize(int position) {
    _position = position;
  }

  /// Reset to 0 (tests or full wallet resets only).
  void reset() {
    _position = 0;
  }
}
