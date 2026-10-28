/// Thrown when a Monero transaction is constructed with more than one destination
/// while at least one destination is an integrated address carrying a payment ID.
///
/// The native wallet API cannot combine an integrated address with other
/// recipients in a single multi-destination transaction.
class MoneroMultipleDestinationsPaymentIdException implements Exception {
  const MoneroMultipleDestinationsPaymentIdException();

  @override
  String toString() =>
      'Transactions cannot contain more than one destination when paying to a payment ID.';
}
