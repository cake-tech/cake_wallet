import "dart:convert";

import "package:cake_wallet/.secrets.g.dart" as secrets;
import "package:convert/convert.dart";
import "package:crypto/crypto.dart";
import "package:cw_core/wallet_base.dart";

///# Madeleine Authentication
///
/// Madeleine supports two authentication levels, selected per endpoint based on sensitivity:
///
/// - **Light**: for wallet-bound endpoints.
/// - **Full**: for wallet-bound. Requires a wallet signature in addition to the shared-secret MAC.
///
/// All requests must include `X-Madeleine-Valid-Until`, a Unix timestamp (in seconds) after which the request is rejected. MAC values are hex-encoded.
///
/// ## Light Authentication
///
/// | Header                  | Value                                                                                      |
/// |-------------------------|--------------------------------------------------------------------------------------------|
/// | X-Madeleine-Valid-Until | `<unix_seconds>`                                                                           |
/// | X-Madeleine-Mac         | `HMAC-SHA256(madeleineSecret, "Madeleine Light Auth v1:\n<method> <path> <unix_seconds>")` |
///
/// ## Full Authentication
///
/// | Header                  | Value                                                                             |
/// |-------------------------|-----------------------------------------------------------------------------------|
/// | X-Madeleine-Signature   | `SignWallet("Madeleine Auth v1:\n<method> <path> <user_address> <unix_seconds>")` |
/// | X-Madeleine-Mac         | `HMAC-SHA256(madeleineSecret, <wallet_signature>)`                                |
/// | X-Madeleine-Valid-Until | `<unix_seconds>`                                                                  |
/// | X-Madeleine-Wallet      | `<user_address>`                                                                  |
class MadeleineAuth {
  const MadeleineAuth({required this.useSandbox});

  static const madeleineLightAuthMagic = "Madeleine Light Auth v1:\n";
  static const madeleineFullAuthMagic = "Madeleine Auth v1:\n";

  static const baseUrl = "madeleine.cakewallet.com";

  static String get _exchangeHelperApiKey => secrets.exchangeHelperApiKey;

  final bool useSandbox;

  Map<String, String> getLightHeaders({
    required String method,
    required String path,
    Map<String, String>? headers,
  }) {
    final validUntil = (DateTime.now().millisecondsSinceEpoch / 1000).round() + 10;

    final message = "$madeleineLightAuthMagic$method $path $validUntil";
    final hmac = _getHmac(message);

    headers ??= {};
    headers["X-Madeleine-Valid-Until"] = "$validUntil";
    headers["X-Madeleine-Mac"] = hmac;

    if (useSandbox) {
      headers["x-madeleine-sandbox"] = "true";
    }

    return headers;
  }

  Future<Map<String, String>> getFullHeaders({
    required String method,
    required String path,
    required WalletBase wallet,
    Map<String, String>? headers,
  }) async {
    final walletAddress = wallet.walletAddresses.address;
    final validUntil = (DateTime.now().millisecondsSinceEpoch / 1000).round() + 200;

    final message = "$madeleineFullAuthMagic$method $path $walletAddress $validUntil";
    final signature = await wallet.signMessage(message, address: walletAddress);
    final hmac = _getHmac(signature);

    headers ??= {};
    headers["X-Madeleine-Signature"] = signature;
    headers["X-Madeleine-Mac"] = hmac;
    headers["X-Madeleine-Valid-Until"] = "$validUntil";
    headers["X-Madeleine-Wallet"] = walletAddress;

    if (useSandbox) {
      headers["x-madeleine-sandbox"] = "true";
    }

    return headers;
  }

  String _getHmac(String message) {
    final key = utf8.encode(_exchangeHelperApiKey);
    final bytes = utf8.encode(message);

    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);

    return hex.encode(digest.bytes);
  }
}
