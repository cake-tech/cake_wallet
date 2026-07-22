import "dart:convert";

import "package:bech32/bech32.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/utils/proxy_wrapper.dart";

const _BOLT_PREFIXES = ["lnbcrt", "lntbs", "lnbc", "lntb"];
const _LUD17_PREFIXES = ["lnurlw", "lnurlc", "lnurlp", "keyauth"];

bool isBolt11ZeroInvoice(String invoice) {
  try {
    final request =
        const Bech32Codec().decode(invoice.replaceFirst("lightning:", ""), invoice.length);

    final prefix =
        _BOLT_PREFIXES.firstWhere(request.hrp.startsWith, orElse: () => "");

    return request.hrp.length == prefix.length;
  } catch (e) {
    return false;
  }
}

/// Get the amount of a Bolt 11 Invoice in
int? _getAmountBolt11Msat(String invoice) {
  final request =
      const Bech32Codec().decode(invoice.replaceFirst("lightning:", ""), invoice.length);

  final prefix = _BOLT_PREFIXES.firstWhere(
    request.hrp.startsWith,
    orElse: () => throw const FormatException("Invalid BOLT11 invoice: unknown HRP prefix."),
  );

  final amountPart = request.hrp.substring(prefix.length);
  if (amountPart.isEmpty) {
    return null; // zero-amount invoice
  }

  final hasMultiplier = RegExp(r"[munp]$").hasMatch(amountPart);
  final multiplier = hasMultiplier ? amountPart[amountPart.length - 1] : "";
  final numberStr = hasMultiplier ? amountPart.substring(0, amountPart.length - 1) : amountPart;

  if (numberStr.isEmpty || !RegExp(r"^\d+$").hasMatch(numberStr)) {
    throw const FormatException("Invalid BOLT11 invoice: invalid amount number in HRP.");
  }

  final amount = int.parse(numberStr);

  switch (multiplier) {
    case "": // bitcoin
      return amount * 100000000000;
    case "m": // milli-bitcoin
      return amount * 100000000;
    case "u": // micro-bitcoin
      return amount * 100000;
    case "n": // nano-bitcoin
      return amount * 100;
    case "p":
      if (amount % 10 != 0) {
        throw const FormatException(
          "Invalid BOLT11 invoice: amount not representable in whole msat.",
        );
      }
      return amount ~/ 10;
    default:
      throw const FormatException("Invalid BOLT11 invoice: unknown amount multiplier.");
  }
}

Money? getBolt11Amount(String invoice) {
  final msat = _getAmountBolt11Msat(invoice);
  if (msat == null || msat % 1000 != 0) {
    return null;
  }

  return Money.fromInt(msat ~/ 1000, CryptoCurrency.btcln);
}

class LNURL {
  static Future<Money?> getPayRequestAmount(String lnurl) async {
    final url = decode(lnurl);
    final response = await ProxyWrapper().get(clearnetUri: url);

    if (response.statusCode != 200) {
      return null;
    }

    try {
      final body = jsonDecode(response.body) as Map;
      final tag = body["tag"] as String?;

      if (tag != "payRequest") {
        return null;
      }

      final msat = body["minSendable"] as int?;
      final maxSendable = body["maxSendable"] as int?;

      // if minSendable and maxSendable are the same we assume a specific payment request
      if (msat != maxSendable) {
        return null;
      }

      if (msat == null || msat % 1000 != 0) {
        return null;
      }
      return Money.fromInt(msat ~/ 1000, CryptoCurrency.btcln);
    } catch (_) {
      return null;
    }
  }

  static Future<LNURLWithdrawRequest?> getWithdrawRequest(String lnurl) async {
    final url = decode(lnurl);
    final response = await ProxyWrapper().get(clearnetUri: url);

    if (response.statusCode != 200) {
      return null;
    }

    try {
      final body = jsonDecode(response.body) as Map;
      final tag = body["tag"] as String?;

      if (tag != "withdrawRequest") {
        return null;
      }

      final minWithdrawable = body["minWithdrawable"] as int?;
      final maxWithdrawable = body["maxWithdrawable"] as int?;

      if ((minWithdrawable == null || minWithdrawable % 1000 != 0) ||
          (maxWithdrawable == null || maxWithdrawable % 1000 != 0)) {
        return null;
      }

      return LNURLWithdrawRequest(
        callback: body["callback"] as String,
        k1: body["k1"] as String,
        description: body["defaultDescription"] as String,
        minAmount: Money.fromInt(minWithdrawable ~/ 1000, CryptoCurrency.btcln),
        maxAmount: Money.fromInt(maxWithdrawable ~/ 1000, CryptoCurrency.btcln),
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> commitWithdrawRequest(LNURLWithdrawRequest request, String invoice) async {
    try {
      final url = Uri.parse(request.callback);
      url.queryParameters["k1"] = request.k1;
      url.queryParameters["pr"] = invoice;

      final response = await ProxyWrapper().get(clearnetUri: url);

      if (response.statusCode != 200) {
        return false;
      }

      final body = jsonDecode(response.body) as Map;
      final status = body["status"] as String?;

      if (status == "OK") {
        return true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  static String encode(String url) {
    final raw = _convert(utf8.encode(url), 8, 5, true);
    return const Bech32Codec().encode(Bech32("lnurl", raw), 999);
  }

  static Uri decode(String encodedUrl) {
    Uri decodedUri;

    /// The URL doesn't have to be encoded at all as per LUD-17: Protocol schemes and raw (non bech32-encoded) URLs.
    /// https://github.com/lnurl/luds/blob/luds/17.md
    /// Handle non bech32-encoded LNURL
    decodedUri = Uri.parse(encodedUrl);
    for (final prefix in _LUD17_PREFIXES) {
      if (decodedUri.scheme.contains(prefix)) {
        decodedUri = decodedUri.replace(scheme: prefix);
      }
    }
    if (_LUD17_PREFIXES.contains(decodedUri.scheme)) {
      /// If the non-bech32 LNURL is a Tor address, the port has to be http instead of https for the clearnet LNURL so check if the host ends with '.onion' or '.onion.'
      decodedUri = decodedUri.replace(
        scheme: decodedUri.host.endsWith("onion") || decodedUri.host.endsWith("onion.")
            ? "http"
            : "https",
      );
    } else {
      /// Try to parse the input as a lnUrl. Will throw an error if it fails.
      final lnUrl = _findLnUrl(encodedUrl);

      /// Decode the lnurl using bech32
      final bech32 = const Bech32Codec().decode(lnUrl, lnUrl.length);
      decodedUri = Uri.parse(utf8.decode(_convert(bech32.data, 5, 8, false)));
    }
    return decodedUri;
  }
}

class LNURLWithdrawRequest {
  const LNURLWithdrawRequest({
    required this.callback,
    required this.k1,
    required this.description,
    required this.minAmount,
    required this.maxAmount,
  });

  final String callback;
  final String k1;
  final String description;
  final Money minAmount;
  final Money maxAmount;
}

/// Parse and return a given lnurl string if it's valid. Will remove
/// `lightning:` from the beginning of it if present.
String _findLnUrl(String input) {
  final res = RegExp(r",*?((lnurl)([0-9]+[a-z0-9]+))").allMatches(input.toLowerCase());

  if (res.length != 1) {
    throw ArgumentError("Not a valid lnurl string");
  }
  return res.first.group(0)!;
}

/// Taken from bech32 (bitcoinjs): https://github.com/bitcoinjs/bech32
List<int> _convert(List<int> data, int inBits, int outBits, bool pad) {
  var value = 0;
  var bits = 0;
  final maxV = (1 << outBits) - 1;

  final result = <int>[];
  for (final dataValue in data) {
    value = (value << inBits) | dataValue;
    bits += inBits;

    while (bits >= outBits) {
      bits -= outBits;
      result.add((value >> bits) & maxV);
    }
  }

  if (pad) {
    if (bits > 0) {
      result.add((value << (outBits - bits)) & maxV);
    }
  } else {
    if (bits >= inBits) {
      throw Exception("[BECH32] Excess padding");
    }
    if ((value << (outBits - bits)) & maxV > 0) {
      throw Exception("[BECH32] Non-zero padding");
    }
  }

  return result;
}
