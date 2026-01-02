import 'package:cw_core/receive_page_option.dart';
import 'package:cw_core/utils/print_verbose.dart';

enum ZcashAddressType {
  transparent,
  shieldedSapling,
  shieldedOrchard,
  unifiedType
}

class ZcashReceivePageOption implements ReceivePageOption {
  static const transparent = ZcashReceivePageOption._(ZcashAddressType.transparent);
  static const shieldedSapling = ZcashReceivePageOption._(ZcashAddressType.shieldedSapling);
  static const shieldedOrchard = ZcashReceivePageOption._(ZcashAddressType.shieldedOrchard);
  static const unified = ZcashReceivePageOption._(ZcashAddressType.unifiedType);

  const ZcashReceivePageOption._(this.type);

  final ZcashAddressType type;

  String get value => switch (type) {
    ZcashAddressType.transparent => "Transparent",
    ZcashAddressType.shieldedSapling => "Shielded (Sapling)",
    ZcashAddressType.shieldedOrchard => "Shielded (Orchard)",
    ZcashAddressType.unifiedType => "Unified"
  };

  String toString() {
    return value;
  }

  static const all = [
    ZcashReceivePageOption.unified,
    ZcashReceivePageOption.shieldedOrchard,
    ZcashReceivePageOption.shieldedSapling,
    ZcashReceivePageOption.transparent,
  ];

  factory ZcashReceivePageOption.fromType(ZcashAddressType type) {
    switch (type) {
    case ZcashAddressType.transparent:
      return transparent;
    case ZcashAddressType.shieldedSapling:
      return shieldedSapling;
    case ZcashAddressType.shieldedOrchard:
      return shieldedOrchard;
    case ZcashAddressType.unifiedType:
      return unified;
    }
  }

  ZcashAddressType toType() {
    return type;
  }

  static ZcashAddressType typeFromString(String str) {
    for (int i = 0; i < ZcashAddressType.values.length; i++) {
      if (str == ZcashAddressType.values[i].toString()) {
        return ZcashAddressType.values[i];
      }
    }
    printV("Not found for: $str");
    return ZcashAddressType.unifiedType;
  }
}
