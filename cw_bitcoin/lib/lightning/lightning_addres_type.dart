import 'package:bitcoin_base/src/bitcoin/address/address.dart';

class LightningAddressType implements BitcoinAddressType {
  const LightningAddressType._(this.value);
  static const LightningAddressType p2l = LightningAddressType._("Lightning");

  static const String Bolt11InvoiceMatcher = r'^(lightning:)?(lnbc|lntb|lnbs|lnbcrt)[a-z0-9]+$';
  static const String Bolt12OfferMatcher = r'^(lightning:)?(lno1)[a-z0-9]+$';

  @override
  bool get isP2sh => false;
  @override
  bool get isSegwit => false;

  @override
  final String value;

  @override
  int get hashLength {
    return 32;
  }

  @override
  String toString() => value;
}
