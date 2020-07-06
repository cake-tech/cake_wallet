import 'package:flutter/foundation.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';

class WalletListItem {
  const WalletListItem(
      {@required this.name, @required this.type, this.isCurrent = false});

  final String name;
  final WalletType type;
  final bool isCurrent;
}
