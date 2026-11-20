import "package:cw_core/multisig/multisig_config.dart";
import "package:cw_core/wallet_info.dart";

class BitcoinMultisigSigner extends MultisigSigner {
  const BitcoinMultisigSigner({
    required this.xPub,
    required this.masterFingerprint,
    required super.derivationPath,
    required super.name,
    required super.hardwareWalletType,
  });

  factory BitcoinMultisigSigner.fromJson(Map<String, dynamic> json) => BitcoinMultisigSigner(
        xPub: json["xPub"] as String,
        masterFingerprint: json["masterFingerprint"] as String,
        derivationPath: json["derivationPath"] as String,
        name: json["name"] as String,
        hardwareWalletType: HardwareWalletType.values.byName(json["hardwareWalletType"] as String),
      );

  final String xPub;
  final String masterFingerprint;

  String get keyOrigin {
    final pathPart = derivationPath.replaceFirst(RegExp(r"^m/"), "");
    return "[$masterFingerprint/$pathPart]$xPub";
  }

  @override
  Map<String, dynamic> toJson() => {
        "xPub": xPub,
        "masterFingerprint": masterFingerprint,
        "derivationPath": derivationPath,
        "name": name,
        "hardwareWalletType": hardwareWalletType.name,
      };
}

class BitcoinMultisigConfig extends MultisigConfig {
  const BitcoinMultisigConfig({required super.threshold, required this.signers})
      : super(signers: signers);

  factory BitcoinMultisigConfig.fromJson(Map<String, dynamic> json) =>
      BitcoinMultisigConfig(
        threshold: json["threshold"] as int,
        signers: (json["signers"] as List).map((e) =>
            BitcoinMultisigSigner.fromJson(e as Map<String, dynamic>)).toList(),
      );

  @override
  final List<BitcoinMultisigSigner> signers;

  String toPolicy() {
    final keys = List.generate(signers.length, (i) => i).map((c) => "@$c/**").join(",");
    return "wsh(sortedmulti($threshold,$keys))";
  }

  /// Combined-path output descriptor with checksum, e.g.
  /// `wsh(sortedmulti(2,[fp/48'/0'/0'/2']xpub.../<0;1>/*,...))#checksum`.
  String toDescriptor() {
    final keys = signers.map((c) => "${c.keyOrigin}/<0;1>/*").join(",");
    final body = "wsh(sortedmulti($threshold,$keys))";
    return "$body#${_DescriptorChecksum.compute(body)}";
  }

  @override
  Map<String, dynamic> toJson() => {
        "threshold": threshold,
        "descriptor": toDescriptor(),
        "signers": signers.map((e) => e.toJson()).toList(),
      };
}

/// BIP-380 output descriptor checksum.
class _DescriptorChecksum {
  static const String _inputCharset =
      "0123456789()[],'/*abcdefgh@:\$%{}IJKLMNOPQRSTUVWXYZ&+-.;<=>?!^_|~ijklmnopqrstuvwxyzABCDEFGH`#\"\\ ";
  static const String _checksumCharset = "qpzry9x8gf2tvdw0s3jn54khce6mua7l";

  static int _polymod(int c, int val) {
    final c0 = c >> 35;
    c = ((c & 0x7ffffffff) << 5) ^ val;
    if (c0 & 1 != 0) {
      c ^= 0xf5dee51989;
    }
    if (c0 & 2 != 0) {
      c ^= 0xa9fdca3312;
    }
    if (c0 & 4 != 0) {
      c ^= 0x1bab10e32d;
    }
    if (c0 & 8 != 0) {
      c ^= 0x3706b1677a;
    }
    if (c0 & 16 != 0) {
      c ^= 0x644d626ffd;
    }
    return c;
  }

  static String compute(String descriptor) {
    var c = 1;
    var cls = 0;
    var clsCount = 0;
    for (final ch in descriptor.split("")) {
      final pos = _inputCharset.indexOf(ch);
      if (pos == -1) {
        throw FormatException("Invalid descriptor character: $ch");
      }
      c = _polymod(c, pos & 31);
      cls = cls * 3 + (pos >> 5);
      if (++clsCount == 3) {
        c = _polymod(c, cls);
        cls = 0;
        clsCount = 0;
      }
    }
    if (clsCount > 0) {
      c = _polymod(c, cls);
    }
    for (var i = 0; i < 8; i++) {
      c = _polymod(c, 0);
    }
    c ^= 1;

    final result = StringBuffer();
    for (var i = 0; i < 8; i++) {
      result.write(_checksumCharset[(c >> (5 * (7 - i))) & 31]);
    }
    return result.toString();
  }
}
