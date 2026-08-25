import 'package:cw_core/receive_page_option.dart';

enum PivxAddressType {
  transparent,
  shieldedSapling,
}

class PivxReceivePageOption implements ReceivePageOption {
  const PivxReceivePageOption._(this.type,
      {this.iconPath,
      this.description,
      this.isCommon = false,
      this.addAddressWord = false});

  factory PivxReceivePageOption.fromType(final PivxAddressType type) {
    switch (type) {
      case PivxAddressType.transparent:
        return transparent;
      case PivxAddressType.shieldedSapling:
        return shieldedSapling;
    }
  }

  static const transparent = PivxReceivePageOption._(
    PivxAddressType.transparent,
    description: 'P2PKH',
    // shared eye icon, same as Zcash Transparent
    iconPath: 'assets/new-ui/address-type-picker-icons/zec/transparent.svg',
    isCommon: true,
    addAddressWord: true,
  );
  static const shieldedSapling = PivxReceivePageOption._(
    PivxAddressType.shieldedSapling,
    description: 'Sapling',
    // shared shield icon, same as Zcash Shielded
    iconPath: 'assets/new-ui/address-type-picker-icons/zec/shielded.svg',
    isCommon: true,
    addAddressWord: true,
  );

  final PivxAddressType type;
  final String? iconPath;
  final String? description;
  final bool isCommon;
  final bool addAddressWord;

  String get value {
    switch (type) {
      case PivxAddressType.transparent:
        return "Transparent";
      case PivxAddressType.shieldedSapling:
        return "Shielded";
    }
  }

  String toString() {
    return value;
  }

  static const all = [
    PivxReceivePageOption.transparent,
    PivxReceivePageOption.shieldedSapling,
  ];

  PivxAddressType toType() {
    return type;
  }
}
