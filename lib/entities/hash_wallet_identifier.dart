import 'dart:convert';

import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cw_core/wallet_base.dart';
import 'package:hashlib/hashlib.dart';

String createHashedWalletIdentifier(WalletBase wallet) {
  final hashContent = wallet.seed ?? wallet.walletAddresses.primaryAddress;

  final salt = secrets.walletGroupSalt;
  final combined = '$salt.$hashContent';

  final bytes = utf8.encode(combined);
  final digest = sha256.convert(bytes);
  return digest.toString();
}
