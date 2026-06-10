import 'package:cw_core/payment_uris.dart';
import 'package:cw_core/receive_page_option.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_zcash/cw_zcash.dart';
import 'package:cw_zcash/src/zcash_taddress_rotation.dart';
import 'package:mobx/mobx.dart';
import 'package:zkool/src/rust/api/account.dart' as zkool_account;

part 'zcash_wallet_addresses.g.dart';

class ZcashWalletAddresses = ZcashWalletAddressesBase with _$ZcashWalletAddresses;

abstract class ZcashWalletAddressesBase extends WalletAddresses with Store {
  ZcashWalletAddressesBase(this.accountId, final WalletInfo walletInfo) : super(walletInfo) {
    addressPageType = ZcashReceivePageOption.typeFromString(walletInfo.addressPageType ?? "");
  }

  int accountId;

  static const int transparentType = 0;
  static const int shieldedSaplingType = 1;
  static const int shieldedOrchardType = 2;
  static const int unifiedType = 3;

  @observable
  String? transparentAddress;

  @observable
  String? _transparentObservableAddress;

  @observable
  String? saplingAddress;

  @observable
  String? orchardAddress;

  @observable
  String? unifiedAddress;

  @override
  @computed
  String get latestAddress {
    switch (addressPageType) {
      case ZcashAddressType.transparent:
        return transparentAddress ?? "unknown transparentAddress";
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
        return _transparentObservableAddress ??
            transparentAddress ??
            "unknown transparentAddressRotated";
      case ZcashAddressType.shieldedSapling:
        return saplingAddress ?? "unknown saplingAddress";
      case ZcashAddressType.shieldedOrchard:
        return orchardAddress ?? "unknown orchardAddress";
      case ZcashAddressType.unifiedType:
        return unifiedAddress ?? "unknown unifiedAddress";
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

  @override
  @computed
  String get addressForExchange =>
      _transparentObservableAddress ?? transparentAddress ?? "unknown addressForExchange";

  @override
  @computed
  String get addressForBuy =>
      _transparentObservableAddress ?? transparentAddress ?? "unknown addressForBuy";

  @override
  bool containsAddress(final String address) {
    return this.address == address || addressesMap.values.contains(address);
  }

  @override
  @observable
  Set<String> hiddenAddresses = {};

  Future<void> _initAddresses() async {
    addressesMap = await walletInfo.getAddresses();
    addressInfos = await walletInfo.getAddressInfos();
    usedAddresses = await walletInfo.getUsedAddresses();
    manualAddresses = await walletInfo.getManualAddresses();
    hiddenAddresses = await walletInfo.getHiddenAddresses();
    address = latestAddress;
  }

  @override
  Future<void> init() async {
    try {
      await _init();
    } catch (e) {
      printV("init failed, retrying in 2 seconds");
      printV(e);
      await Future.delayed(Duration(seconds: 2));
      await init();
    }
  }

  Future<void> _init() async {
    await _initAddresses();

    final addr = await zkool_account.getAddresses(c: ZcashWalletBase.c, uaPools: 7);

    transparentAddress = addr.taddr ?? 'unknown addr.taddr';
    saplingAddress = addr.saddr ?? 'unknown addr.saddr';
    orchardAddress = addr.oaddr ?? 'unknown addr.oaddr';
    unifiedAddress = addr.ua ?? 'unknown addr.ua';
    _transparentObservableAddress = (await ZcashTaddressRotation.addressForAccount(accountId));
    int accountIndex = 0;
    addressInfos = {
      0:
          (await ZcashTaddressRotation.allAddressesForAccount(accountId))?.map((final v) {
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
    hiddenAddresses.addAll(
      (await ZcashTaddressRotation.allUsedAddressesForAccount(accountId))?.toSet() ?? {},
    );

    // addressInfos[0]?.removeWhere((final test) => hiddenAddresses.contains(test.address));
    if (_addressPageType == ZcashAddressType.transparentRotated) {
      final addr = await ZcashTaddressRotation.addressForAccount(accountId);
      if (addr != null) {
        address = addr;
      }
    } else {
      address = latestAddress;
    }
    await saveAddressesInBox();
  }

  @observable
  late String _address = latestAddress;

  @computed
  String get address {
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
      await _initAddresses();
      hiddenAddresses.addAll(
        (await ZcashTaddressRotation.allUsedAddressesForAccount(accountId))?.toSet() ?? {},
      );
    } catch (e) {
      printV("Error saving addresses: $e");
    }
  }

  @override
  Future<void> updateAddressesInBox() async {
    await _initAddresses();
  }

  @override
  Map<String, String> get usableAddressesMap => addressesMap;

  @override
  Map<String, String> get usableAllAddressesMap => allAddressesMap;

  List<WalletInfoAddressInfo> getAddressInfos() {
    if (addressPageType != ZcashAddressType.transparentRotated) {
      return [];
    }
    final rotationAddresses = ZcashTaddressRotation.rotationAddresses[accountId];
    if (rotationAddresses != null && rotationAddresses.isNotEmpty) {
      final addresses = rotationAddresses.toList();
      return [
        for (int i = 0; i < addresses.length; i++)
          WalletInfoAddressInfo(
            walletInfoId: walletInfo.internalId,
            mapKey: i + 1,
            accountIndex: 0,
            address: addresses[i],
            label: "",
          ),
      ];
    }
    final List<WalletInfoAddressInfo> allInfos = [];
    for (final entry in addressInfos.entries) {
      allInfos.addAll(entry.value);
    }
    return allInfos;
  }

  @override
  List<ReceivePageOption> get receivePageOptions {
    return [
      ...ZcashReceivePageOption.all,
      ...ReceivePageOptions.where((final element) => element != ReceivePageOption.mainnet),
    ];
  }

  @override
  PaymentURI getPaymentUri(final String amount) => ZcashURI(amount: amount, address: address);
}
