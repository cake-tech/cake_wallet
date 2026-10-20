import 'package:cake_wallet/entities/contact_base.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_type.dart';

class WalletContact implements ContactBase {
  WalletContact(this.address, this.name, this.type, {this.walletType, this.label = ""});

  @override
  String address;

  @override
  String name;

  @override
  CryptoCurrency type;

  /// Wallet type of the wallet this contact belongs to
  /// Used for EVM chain filtering
  final WalletType? walletType;

  /// Untranslated address-map label, e.g. "Active - P2WPKH"; match on this, never on [name].
  final String label;

  bool get isActive => label.startsWith("Active");

  bool get isPickable {
    if (type == CryptoCurrency.btc || type == CryptoCurrency.ltc) {
      return isActive;
    }
    return true;
  }

  String get displayName => "";

  set displayName(String _) {}
}
