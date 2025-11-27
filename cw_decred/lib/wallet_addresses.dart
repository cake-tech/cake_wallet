import 'dart:convert';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:mobx/mobx.dart';

import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_decred/api/libdcrwallet.dart';

part 'wallet_addresses.g.dart';

class DecredWalletAddresses = DecredWalletAddressesBase with _$DecredWalletAddresses;

abstract class DecredWalletAddressesBase extends WalletAddresses with Store {
  DecredWalletAddressesBase(WalletInfo walletInfo, Libwallet libwallet)
      : _libwallet = libwallet,
        super(walletInfo);
  final Libwallet _libwallet;
  String currentAddr = '';

  @observable
  bool isEnabledAutoGenerateSubaddress = true;

  @observable
  String selectedAddr = '';

  @override
  @computed
  String get address {
    return selectedAddr;
  }

  @override
  set address(value) {
    selectedAddr = value;
  }

  @override
  Future<void> init() async {
    addressesMap = await walletInfo.getAddresses();
    addressInfos = await walletInfo.getAddressInfos();
    usedAddresses = await walletInfo.getUsedAddresses();
    manualAddresses = await walletInfo.getManualAddresses();
    hiddenAddresses = await walletInfo.getHiddenAddresses();
    await updateAddressesInBox();
  }

  @override
  Future<void> updateAddressesInBox() async {
    final addrs = await libAddresses();
    final allAddrs = new List.from(addrs.usedAddrs)..addAll(addrs.unusedAddrs);

    // Add all addresses.
    allAddrs.forEach((addr) {
      if (addressesMap.containsKey(addr)) {
        return;
      }
      addressesMap[addr] = "";
      addressInfos[0] ??= [];
      addressInfos[0]?.add(
        WalletInfoAddressInfo(
          walletInfoId: walletInfo.internalId,
          mapKey: 0,
          address: addr,
          label: "",
          accountIndex: 0,
        ),
      );
    });

    // Add used addresses.
    addrs.usedAddrs.forEach((addr) {
      if (!usedAddresses.contains(addr)) {
        usedAddresses.add(addr);
      }
    });

    if (addrs.unusedAddrs.length > 0 && addrs.unusedAddrs[0] != currentAddr) {
      currentAddr = addrs.unusedAddrs[0];
      selectedAddr = currentAddr;
    }

    await saveAddressesInBox();
  }

  List<WalletInfoAddressInfo> getAddressInfos() {
    if (addressInfos.containsKey(0)) {
      return addressInfos[0]!;
    }
    return <WalletInfoAddressInfo>[];
  }

  Future<void> updateAddress(String address, String label) async {
    if (!addressInfos.containsKey(0)) {
      return;
    }
    addressInfos[0]!.forEach((info) {
      if (info.address == address) {
        info.label = label;
      }
    });
    await saveAddressesInBox();
  }

  Future<LibAddresses> libAddresses() async {
    final nUsed = "10";
    var nUnused = "1";
    if (this.isEnabledAutoGenerateSubaddress) {
      nUnused = "3";
    }
    try {
      final res = await _libwallet.addresses(walletInfo.name, nUsed, nUnused);
      final decoded = json.decode(res);
      final usedAddrs = List<String>.from(decoded["used"] ?? []);
      final unusedAddrs = List<String>.from(decoded["unused"] ?? []);
      // index is the index of the first unused address.
      final index = decoded["index"] ?? 0;
      return new LibAddresses(usedAddrs, unusedAddrs, index);
    } catch (e) {
      printV(e);
      return LibAddresses([], [], 0);
    }
  }

  Future<void> generateNewAddress(String label) async {
    // NOTE: This will ignore the gap limit and may cause problems when restoring from seed if too
    // many addresses are taken and not used.
    final addr = await _libwallet.newExternalAddress(walletInfo.name) ?? '';
    if (addr == "") {
      return;
    }
    if (!addressesMap.containsKey(addr)) {
      addressesMap[addr] = "";
      addressInfos[0] ??= [];
      addressInfos[0]?.add(
        WalletInfoAddressInfo(
          walletInfoId: walletInfo.internalId,
          mapKey: 0,
          address: addr,
          label: label,
          accountIndex: 0,
        ),
      );
    }
    selectedAddr = addr;
    await saveAddressesInBox();
  }
}

class LibAddresses {
  final List<String> usedAddrs, unusedAddrs;
  final int firstUnusedAddrIndex;

  LibAddresses(this.usedAddrs, this.unusedAddrs, this.firstUnusedAddrIndex);
}
