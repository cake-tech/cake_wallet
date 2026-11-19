abstract class MultisigSigner {
  const MultisigSigner({
    required this.derivationPath,
    required this.name,
  });

  final String derivationPath;
  final String name;

  Map<String, String> toJson() => {
    "derivationPath": derivationPath,
    "name": name,
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
