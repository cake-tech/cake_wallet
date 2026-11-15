import "package:bitcoin_base/bitcoin_base.dart" show SegwitAddresType;
import "package:cw_bitcoin/bitcoin_address_record.dart";

/// A blank address uses the wallet's main key. Any other address has to be
/// one this wallet can derive a key for. Silent payment and MWEB addresses
/// have no such key, and signing them with another key would look like proof
/// for the wrong key.
BitcoinAddressRecord? getSigningAddressRecord({
  required String? address,
  required Iterable<BitcoinAddressRecord> walletAddresses,
}) {
  final requested = address?.trim() ?? "";
  if (requested.isEmpty) {
    return null;
  }

  final record = walletAddresses.where((candidate) => candidate.address == requested).firstOrNull;
  if (record == null) {
    throw UnsupportedError("Cannot sign a message for an address this wallet does not hold");
  }
  if (record.type == SegwitAddresType.p2tr) {
    throw UnsupportedError("Cannot sign message with Taproot address");
  }
  if (record.type == SegwitAddresType.mweb) {
    throw UnsupportedError("Cannot sign message with an MWEB address");
  }

  return record;
}
