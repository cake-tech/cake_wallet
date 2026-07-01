import 'dart:typed_data';

class HardwareAccountData {
  HardwareAccountData({
    required this.address,
    required this.accountIndex,
    required this.derivationPath,
    this.xpub,
    this.masterFingerprint,
  });

  final String address;
  final int accountIndex;
  final String derivationPath;

  // Bitcoin Specific
  final Uint8List? masterFingerprint;
  final String? xpub;
}
