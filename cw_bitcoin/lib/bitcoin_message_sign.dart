/// A blank address uses the wallet's main key. Any other address has to be
/// one this wallet can derive. Silent payment addresses are not in that set,
/// and signing them with the main key would look like proof for the wrong key.
void assertCanSignBitcoinMessage({
  required String? address,
  required bool heldByWallet,
  required bool isTaproot,
}) {
  final requested = address != null && address.trim().isNotEmpty;
  if (!requested) {
    return;
  }
  if (!heldByWallet) {
    throw UnsupportedError('Cannot sign a message for an address this wallet does not hold');
  }
  if (isTaproot) {
    throw UnsupportedError('Cannot sign message with Taproot address');
  }
}
