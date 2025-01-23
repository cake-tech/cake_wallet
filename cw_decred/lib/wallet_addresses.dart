import 'dart:convert';

import 'package:cw_core/address_info.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_decred/api/libdcrwallet.dart' as libdcrwallet;

class DecredWalletAddresses extends WalletAddresses {
  DecredWalletAddresses(WalletInfo walletInfo) : super(walletInfo);

  String currentAddr = '';

  @override
  String get address {
    // This will not return an address if the wallet is not synced.
    final cAddr = libdcrwallet.currentReceiveAddress(walletInfo.name) ?? '';
    if (cAddr != '') {
      currentAddr = cAddr;
    }
    return currentAddr;
  }

  @override
  Future<void> init() async {
    if (walletInfo.addresses != null) {
      addressesMap = walletInfo.addresses!;
    }
    if (walletInfo.addressInfos != null) {
      addressInfos = walletInfo.addressInfos!;
    }
    if (walletInfo.usedAddresses != null) {
      usedAddresses = {...walletInfo.usedAddresses!};
    }
    await updateAddressesInBox();
  }

  @override
  Future<void> updateAddressesInBox() async {
    final addrs = libAddresses();
    final allAddrs = new List.from(addrs.usedAddrs)..addAll(addrs.unusedAddrs);

    // Add all addresses.
    allAddrs.forEach((addr) {
      if (addressesMap.containsKey(addr)) {
        return;
      }
      addressesMap[addr] = "";
      addressInfos[0] ??= [];
      addressInfos[0]?.add(AddressInfo(address: addr, label: "", accountIndex: 0));
    });

    // Add used addresses.
    addrs.usedAddrs.forEach((addr) {
      if (!usedAddresses.contains(addr)) {
        usedAddresses.add(addr);
      }
    });

    await saveAddressesInBox();
  }

  String generateNewAddress() {
    final nAddr = libdcrwallet.newExternalAddress(walletInfo.name) ?? '';
    if (nAddr != '') {
      currentAddr = nAddr;
    }
    return nAddr;
  }

  List<AddressInfo> getAddressInfos() {
    if (addressInfos.containsKey(0)) {
      return addressInfos[0]!;
    }
    return <AddressInfo>[];
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

  LibAddresses libAddresses() {
    final nUsed = "10";
    final nUnused = "1";
    final res = libdcrwallet.addresses(walletInfo.name, nUsed, nUnused);
    final decoded = json.decode(res);
    final usedAddrs = List<String>.from(decoded["used"]);
    final unusedAddrs = List<String>.from(decoded["unused"]);
    // index is the index of the first unused address.
    final index = decoded["index"] ?? 0;
    return new LibAddresses(usedAddrs, unusedAddrs, index);
  }
}

class LibAddresses {
  final List<String> usedAddrs, unusedAddrs;
  final int firstUnusedAddrIndex;

  LibAddresses(this.usedAddrs, this.unusedAddrs, this.firstUnusedAddrIndex);
}
