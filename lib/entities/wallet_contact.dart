import 'package:cake_wallet/entities/contact_base.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_type.dart';

class WalletContact implements ContactBase {
  WalletContact(this.address, this.name, this.type, {this.walletType, this.chainId});

  @override
  String address;

  @override
  String name;

  @override
  CryptoCurrency type;

  final WalletType? walletType;

  final int? chainId;

  String get displayName => "";

  set displayName(String _) {}
}
