import "package:cw_core/format_fixed.dart";

class PaymentURI {
  const PaymentURI({required this.scheme, required this.address, required this.amount});

  final String scheme;
  final String address;
  final String amount;

  String toString() {
    final queryParameters = <String, String>{};

    if (amount.isNotEmpty) queryParameters["amount"] = amount.replaceAll(",", ".");

    return Uri(scheme: scheme, path: address, queryParameters: queryParameters).toString();
  }
}

class MoneroURI extends PaymentURI {
  const MoneroURI({required super.address, required super.amount, super.scheme = "monero"});

  @override
  String toString() {
    final queryParameters = <String, String>{};

    if (amount.isNotEmpty) queryParameters["tx_amount"] = amount.replaceAll(",", ".");

    return Uri(scheme: scheme, path: address, queryParameters: queryParameters).toString();
  }
}

class BitcoinURI extends PaymentURI {
  const BitcoinURI({
    required super.address,
    required super.amount,
    this.pjUri = "",
    super.scheme = "bitcoin",
  });

  final String pjUri;

  @override
  String toString() {
    final qp = <String, String>{};

    if (amount.isNotEmpty) qp["amount"] = amount.replaceAll(",", ".");
    if (pjUri.isNotEmpty && !address.startsWith("sp")) {
      qp["pjos"] = "0";
      qp["pj"] = pjUri;
    }

    return Uri(scheme: "bitcoin", path: address, queryParameters: qp).toString();
  }
}

class LightningPaymentRequest extends PaymentURI {
  const LightningPaymentRequest(
      {required super.address,
      required super.amount,
      required this.bolt11Invoice,
      super.scheme = "lightning"});

  final String bolt11Invoice;

  @override
  String toString() => bolt11Invoice;
}

class LitecoinURI extends PaymentURI {
  LitecoinURI({required super.amount, required super.address});

  @override
  String toString() {
    var base = 'litecoin:$address';
    if (amount.isNotEmpty) base += '?amount=${amount.replaceAll(',', '.')}';

    return base;
  }
}

class EthereumURI extends PaymentURI {
  EthereumURI({required super.amount, required super.address});

  @override
  String toString() {
    var base = 'ethereum:$address';
    if (amount.isNotEmpty) base += '?amount=${amount.replaceAll(',', '.')}';

    return base;
  }
}

class BaseURI extends PaymentURI {
  BaseURI({required super.amount, required super.address});

  @override
  String toString() {
    var base = 'base:$address';
    if (amount.isNotEmpty) base += '?amount=${amount.replaceAll(',', '.')}';

    return base;
  }
}

class ArbitrumURI extends PaymentURI {
  ArbitrumURI({required super.amount, required super.address});

  @override
  String toString() {
    var base = 'arbitrum:$address';

    if (amount.isNotEmpty) {
      base += '?amount=${amount.replaceAll(',', '.')}';
    }

    return base;
  }
}

class BitcoinCashURI extends PaymentURI {
  const BitcoinCashURI({required super.address, required super.amount, super.scheme = ""});

  @override
  String toString() {
    var base = address;
    if (amount.isNotEmpty) base += '?amount=${amount.replaceAll(',', '.')}';

    return base;
  }
}

class ERC681URI extends PaymentURI {
  final int chainId;
  final String? contractAddress;

  const ERC681URI({
    required this.chainId,
    required super.address,
    required super.amount,
    required this.contractAddress,
    super.scheme = "ethereum",
  });

  @override
  String toString() {
    var uri = '$scheme:';

    final targetAddress = contractAddress ?? address;
    uri += targetAddress;

    if (chainId != 1) uri += "@$chainId";

    if (contractAddress != null) uri += "/transfer";

    final params = <String, String>{};

    if (contractAddress != null) {
      params["address"] = address;
      if (amount.isNotEmpty) params["uint256"] = _formatAmountForERC20(amount);
    } else {
      if (amount.isNotEmpty) params["value"] = _formatAmountForNative(amount);
    }

    if (params.isNotEmpty) {
      uri += "?${params.entries.map((e) => "${e.key}=${e.value}").join("&")}";
    }

    return uri;
  }

  /// Formats amount for ERC-20 token transfers (in atomic units)
  String _formatAmountForERC20(String amount) {
    try {
      // Convert decimal amount to BigInt (assuming 18 decimals)
      final amountDouble = double.parse(amount.replaceAll(",", "."));
      final amountBigInt = BigInt.from(amountDouble * 1e18);
      return amountBigInt.toString();
    } catch (e) {
      return amount.replaceAll(",", ".");
    }
  }

  /// Formats amount for native ETH payments (in wei using scientific notation)
  String _formatAmountForNative(String amount) {
    try {
      // Convert decimal amount to double for scientific notation
      final amountDouble = double.parse(amount.replaceAll(",", "."));

      // Use scientific notation as recommended by ERC-681
      return "${amountDouble}e18";
    } catch (e) {
      return amount.replaceAll(",", ".");
    }
  }

  factory ERC681URI.fromUri(Uri uri) {
    final (isContract, targetAddress) = _getTargetAddress(uri.path);
    final chainId = _getChainID(uri.path);

    final address = isContract ? uri.queryParameters["address"] ?? "" : targetAddress;
    final amountParam = isContract ? uri.queryParameters["uint256"] : uri.queryParameters["value"];

    var formatedAmount = "";

    if (amountParam != null) {
      final normalized = _normalizeToIntegerWei(amountParam);
      formatedAmount = formatFixed(BigInt.parse(normalized), 18);
    } else {
      formatedAmount = uri.queryParameters["amount"] ?? "";
    }

    return ERC681URI(
      chainId: chainId,
      address: address,
      amount: formatedAmount,
      contractAddress: isContract ? targetAddress : null,
    );
  }

  static int _getChainID(String path) {
    return int.parse(RegExp(r"@\d*").firstMatch(path)?.group(0)?.replaceAll("@", "") ?? "1");
  }

  static (bool, String) _getTargetAddress(String path) {
    final targetAddress =
        RegExp(r"^(0x)?[0-9a-f]{40}", caseSensitive: false).firstMatch(path)!.group(0)!;
    return (path.contains("/"), targetAddress);
  }

  /// Normalize an input amount into an integer wei string.
  ///
  /// Accepts the following forms:
  /// - Integer string: "123000000000000000" → unchanged
  /// - Scientific notation: "0.123e18", "1e6" → expanded to integer
  /// - Decimal ETH: "0.123456" → shifted by 18 decimals
  static String _normalizeToIntegerWei(String input) {
    final raw = input.replaceAll(",", ".").trim();

    // First we check if it's already a plain integer (basically just a number with no dot, no exponent)
    try {
      final isPlainInteger = RegExp(r"^[+-]?\d+$").hasMatch(raw) &&
          !raw.contains(".") &&
          !raw.toLowerCase().contains("e");
      if (isPlainInteger) return raw.replaceFirst(RegExp(r"^\+"), "");

      // Then we check if it's a scientific notation
      final sci = RegExp(r"^[+-]?(\d+\.?\d*|\d*\.?\d+)[eE][+-]?\d+$");
      if (sci.hasMatch(raw)) {
        final mantissaStr = raw.toLowerCase().split("e")[0];
        final exp = int.parse(raw.toLowerCase().split("e")[1]);
        return _expandDecimal(mantissaStr, exp);
      }

      // Lastly, we check if it's a fixed decimal ETH amount, here we shift by 18 to get wei for the amount
      if (raw.contains(".")) {
        return _expandDecimal(raw, 18);
      }
      return raw;
    } catch (e) {
      return raw;
    }
  }

  /// Expands a decimal string by shifting the decimal point `expShift` places
  /// to the right and returns an integer string (digits only, optional leading minus).
  /// Examples:
  ///  _expandDecimal("0.123456", 18) -> "123456000000000000"
  ///  _expandDecimal("1.2", 3) -> "1200"
  static String _expandDecimal(String decimalStr, int expShift) {
    var s = decimalStr.trim();
    var sign = "";
    if (s.startsWith("-") || s.startsWith("+")) {
      sign = s[0] == "-" ? "-" : "";
      s = s.substring(1);
    }

    // First we split the integer and fractional parts
    final parts = s.split(".");
    final intPart = parts[0].isEmpty ? "0" : parts[0];
    final fracPart = parts.length > 1 ? parts[1] : "";
    final digits = (intPart + fracPart).replaceFirst(RegExp(r"^0+"), "");
    final fracLen = fracPart.length;

    // Then we calculate the effective shift = desired shift minus existing fractional digits
    final shift = expShift - fracLen;
    if (shift >= 0) {
      final head = digits.isEmpty ? "0" : digits;
      final zeros = List.filled(shift, "0").join();
      final res = head + zeros;
      return sign + (res.isEmpty ? "0" : res);
    } else {
      // Need to insert a decimal point within digits; return integer by truncating
      final cut = digits.length + shift;
      if (cut <= 0) return "0";

      final res = digits.substring(0, cut);
      return sign + (res.isEmpty ? "0" : res);
    }
  }
}
