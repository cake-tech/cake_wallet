import 'dart:convert';
import 'package:mobx/mobx.dart';

import 'package:cw_core/address_info.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_decred/api/libdcrwallet.dart' as libdcrwallet;

part 'wallet_addresses.g.dart';

class DecredWalletAddresses = DecredWalletAddressesBase with _$DecredWalletAddresses;

abstract class DecredWalletAddressesBase extends WalletAddresses with Store {
  DecredWalletAddressesBase(WalletInfo walletInfo) : super(walletInfo);

  @observable
  String selectedAddr = '';

  @override
  @computed
  String get address {
    // Only request a new address from libwallet if an address wasn't already
    // selected. Libwallet will return an empty string if the wallet isn't
    // synced.
    if (selectedAddr == '') {
      // TODO: Consider simply returning whatever libwallet returns, and don't
      // auto-select the address returned by libwallet, so that if that address
      // becomes used, libwallet will be contacted to return a new unused
      // address. If the first unused address returned by libwallet is assigned
      // to `selectedAddr`, then it would always be returned subsequently even
      // if the address becomes used and libwallet would have returned a
      // different address.
      selectedAddr = libdcrwallet.currentReceiveAddress(walletInfo.name) ?? '';
    }
    return selectedAddr;
  }

  @override
  set address(value) {
    selectedAddr = value;
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
