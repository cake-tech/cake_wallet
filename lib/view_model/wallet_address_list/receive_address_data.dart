import "package:cw_core/payment_uris.dart";
import "package:cw_core/wallet_type.dart";

abstract interface class ReceiveAddressData {
  PaymentURI get uri;
  WalletType get type;
}
