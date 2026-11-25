import "package:cw_core/wallet_info.dart";

abstract class MultisigSigner {
  const MultisigSigner({
    required this.derivationPath,
    required this.name,
    required this.hardwareWalletType,
  });

  final String derivationPath;
  final String name;
  final HardwareWalletType hardwareWalletType;

  Map<String, dynamic> toJson() => {
    "derivationPath": derivationPath,
    "name": name,
    "hardwareWalletType": hardwareWalletType.name,
  };
}

class MultisigConfig {
  const MultisigConfig({required this.threshold, required this.signers});

  final int threshold;
  final List<MultisigSigner> signers;

  Map<String, dynamic> toJson() => {
    "threshold": threshold,
    "signers": signers.map((s) => s.toJson()).toList(),
  };
}
