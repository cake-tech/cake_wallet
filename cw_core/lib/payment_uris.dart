import "package:cw_core/format_fixed.dart";

abstract class PaymentURI {
  PaymentURI({required this.amount, required this.address});

  final String amount;
  final String address;
}

class ExternalAddressURI extends PaymentURI {
  ExternalAddressURI({required super.amount, required super.address});

  @override
  String toString() => address;
}

class MoneroURI extends PaymentURI {
  MoneroURI({required super.amount, required super.address});

  @override
  String toString() {
    var base = "monero:$address";

    if (amount.isNotEmpty) {
      base += '?tx_amount=${amount.replaceAll(',', '.')}';
    }

    return base;
  }
}

class HavenURI extends PaymentURI {
  HavenURI({required super.amount, required super.address});

  @override
  String toString() {
    var base = "haven:$address";

    if (amount.isNotEmpty) {
      base += '?tx_amount=${amount.replaceAll(',', '.')}';
    }

    return base;
  }
}

class BitcoinURI extends PaymentURI {
  BitcoinURI({required super.amount, required super.address, this.pjUri = ""});

  final String pjUri;

  @override
  String toString() {
    final qp = <String, String>{};

    if (amount.isNotEmpty) {
      qp["amount"] = amount.replaceAll(",", ".");
    }

    if (pjUri.isNotEmpty && !address.startsWith("sp")) {
      qp["pjos"] = "0";
      qp["pj"] = pjUri;
    }

    return Uri(scheme: "bitcoin", path: address, queryParameters: qp).toString();
  }
}

class LitecoinURI extends PaymentURI {
  LitecoinURI({required super.amount, required super.address});

  @override
  String toString() {
    var base = "litecoin:$address";

    if (amount.isNotEmpty) {
      base += '?amount=${amount.replaceAll(',', '.')}';
    }

    return base;
  }
}

class EthereumURI extends PaymentURI {
  EthereumURI({required super.amount, required super.address});

  @override
  String toString() {
    var base = "ethereum:$address";

    if (amount.isNotEmpty) {
      base += '?amount=${amount.replaceAll(',', '.')}';
    }

    return base;
  }
}

class BitcoinCashURI extends PaymentURI {
  BitcoinCashURI({required super.amount, required super.address});

  @override
  String toString() {
    var base = address;

    if (amount.isNotEmpty) {
      base += '?amount=${amount.replaceAll(',', '.')}';
    }

    return base;
  }
}

class NanoURI extends PaymentURI {
  NanoURI({required super.amount, required super.address});

  @override
  String toString() {
    var base = "nano:$address";
    if (amount.isNotEmpty) {
      base += '?amount=${amount.replaceAll(',', '.')}';
    }

    return base;
  }
}

class SolanaURI extends PaymentURI {
  SolanaURI({required super.amount, required super.address, this.contractAddress});

  final String? contractAddress;

  @override
  String toString() {
    var base = "solana:$address";
    final params = <String>[];

    if (amount.isNotEmpty) {
      params.add('amount=${amount.replaceAll(',', '.')}');
    }
    if (contractAddress != null && contractAddress!.isNotEmpty) {
      params.add("spl-token=$contractAddress");
    }
    if (params.isNotEmpty) {
      base += '?${params.join('&')}';
    }

    return base;
  }
}

class TronURI extends PaymentURI {
  TronURI({required super.amount, required super.address, this.contractAddress});

  final String? contractAddress;

  @override
  String toString() {
    var base = "tron:$address";
    final params = <String>[];

    if (amount.isNotEmpty) {
      params.add('amount=${amount.replaceAll(',', '.')}');
    }
    if (contractAddress != null && contractAddress!.isNotEmpty) {
      params.add("token=$contractAddress");
    }
    if (params.isNotEmpty) {
      base += '?${params.join('&')}';
    }

    return base;
  }
}

class WowneroURI extends PaymentURI {
  WowneroURI({required super.amount, required super.address});

  @override
  String toString() {
    var base = "wownero:$address";

    if (amount.isNotEmpty) {
      base += '?tx_amount=${amount.replaceAll(',', '.')}';
    }

    return base;
  }
}

class ZanoURI extends PaymentURI {
  ZanoURI({required super.amount, required super.address});

  @override
  String toString() {
    var base = "zano:$address";

    if (amount.isNotEmpty) {
      base += '?amount=${amount.replaceAll(',', '.')}';
    }

    return base;
  }
}

class DecredURI extends PaymentURI {
  DecredURI({required super.amount, required super.address});

  @override
  String toString() {
    var base = "decred:$address";

    if (amount.isNotEmpty) {
      base += '?amount=${amount.replaceAll(',', '.')}';
    }

    return base;
  }
}

class DogeURI extends PaymentURI {
  DogeURI({required super.amount, required super.address});

  @override
  String toString() {
    var base = "doge:$address";

    if (amount.isNotEmpty) {
      base += '?amount=${amount.replaceAll(',', '.')}';
    }

    return base;
  }
}

class ZcashURI extends PaymentURI {
  ZcashURI({required super.amount, required super.address});

  @override
  String toString() {
    var base = "zcash:$address";

    if (amount.isNotEmpty) {
      base += '?amount=${amount.replaceAll(',', '.')}';
    }

    return base;
  }
}

class ERC681URI extends PaymentURI {
  ERC681URI({
    required this.chainId,
    required super.address,
    required super.amount,
    required this.contractAddress,
    this.tokenDecimals = 18,
    this.rawTokenAmount,
  });

  factory ERC681URI.fromUri(Uri uri) {
    final (isContract, targetAddress) = _getTargetAddress(uri.path);
    final chainId = _getChainID(uri.path);

    final address = isContract ? uri.queryParameters["address"] ?? "" : targetAddress;

    var formatedAmount = "";
    String? rawTokenAmount;

    if (isContract) {
      formatedAmount = uri.queryParameters["amount"] ?? "";
      final uint256Param = uri.queryParameters["uint256"];
      if (uint256Param != null) {
        final raw = uint256Param.replaceAll(",", ".").trim();
        if (!_scientificPattern.hasMatch(raw) && raw.contains(".")) {
          if (formatedAmount.isEmpty) {
            formatedAmount = raw;
          }
        } else {
          rawTokenAmount = _normalizeToIntegerWei(raw);
        }
      }
    } else {
      final valueParam = uri.queryParameters["value"];
      if (valueParam != null) {
        final normalized = BigInt.tryParse(_normalizeToIntegerWei(valueParam));
        formatedAmount = normalized != null ? formatFixed(normalized, 18) : "";
      } else {
        formatedAmount = uri.queryParameters["amount"] ?? "";
      }
    }

    return ERC681URI(
      chainId: chainId,
      address: address,
      amount: formatedAmount,
      contractAddress: isContract ? targetAddress : null,
      rawTokenAmount: rawTokenAmount,
    );
  }

  final int chainId;
  final String? contractAddress;
  final int tokenDecimals;
  final String? rawTokenAmount;

  static final RegExp _scientificPattern = RegExp(r"^[+-]?(\d+\.?\d*|\d*\.?\d+)[eE][+-]?\d+$");

  @override
  String toString() {
    var uri = "ethereum:";

    final targetAddress = contractAddress ?? address;
    uri += targetAddress;

    uri += "@$chainId";

    if (contractAddress != null) {
      uri += "/transfer";
    }

    final params = <String, String>{};

    if (contractAddress != null) {
      params["address"] = address;
      // only emit an atomic uint256 when it is unambiguous, either stored raw or 18 decimals,
      // old app versions divide any uint256 by 1e18 so other tokens rely on the amount param
      final uint256 = rawTokenAmount ??
          (tokenDecimals == 18 && amount.isNotEmpty
              ? _expandDecimal(amount.replaceAll(",", "."), 18)
              : null);
      if (uint256 != null && uint256.isNotEmpty) {
        params["uint256"] = uint256;
      }
      if (amount.isNotEmpty) {
        params["amount"] = amount.replaceAll(",", ".");
      }
    } else {
      if (amount.isNotEmpty) {
        params["value"] = _formatAmountForNative(amount);
      }
    }

    if (params.isNotEmpty) {
      uri += "?${params.entries.map((e) => "${e.key}=${e.value}").join("&")}";
    }

    return uri;
  }

  /// Formats amount for native ETH payments (in wei using scientific notation)
  String _formatAmountForNative(String amount) {
    try {
      // Convert decimal amount to double for scientific notation
      final amountDouble = double.parse(amount.replaceAll(",", "."));

      // Use scientific notation as recommended by ERC-681
      return "${amountDouble}e18";
    } catch (e) {
      // Fallback to original amount if parsing fails
      return amount.replaceAll(",", ".");
    }
  }

  static int _getChainID(String path) =>
      int.tryParse(
        RegExp(r"@\d*").firstMatch(path)?.group(0)?.replaceAll("@", "") ?? "1",
      ) ??
      1;

  static (bool, String) _getTargetAddress(String path) {
    // I saw in the schema (thanks Konsti) that EIP-681 allows an optional "pay-" prefix before the target address, so adding a check for it here
    final cleaned = path.startsWith("pay-") ? path.substring(4) : path;
    final match = RegExp(r"^(0x)?[0-9a-f]{40}", caseSensitive: false).firstMatch(cleaned);
    final targetAddress = match?.group(0) ?? cleaned.split("@").first.split("/").first;
    return (cleaned.contains("/"), targetAddress);
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
      if (isPlainInteger) {
        return raw.replaceFirst(RegExp(r"^\+"), "");
      }

      // Then we check if it's a scientific notation
      if (_scientificPattern.hasMatch(raw)) {
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

    // If none of these checks work, we return the raw input
  }

  /// Expands a decimal string by shifting the decimal point `expShift` places
  /// to the right and returns an integer string (digits only, optional leading minus).
  /// Examples:
  ///  _expandDecimal('0.123456', 18) -> '123456000000000000'
  ///  _expandDecimal('1.2', 3) -> '1200'
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
      if (cut <= 0) {
        return "0";
      }
      final res = digits.substring(0, cut);
      return sign + (res.isEmpty ? "0" : res);
    }
  }
}

class LightningPaymentRequest extends PaymentURI {
  LightningPaymentRequest({
    required super.address,
    required super.amount,
    required this.lnURL,
    this.bolt11Invoice,
  });

  final String lnURL;
  final String? bolt11Invoice;

  @override
  String toString() => bolt11Invoice ?? "lightning:$lnURL";
}
