import 'dart:typed_data';

final zecBase = Uint8List(32);

/// Whether NU6.3 (Ironwood) is active at the chain tip. Updated on balance refresh.
bool ironwoodActive = false;

/// Pool bitmask for Ironwood (pool index 3). Orchard and Ironwood share the same address.
const ironwoodPoolMask = 8;

int? get shieldedRecipientPools => ironwoodActive ? ironwoodPoolMask : null;
