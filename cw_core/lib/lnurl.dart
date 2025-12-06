import 'dart:convert';

import 'package:bech32/bech32.dart';

String encodeLNURL(String url) {
  final raw = _convert(utf8.encode(url), 8, 5, true);
  return const Bech32Codec().encode(Bech32('lnurl', raw), 255);
}

Uri decodeLNURL(String encodedUrl) {
  Uri decodedUri;

  /// The URL doesn't have to be encoded at all as per LUD-17: Protocol schemes and raw (non bech32-encoded) URLs.
  /// https://github.com/lnurl/luds/blob/luds/17.md
  /// Handle non bech32-encoded LNURL
  final lud17prefixes = ['lnurlw', 'lnurlc', 'lnurlp', 'keyauth'];
  decodedUri = Uri.parse(encodedUrl);
  for (final prefix in lud17prefixes) {
    if (decodedUri.scheme.contains(prefix)) {
      decodedUri = decodedUri.replace(scheme: prefix);
    }
  }
  if (lud17prefixes.contains(decodedUri.scheme)) {
    /// If the non-bech32 LNURL is a Tor address, the port has to be http instead of https for the clearnet LNURL so check if the host ends with '.onion' or '.onion.'
    decodedUri = decodedUri.replace(
        scheme: decodedUri.host.endsWith('onion') ||
                decodedUri.host.endsWith('onion.')
            ? 'http'
            : 'https');
  } else {
    /// Try to parse the input as a lnUrl. Will throw an error if it fails.
    final lnUrl = _findLnUrl(encodedUrl);

    /// Decode the lnurl using bech32
    final bech32 = const Bech32Codec().decode(lnUrl, lnUrl.length);
    decodedUri = Uri.parse(utf8.decode(_convert(bech32.data, 5, 8, false)));
  }
  return decodedUri;
}

/// Parse and return a given lnurl string if it's valid. Will remove
/// `lightning:` from the beginning of it if present.
String _findLnUrl(String input) {
  final res = RegExp(
    r',*?((lnurl)([0-9]+[a-z0-9]+))',
  ).allMatches(input.toLowerCase());

  if (res.length == 1) {
    return res.first.group(0)!;
  } else {
    throw ArgumentError('Not a valid lnurl string');
  }
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
    if (bits > 0) result.add((value << (outBits - bits)) & maxV);
  } else {
    if (bits >= inBits) throw Exception('Excess padding');

    if ((value << (outBits - bits)) & maxV > 0) {
      throw Exception('Non-zero padding');
    }
  }

  return result;
}
