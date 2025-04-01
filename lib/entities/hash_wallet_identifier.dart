import 'dart:convert';

import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cw_core/wallet_base.dart';
import 'package:hashlib/hashlib.dart';

String createHashedWalletIdentifier(WalletBase wallet) {
  if (wallet.seed == null) return '';

  final salt = secrets.walletGroupSalt;
  final combined = '$salt.${wallet.seed}';

  // Convert to UTF-8 bytes.
  final bytes = utf8.encode(combined);

  // Perform SHA-256 hash.
  final digest = sha256.convert(bytes);

  // Return the hex string representation of the hash.
  return digest.toString();
}
