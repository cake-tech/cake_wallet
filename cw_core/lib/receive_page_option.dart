import 'package:cw_core/enumerate.dart';

class ReceivePageOption implements Enumerate {
  static const mainnet = ReceivePageOption._('mainnet');
  static const testnet = ReceivePageOption._('testnet');
  static const anonPayInvoice = ReceivePageOption._('anonPayInvoice');
  static const anonPayDonationLink = ReceivePageOption._('anonPayDonationLink');

  const ReceivePageOption._(this.value, {this.iconPath, this.description, this.isCommon = false});

  final String value;
  final String? iconPath;
  final String? description;
  final bool isCommon;

  String toString() {
    return value;
  }
}

const ReceivePageOptions = [
  ReceivePageOption.mainnet,
  ReceivePageOption.anonPayInvoice,
  ReceivePageOption.anonPayDonationLink
];
