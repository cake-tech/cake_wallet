import "dart:typed_data";

import "package:cw_bitcoin/electrum_wallet.dart";
import "package:cw_bitcoin/psbt/transaction_builder.dart";

mixin BitcoinHardwareWalletService {
  Future<Uint8List> getMasterFingerprint() async => Uint8List.fromList([0, 0, 0, 0]);
}

mixin LitecoinHardwareWalletService on BitcoinHardwareWalletService {
  Future<String> signLitecoinTransaction({
    required List<PSBTReadyBitcoinOutput> outputs,
    required List<PSBTReadyUtxoWithAddress> inputs,
    required Map<String, PublicKeyWithDerivationPath> publicKeys,
  });
}
