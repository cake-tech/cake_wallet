import 'dart:typed_data';

mixin BitcoinHardwareWalletService {
  Future<Uint8List> getMasterFingerprint();
}
