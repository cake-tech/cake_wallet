import 'package:cake_wallet/src/domain/common/wallet_type.dart';

class WalletDescription {
  WalletDescription({this.name, this.type});
  
  final String name;
  final WalletType type;
}