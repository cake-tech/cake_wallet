import 'package:cw_core/receive_page_option.dart';
import 'package:cw_core/utils/print_verbose.dart';

enum ZcashAddressType {
  transparent,
  transparentRotated,
  shieldedSapling,
  shieldedOrchard,
  unifiedType,
}

class ZcashReceivePageOption implements ReceivePageOption {
  factory ZcashReceivePageOption.fromType(final ZcashAddressType type) {
    switch (type) {
      case ZcashAddressType.transparent:
        return transparent;
      case ZcashAddressType.transparentRotated:
        return transparentRotated;
      case ZcashAddressType.shieldedSapling:
        return shieldedSapling;
      case ZcashAddressType.shieldedOrchard:
        return shieldedOrchard;
      case ZcashAddressType.unifiedType:
        return unified;
    }
  }
  const ZcashReceivePageOption._(
    this.type,
    this.value, {
    this.iconPath,
    this.description,
    this.isCommon = false,
  });

  final String value;
  final String? iconPath;
  final String? description;
  final bool isCommon;
  final bool addAddressWord = false;

  static const transparent = ZcashReceivePageOption._(
    ZcashAddressType.transparent,
    "Public",
    description: "Static & Transparent",
    iconPath: "assets/new-ui/address-type-picker-icons/zec/public.svg",
  );
  static const transparentRotated = ZcashReceivePageOption._(
    ZcashAddressType.transparentRotated,
    "Transparent",
    description: "Disposable",
    iconPath: "assets/new-ui/address-type-picker-icons/zec/transparent.svg",
    isCommon: true,
  );
  static const shieldedSapling = ZcashReceivePageOption._(
    ZcashAddressType.shieldedSapling,
    "Legacy Shielded",
    description: "Sapling",
    iconPath: "assets/new-ui/address-type-picker-icons/zec/sapling.svg",
  );
  static const shieldedOrchard = ZcashReceivePageOption._(
    ZcashAddressType.shieldedOrchard,
    "Shielded",
    description: "Default (Orchard)",
    iconPath: "assets/new-ui/address-type-picker-icons/zec/shielded.svg",
    isCommon: true,
  );
  static const unified = ZcashReceivePageOption._(
    ZcashAddressType.unifiedType,
    "Unified",
    description: "Compatible Shielded",
    iconPath: "assets/new-ui/address-type-picker-icons/zec/unified.svg",
    isCommon: true,
  );

  final ZcashAddressType type;

  String toString() {
    return value;
  }

  static const all = [
    ZcashReceivePageOption.shieldedOrchard,
    ZcashReceivePageOption.shieldedSapling,
    ZcashReceivePageOption.unified,
    ZcashReceivePageOption.transparentRotated,
    ZcashReceivePageOption.transparent,
  ];

  ZcashAddressType toType() {
    return type;
  }

  static ZcashAddressType typeFromString(final String str) {
    for (int i = 0; i < ZcashAddressType.values.length; i++) {
      if (str == ZcashAddressType.values[i].toString()) {
        return ZcashAddressType.values[i];
      }
    }
    printV("Not found for: $str");
    return ZcashAddressType.shieldedOrchard;
  }
}
