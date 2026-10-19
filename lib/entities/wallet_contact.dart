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

  /// The address's label in the wallet's address map (e.g. "Active - P2WPKH"). Unlike [name] it
  /// is never translated, so it is the one to match on.
  final String label;

  /// Whether the wallet currently hands out this address.
  bool get isActive => label.startsWith("Active");

  bool get isSilentPayment => label.contains("Silent Payments");

  /// Whether a currency-filtered picker may offer this address. Only senders that can build a
  /// Silent Payments output should set [includeSilentPayments].
  bool isPickable({required bool includeSilentPayments}) {
    if (isSilentPayment && !includeSilentPayments) {
      return false;
    }
    // Bitcoin and Litecoin wallets list an address per type; offer only the active ones.
    if (type == CryptoCurrency.btc || type == CryptoCurrency.ltc) {
      return isActive;
    }
    return true;
  }

  String get displayName => "";

  set displayName(String _) {}
}
