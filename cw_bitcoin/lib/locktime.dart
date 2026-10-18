import "dart:typed_data";

/// Anti-fee-sniping locktime, set to the current chain tip (exact-tip).
///
/// Matches the exact-tip cluster (payjoin-cli, ldk-node, Bull Bitcoin) and Core's
/// default for externally-constructed transactions, and takes Cake off its unique
/// `nLockTime = 0` fingerprint. It intentionally skips the ~10% backdate
/// Core/Electrum apply for delayed-broadcast privacy, which does not apply here.
/// Returns 0 when not synced or the tip is unknown, to avoid emitting a stale
/// height.
int antiFeeSnipingLocktime({
  required int chainTip,
  required bool synced,
}) {
  if (!synced || chainTip <= 0) return 0;
  return chainTip;
}

/// Little-endian 4-byte encoding for `BtcTransaction.locktime`.
List<int> locktimeToBytes(int locktime) => (ByteData(4)..setUint32(0, locktime, Endian.little)).buffer.asUint8List();
