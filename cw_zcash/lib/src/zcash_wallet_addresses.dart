import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_zcash/cw_zcash.dart';
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
  String get address {
    switch (addressPageType) {
      case ZcashAddressType.transparent:
        return transparentAddress;
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
  late ZcashAddressType addressPageType = ZcashReceivePageOption.typeFromString(walletInfo.addressPageType ?? "");

  @action
  Future<void> setAddressType(final ZcashAddressType type) async {
    printV("I do not mind doing a print here $type");
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
  String get addressForExchange => address;

  @override
  bool containsAddress(final String address) {
    return this.address == address || addressesMap.values.contains(address);
  }

  @override
  Future<void> init() async {
    addressesMap = await walletInfo.getAddresses();
    addressInfos = await walletInfo.getAddressInfos();
    usedAddresses = await walletInfo.getUsedAddresses();
    manualAddresses = await walletInfo.getManualAddresses();
    hiddenAddresses = await walletInfo.getHiddenAddresses();

    if (addressInfos.isEmpty || addressesMap.isEmpty) {
      final primaryAddr = address;
      if (primaryAddr.isNotEmpty) {
        addressesMap[primaryAddr] = primaryAddr;
        allAddressesMap[primaryAddr] = primaryAddr;

        addressInfos[unifiedType] ??= [];
        if (!addressInfos[unifiedType]!.any((final info) => info.address == primaryAddr)) {
          addressInfos[unifiedType]!.add(
            WalletInfoAddressInfo(
              walletInfoId: walletInfo.internalId,
              mapKey: unifiedType,
              accountIndex: accountId,
              address: primaryAddr,
              label: "Unified Address",
            ),
          );
        }
      }

      final tAddr = transparentAddress;
      if (tAddr.isNotEmpty && !addressesMap.containsKey(tAddr)) {
        addressesMap[tAddr] = tAddr;
        allAddressesMap[tAddr] = tAddr;

        addressInfos[transparentType] ??= [];
        if (!addressInfos[transparentType]!.any((final info) => info.address == tAddr)) {
          addressInfos[transparentType]!.add(
            WalletInfoAddressInfo(
              walletInfoId: walletInfo.internalId,
              mapKey: transparentType,
              accountIndex: accountId,
              address: tAddr,
              label: "Transparent Address",
            ),
          );
        }
      }

      final sAddr = saplingAddress;
      if (sAddr.isNotEmpty && !addressesMap.containsKey(sAddr)) {
        addressesMap[sAddr] = sAddr;
        allAddressesMap[sAddr] = sAddr;

        addressInfos[shieldedSaplingType] ??= [];
        if (!addressInfos[shieldedSaplingType]!.any((final info) => info.address == sAddr)) {
          addressInfos[shieldedSaplingType]!.add(
            WalletInfoAddressInfo(
              walletInfoId: walletInfo.internalId,
              mapKey: shieldedSaplingType,
              accountIndex: accountId,
              address: sAddr,
              label: "Shielded Address (Sapling)",
            ),
          );
        }
      }

      final oAddr = orchardAddress;
      if (oAddr.isNotEmpty && !addressesMap.containsKey(oAddr)) {
        addressesMap[oAddr] = oAddr;
        allAddressesMap[oAddr] = oAddr;

        addressInfos[shieldedOrchardType] ??= [];
        if (!addressInfos[shieldedOrchardType]!.any((final info) => info.address == oAddr)) {
          addressInfos[shieldedOrchardType]!.add(
            WalletInfoAddressInfo(
              walletInfoId: walletInfo.internalId,
              mapKey: shieldedOrchardType,
              accountIndex: accountId,
              address: oAddr,
              label: "Shielded Address (Orchard)",
            ),
          );
        }
      }

      await saveAddressesInBox();
    }
  }

  @override
  String get latestAddress => address;

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

    await init();
  }

  @override
  Map<String, String> get usableAddressesMap => addressesMap;

  @override
  Map<String, String> get usableAllAddressesMap => allAddressesMap;

  @override
  set address(final String address) {
    throw UnimplementedError();
  }

  List<WalletInfoAddressInfo> getAddressInfos() {
    final List<WalletInfoAddressInfo> allInfos = [];
    for (final entry in addressInfos.entries) {
      allInfos.addAll(entry.value);
    }
    return allInfos;
  }
}
