import 'dart:typed_data';

class HardwareAccountData {
  HardwareAccountData({
    required this.address,
    required this.accountIndex,
    this.xpub,
    this.masterFingerprint,
  });

  final String address;
  final int accountIndex;

  // Bitcoin Specific
  final Uint8List? masterFingerprint;
  final String? xpub;
}
