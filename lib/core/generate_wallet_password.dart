import 'package:uuid/uuid.dart';
import 'package:cake_wallet/bitcoin/key.dart';
import 'package:cake_wallet/entities/wallet_type.dart';

String generateWalletPassword(WalletType type) {
  switch (type) {
    case WalletType.monero:
      return Uuid().v4();
    default:
      return generateKey();
  }
}
