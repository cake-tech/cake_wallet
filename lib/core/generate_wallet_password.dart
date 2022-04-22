import 'package:uuid/uuid.dart';
import 'package:cw_core/key.dart';
import 'package:cw_core/wallet_type.dart';

String generateWalletPassword(WalletType type) {
  switch (type) {
    case WalletType.monero:
      return Uuid().v4();
    default:
      return generateKey();
  }
}
