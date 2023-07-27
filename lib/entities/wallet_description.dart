import 'package:cw_core/wallet_type.dart';

class WalletDescription {
  WalletDescription({required this.name, required this.type});
  
  final String name;
  final WalletType type;
}