import 'dart:math';

import 'package:bitcoin_base/bitcoin_base.dart';

/// Applies [ordering] to a transaction's [outputs] before building.
///
/// Returns a new list; the input is never mutated. Only [BitcoinOrdering.shuffle]
/// reorders (using a secure RNG by default) so the change output is no longer
/// placed deterministically last. Any other value preserves the given order,
/// matching the pre-existing hardware-wallet behavior.
List<T> orderOutputs<T>(
  List<T> outputs,
  BitcoinOrdering ordering, {
  Random? rng,
}) {
  final result = List<T>.of(outputs);
  if (ordering == BitcoinOrdering.shuffle) {
    result.shuffle(rng ?? Random.secure());
  }
  return result;
}
