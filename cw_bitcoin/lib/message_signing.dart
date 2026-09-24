import "package:bitcoin_base/bitcoin_base.dart";
import "package:collection/collection.dart";
import "package:cw_bitcoin/bitcoin_address_record.dart";

BitcoinAddressRecord? resolveMessageSigningAddress({
  required String? address,
  required List<BitcoinAddressRecord> allAddresses,
}) {
  if (address == null) {
    return null;
  }

  final addressRecord = allAddresses.firstWhereOrNull((addr) => addr.address == address);

  if (addressRecord == null) {
    throw UnsupportedError("Cannot sign message with this address");
  }

  if (addressRecord.type == SegwitAddresType.p2tr) {
    throw UnsupportedError("Cannot sign message with Taproot address");
  }

  return addressRecord;
}
