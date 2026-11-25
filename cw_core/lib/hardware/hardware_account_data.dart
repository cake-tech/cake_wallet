import "dart:typed_data";

import "package:cw_core/multisig/multisig_config.dart";

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

  MultisigSigner get multisigSigner => throw UnimplementedError();
}
