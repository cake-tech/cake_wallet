import 'package:cw_core/receive_page_option.dart';

class LightningReceivePageOption implements ReceivePageOption {
  static const lightningOnchain = LightningReceivePageOption._('lightningOnchain');
  static const lightningInvoice = LightningReceivePageOption._('lightningInvoice');

  const LightningReceivePageOption._(this.value);

  final String value;

  String toString() {
    return value;
  }

  static const all = [
    LightningReceivePageOption.lightningInvoice,
    LightningReceivePageOption.lightningOnchain
  ];
}
