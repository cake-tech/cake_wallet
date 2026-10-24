import 'package:cw_core/enumerate.dart';

class ReceivePageOption implements Enumerate {
  static const mainnet = ReceivePageOption._('mainnet');
  static const testnet = ReceivePageOption._('testnet');

  const ReceivePageOption._(this.value,
      {this.iconPath, this.description, this.isCommon = false, this.addAddressWord = false});

  final String value;
  final String? iconPath;
  final String? description;
  final bool isCommon;
  final bool addAddressWord;
  bool get canRotateAddress => true;

  String toString() {
    return value;
  }
}

const ReceivePageOptions = [
  ReceivePageOption.mainnet,
];
