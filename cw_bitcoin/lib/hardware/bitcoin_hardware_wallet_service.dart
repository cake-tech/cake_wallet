import "dart:typed_data";

import "package:cw_bitcoin/electrum_wallet.dart";
import "package:cw_bitcoin/multisig/multisig_config.dart";
import "package:cw_bitcoin/psbt/transaction_builder.dart";
import "package:cw_core/hardware/hardware_account_data.dart";
import "package:cw_core/wallet_info.dart";
import "package:ledger_flutter_plus/ledger_flutter_plus_dart.dart";

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

class BitcoinHardwareAccountData extends HardwareAccountData {
  BitcoinHardwareAccountData({
    required super.address,
    required super.accountIndex,
    required super.derivationPath,
    required Uint8List masterFingerprint,
    required String xpub,
    required this.hardwareWalletType,
  }) : super(masterFingerprint: masterFingerprint, xpub: xpub);

  final HardwareWalletType hardwareWalletType;

  @override
  BitcoinMultisigSigner get multisigSigner => BitcoinMultisigSigner(
        xPub: xpub!,
        masterFingerprint: hex.encode(masterFingerprint!),
        derivationPath: derivationPath,
        name: address,
        hardwareWalletType: hardwareWalletType,
      );
}
