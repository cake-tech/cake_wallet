import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_zcash/cw_zcash.dart';
import 'package:cw_zcash/src/zcash_taddress_rotation.dart';
import 'package:mobx/mobx.dart';
import 'package:warp_api/warp_api.dart';

part 'zcash_wallet_addresses.g.dart';

class ZcashWalletAddresses = ZcashWalletAddressesBase with _$ZcashWalletAddresses;

abstract class ZcashWalletAddressesBase extends WalletAddresses with Store {
  ZcashWalletAddressesBase(this.accountId, final WalletInfo walletInfo) : super(walletInfo) {
    addressPageType = ZcashReceivePageOption.typeFromString(walletInfo.addressPageType ?? "");
  }

  final int accountId;

  static const int transparentType = 0;
  static const int shieldedSaplingType = 1;
  static const int shieldedOrchardType = 2;
  static const int unifiedType = 3;

  String? _transparentAddress;
  String? _saplingAddress;
  String? _orchardAddress;
  String? _unifiedAddress;

  @override
  @computed
  String get latestAddress {
    switch (addressPageType) {
      case ZcashAddressType.transparent:
        return transparentAddress;
      case ZcashAddressType.transparentRotated:
        // just to display something, after the wallet is synced the address
        // will start rotating, and since we can't rotate address until the wallet syncs
        // we can't know if some T address already got used, so we would still default to
        // the same address.
        // So.. we can
        // 1) display placeholder text (looks ugly)
        // 2) display static address
        // 3) display first address from rotated pool which is also static until synced
        // 2 seems like an obvious winner simply because it offers little to no benefit over 3
        // and is noticably less complex in implementation
        return transparentAddressRotated ?? transparentAddress;
      case ZcashAddressType.shieldedSapling:
        return saplingAddress;
      case ZcashAddressType.shieldedOrchard:
        return orchardAddress;
      case ZcashAddressType.unifiedType:
        if (_unifiedAddress == null) {
          _unifiedAddress = WarpApi.getAddress(ZcashWalletBase.coin, accountId, 7);
        }
        return _unifiedAddress ?? "";
    }
  }

  @observable
  ZcashAddressType? _addressPageType;

  @computed
  ZcashAddressType get addressPageType => _addressPageType ?? ZcashAddressType.shieldedOrchard;

  @computed
  set addressPageType(final ZcashAddressType newZat) {
    _addressPageType = newZat;
    init();
    address = latestAddress;
  }

  @action
  Future<void> setAddressType(final ZcashAddressType type) async {
    addressPageType = ZcashReceivePageOption.typeFromString(type.toString());
    walletInfo.addressPageType = type.toString();
    await walletInfo.save();
  }

  String get transparentAddress {
    try {
      if (_transparentAddress == null) {
        _transparentAddress = WarpApi.getTAddr(ZcashWalletBase.coin, accountId);
      }
      return _transparentAddress ?? "";
    } catch (e) {
      return "";
    }
  }

  @computed
  String? get transparentAddressRotated {
    try {
      return ZcashTaddressRotation.addressForAccount(accountId);
    } catch (e) {
      return null;
    }
  }

  String get saplingAddress {
    try {
      if (_saplingAddress == null) {
        _saplingAddress = WarpApi.getAddress(ZcashWalletBase.coin, accountId, 2);
      }
      return _saplingAddress ?? "";
    } catch (e) {
      return "";
    }
  }

  String get orchardAddress {
    try {
      if (_orchardAddress == null) {
        _orchardAddress = WarpApi.getAddress(ZcashWalletBase.coin, accountId, 4);
      }
      return _orchardAddress ?? "";
    } catch (e) {
      return "";
    }
  }

  @override
  String get addressForExchange => transparentAddressRotated ?? transparentAddress;

  @override
  bool containsAddress(final String address) {
    return this.address == address || addressesMap.values.contains(address);
  }

  static int get coin => ZcashWalletBase.coin;

  @override
  Future<void> init() async {
    addressesMap = await walletInfo.getAddresses();
    addressInfos = await walletInfo.getAddressInfos();
    usedAddresses = await walletInfo.getUsedAddresses();
    manualAddresses = await walletInfo.getManualAddresses();
    hiddenAddresses = await walletInfo.getHiddenAddresses();

    addressesMap = {"a": "b"};

    await ZcashTaddressRotation.init();
    printV(ZcashTaddressRotation.rotationAccounts.keys);
    int accountIndex = 0;
    addressInfos = {
      0:
          ZcashTaddressRotation.allAddressesForAccount(accountId)?.map((final v) {
            return WalletInfoAddressInfo(
              walletInfoId: walletInfo.internalId,
              mapKey: ++accountIndex,
              accountIndex: 0,
              address: v,
              label: "",
            );
          }).toList() ??
          [],
    };
    hiddenAddresses = ZcashTaddressRotation.allUsedAddressesForAccount(accountId)?.toSet() ?? {};

    addressInfos[0]?.removeWhere((final test) => hiddenAddresses.contains(test.address));
    if (_addressPageType == ZcashAddressType.transparentRotated) {
      final addr = ZcashTaddressRotation.addressForAccount(accountId);
      if (addr != null) {
        address = addr;      
      }
    }
    await saveAddressesInBox();
  }

  @override
  @observable
  late String _address = latestAddress;

  String get address {
    if (addressPageType == ZcashAddressType.transparentRotated) {
      return transparentAddressRotated ?? transparentAddress;
    }
    return _address;
  }

  void set address(final String _$address) => _address = _$address;

  @override
  String get primaryAddress => address;

  @override
  Future<void> saveAddressesInBox() async {
    try {
      await walletInfo.setAddresses(addressesMap);
      await walletInfo.setAddressInfos(addressInfos);
      await walletInfo.setUsedAddresses(usedAddresses.toList());
      await walletInfo.setHiddenAddresses(hiddenAddresses.toList());
      await walletInfo.setManualAddresses(manualAddresses.toList());
    } catch (e) {
      printV("Error saving addresses: $e");
    }
  }

  @override
  Future<void> updateAddressesInBox() async {
    _transparentAddress = null;
    _saplingAddress = null;
    _orchardAddress = null;
    _unifiedAddress = null;
  }

  @override
  Map<String, String> get usableAddressesMap => addressesMap;

  @override
  Map<String, String> get usableAllAddressesMap => allAddressesMap;

  List<WalletInfoAddressInfo> getAddressInfos() {
    if (addressPageType != ZcashAddressType.transparentRotated) {
      return [];
    }
    final List<WalletInfoAddressInfo> allInfos = [];
    for (final entry in addressInfos.entries) {
      allInfos.addAll(entry.value);
    }
    return allInfos;
  }
}
