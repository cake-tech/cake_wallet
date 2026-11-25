import "dart:convert";

import "package:cw_bitcoin/multisig/multisig_config.dart";
import "package:cw_core/wallet_info.dart";
import "package:flutter_test/flutter_test.dart";

const _xpub1 =
    "xpub661MyMwAqRbcFtXgS5sYJABqqG9YLmC4Q1Rdap9gSE8NqtwybGhePY2gZ29ESFjqJoCu1Rupje8YtGqsefD265TMg7usUDFdp6W1EGMcet8";
const _xpub2 =
    "xpub661MyMwAqRbcFW31YEwpkMuc5THy2PSt5bDMsktWQcFF8syAmRUapSCGu8ED9W6oDMSgv6Zz8idoc4a6mr8BDzTJY47LJhkJ8UB7WEGuduB";

const _expectedDescriptor = "wsh(sortedmulti(2,"
    "[d34db33f/48'/0'/0'/2']$_xpub1/<0;1>/*,"
    "[deadbeef/48'/0'/0'/2']$_xpub2/<0;1>/*))#k8fwpwdm";

BitcoinMultisigSigner _signer(
  String xPub,
  String fingerprint,
  String name, [
  HardwareWalletType hardwareWalletType = HardwareWalletType.ledger,
]) =>
    BitcoinMultisigSigner(
      xPub: xPub,
      masterFingerprint: fingerprint,
      derivationPath: "m/48'/0'/0'/2'",
      name: name,
      hardwareWalletType: hardwareWalletType,
    );

final _config = BitcoinMultisigConfig(
  threshold: 2,
  signers: [
    _signer(_xpub1, "d34db33f", "Ledger"),
    _signer(_xpub2, "deadbeef", "Bitbox", HardwareWalletType.bitbox),
  ],
);

void main() {
  group("BitcoinMultisigSigner", () {
    test("keyOrigin strips the m/ prefix", () {
      expect(
        _signer(_xpub1, "d34db33f", "Ledger").keyOrigin,
        "[d34db33f/48'/0'/0'/2']$_xpub1",
      );
    });

    test("keyOrigin keeps a path without the m/ prefix", () {
      const signer = BitcoinMultisigSigner(
        xPub: _xpub1,
        masterFingerprint: "d34db33f",
        derivationPath: "48'/0'/0'/2'",
        name: "Ledger",
        hardwareWalletType: HardwareWalletType.ledger,
      );
      expect(signer.keyOrigin, "[d34db33f/48'/0'/0'/2']$_xpub1");
    });

    test("round-trips through json", () {
      final signer = _signer(_xpub1, "d34db33f", "Bitbox", HardwareWalletType.bitbox);
      final decoded = BitcoinMultisigSigner.fromJson(
        jsonDecode(jsonEncode(signer.toJson())) as Map<String, dynamic>,
      );

      expect(decoded.xPub, signer.xPub);
      expect(decoded.masterFingerprint, signer.masterFingerprint);
      expect(decoded.derivationPath, signer.derivationPath);
      expect(decoded.name, signer.name);
      expect(decoded.hardwareWalletType, HardwareWalletType.bitbox);
    });

    test("stores the hardware wallet type by name", () {
      final signer = _signer(_xpub1, "d34db33f", "Bitbox", HardwareWalletType.bitbox);
      expect(signer.toJson()["hardwareWalletType"], "bitbox");
    });
  });

  group("BitcoinMultisigConfig", () {
    test("toPolicy uses one placeholder per signer", () {
      expect(_config.toPolicy(), "wsh(sortedmulti(2,@0/**,@1/**))");
    });

    test("toDescriptor matches the BIP-380 reference checksum", () {
      expect(_config.toDescriptor(), _expectedDescriptor);
    });

    test("toDescriptor checksums a single-signer descriptor", () {
      final config = BitcoinMultisigConfig(
        threshold: 1,
        signers: [_signer(_xpub1, "d34db33f", "Ledger")],
      );
      expect(
        config.toDescriptor(),
        "wsh(sortedmulti(1,[d34db33f/48'/0'/0'/2']$_xpub1/<0;1>/*))#v4jzzhlr",
      );
    });

    test("toDescriptor rejects characters outside the descriptor charset", () {
      final config = BitcoinMultisigConfig(
        threshold: 1,
        signers: [_signer("xpubé", "d34db33f", "Ledger")],
      );
      expect(config.toDescriptor, throwsFormatException);
    });

    test("toJson includes the descriptor", () {
      final json = _config.toJson();
      expect(json["threshold"], 2);
      expect(json["descriptor"], _expectedDescriptor);
      expect(json["signers"], hasLength(2));
    });

    test("round-trips through json", () {
      final decoded = BitcoinMultisigConfig.fromJson(
        jsonDecode(jsonEncode(_config.toJson())) as Map<String, dynamic>,
      );

      expect(decoded.threshold, _config.threshold);
      expect(decoded.signers.map((s) => s.name), ["Ledger", "Bitbox"]);
      expect(
        decoded.signers.map((s) => s.hardwareWalletType),
        [HardwareWalletType.ledger, HardwareWalletType.bitbox],
      );
      expect(decoded.toDescriptor(), _expectedDescriptor);
    });
  });
}
