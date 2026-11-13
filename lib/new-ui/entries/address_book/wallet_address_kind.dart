import "package:cake_wallet/generated/i18n.dart";
import "package:cw_core/wallet_type.dart";

enum WalletAddressKind {
  standard,
  segwit,
  segwitCompatible,
  taproot,
  legacy,
  silentPayments,
  lightning,
  mweb;

  static const _activePrefix = "Active - ";

  bool get isLightning => this == WalletAddressKind.lightning;


  static WalletAddressKind? fromLabelCode(String label, {required WalletType type}) {
    final isBitcoin = type == WalletType.bitcoin;
    final isLitecoin = type == WalletType.litecoin;
    if (!isBitcoin && !isLitecoin) return null;

    final code =
        label.startsWith(_activePrefix) ? label.substring(_activePrefix.length) : label;

    if (code == "P2WPKH") return WalletAddressKind.standard;
    if (isLitecoin) return code == "MWEB" ? WalletAddressKind.mweb : null;

    switch (code) {
      case "P2TR":
        return WalletAddressKind.taproot;
      case "P2WSH":
        return WalletAddressKind.segwit;
      case "P2SH":
        return WalletAddressKind.segwitCompatible;
      case "P2PKH":
        return WalletAddressKind.legacy;
      case "LN":
        return WalletAddressKind.lightning;
    }
    if (code.startsWith("Silent Payments")) return WalletAddressKind.silentPayments;
    return null;
  }

  static final _base58 = RegExp(r"^[1-9A-HJ-NP-Za-km-z]{25,34}$");


  static WalletAddressKind? fromAddressFormat(String address) {
    final raw = address.trim();
    if (raw.isEmpty) return null;
    if (raw.contains("@")) return WalletAddressKind.lightning;

    final lower = raw.toLowerCase();
    if (lower.startsWith("sp1") || lower.startsWith("tsp1")) {
      return WalletAddressKind.silentPayments;
    }
    if (lower.startsWith("ltcmweb1")) return WalletAddressKind.mweb;

    for (final hrp in const ["bcrt1", "bc1", "tb1", "ltc1"]) {
      if (!lower.startsWith(hrp)) continue;
      // Witness version char + program: 39 = v0 20-byte, 59 = 32-byte program.
      final data = lower.substring(hrp.length);
      if (data.startsWith("q")) {
        if (data.length == 39) return WalletAddressKind.standard;
        if (data.length == 59 && hrp != "ltc1") return WalletAddressKind.segwit;
        return null;
      }
      if (data.startsWith("p") && data.length == 59 && hrp != "ltc1") {
        return WalletAddressKind.taproot;
      }
      return null;
    }

    if (_base58.hasMatch(raw)) {
      final first = raw[0];
      if (first == "3" || first == "2") return WalletAddressKind.segwitCompatible;
      if (first == "1" || first == "m" || first == "n") return WalletAddressKind.legacy;
    }
    return null;
  }

  String displayName() {
    switch (this) {
      case WalletAddressKind.standard:
        return S.current.standard;
      case WalletAddressKind.segwit:
        return "Segwit";
      case WalletAddressKind.segwitCompatible:
        return "Segwit-Compatible";
      case WalletAddressKind.taproot:
        return "Taproot";
      case WalletAddressKind.legacy:
        return S.current.legacy;
      case WalletAddressKind.silentPayments:
        return S.current.silent_payments;
      case WalletAddressKind.lightning:
        return "Lightning";
      case WalletAddressKind.mweb:
        return "Private";
    }
  }
}

