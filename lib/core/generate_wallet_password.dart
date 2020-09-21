import 'package:uuid/uuid.dart';
import 'package:cake_wallet/bitcoin/key.dart';
import 'package:cake_wallet/entities/wallet_type.dart';

String generateWalletPassword(WalletType type) {
  switch (type) {
    case WalletType.bitcoin:
      return generateKey();
    default:
      return Uuid().v4();
  }
}
