import 'package:bitbox/bitbox.dart' as bitbox;
import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';

part 'electrum_wallet_addresses.g.dart';

class ElectrumWalletAddresses = ElectrumWalletAddressesBase with _$ElectrumWalletAddresses;

abstract class ElectrumWalletAddressesBase extends WalletAddresses with Store {
  ElectrumWalletAddressesBase(
    WalletInfo walletInfo, {
    required this.mainHd,
    required this.sideHd,
    required this.network,
    List<BitcoinAddressRecord>? initialAddresses,
    Map<String, int>? initialRegularAddressIndex,
    Map<String, int>? initialChangeAddressIndex,
    List<BitcoinAddressRecord>? initialSilentAddresses,
    int initialSilentAddressIndex = 0,
    SilentPaymentOwner? silentAddress,
  })  : _addresses = ObservableList<BitcoinAddressRecord>.of((initialAddresses ?? []).toSet()),
        primarySilentAddress = silentAddress,
        addressesByReceiveType =
            ObservableList<BitcoinAddressRecord>.of((<BitcoinAddressRecord>[]).toSet()),
        receiveAddresses = ObservableList<BitcoinAddressRecord>.of((initialAddresses ?? [])
            .where((addressRecord) => !addressRecord.isHidden && !addressRecord.isUsed)
            .toSet()),
        changeAddresses = ObservableList<BitcoinAddressRecord>.of((initialAddresses ?? [])
            .where((addressRecord) => addressRecord.isHidden && !addressRecord.isUsed)
            .toSet()),
        currentReceiveAddressIndexByType = initialRegularAddressIndex ?? {},
        currentChangeAddressIndexByType = initialChangeAddressIndex ?? {},
        _addressPageType = walletInfo.addressPageType != null
            ? BitcoinAddressType.fromValue(walletInfo.addressPageType!)
            : SegwitAddresType.p2wpkh,
        silentAddresses = ObservableList<BitcoinAddressRecord>.of((initialSilentAddresses ?? [])
            .where((addressRecord) => addressRecord.silentPaymentTweak != null)
            .toSet()),
        currentSilentAddressIndex = initialSilentAddressIndex,
        super(walletInfo) {
    updateAddressesByMatch();
  }

  static const defaultReceiveAddressesCount = 22;
  static const defaultChangeAddressesCount = 17;
  static const gap = 20;

  static String toCashAddr(String address) => bitbox.Address.toCashAddress(address);

  static String toLegacy(String address) => bitbox.Address.toLegacyAddress(address);

  final ObservableList<BitcoinAddressRecord> addresses;
  final ObservableList<BitcoinAddressRecord> receiveAddresses;
  final ObservableList<BitcoinAddressRecord> changeAddresses;
  final ObservableList<BitcoinAddressRecord> silentAddresses;
  final BasedUtxoNetwork network;
  final bitcoin.HDWallet mainHd;
  final bitcoin.HDWallet sideHd;

  final SilentPaymentOwner? primarySilentAddress;

  @observable
  BitcoinAddressType _addressPageType = SegwitAddresType.p2wpkh;

  @computed
  BitcoinAddressType get addressPageType => _addressPageType;

  @observable
  String? activeSilentAddress;

  @computed
  List<BitcoinAddressRecord> get allAddresses => _addresses;

  @override
  @computed
  String get address {
    if (addressPageType == SilentPaymentsAddresType.p2sp) {
      if (activeSilentAddress != null) {
        return activeSilentAddress!;
      }

      return primarySilentAddress!.toString();
    }

    String receiveAddress;

    final typeMatchingReceiveAddresses = receiveAddresses.where(_isAddressPageTypeMatch);

    if ((isEnabledAutoGenerateSubaddress && receiveAddresses.isEmpty) ||
        typeMatchingReceiveAddresses.isEmpty) {
      receiveAddress = generateNewAddress().address;
    } else {
      final previousAddressMatchesType =
          previousAddressRecord != null && previousAddressRecord!.type == addressPageType;

      if (previousAddressMatchesType &&
          typeMatchingReceiveAddresses.first.address != addressesByReceiveType.first.address) {
        receiveAddress = previousAddressRecord!.address;
      } else {
        receiveAddress = typeMatchingReceiveAddresses.first.address;
      }
      final receiveAddress = receiveAddresses.first.address;

      return walletInfo.type == WalletType.bitcoinCash
          ? toCashAddr(receiveAddress)
          : receiveAddress;
    } else {
      final receiveAddress = (receiveAddresses.first.address != addresses.first.address &&
              previousAddressRecord != null)
          ? previousAddressRecord!.address
          : addresses.first.address;

      return walletInfo.type == WalletType.bitcoinCash
          ? toCashAddr(receiveAddress)
          : receiveAddress;
    }
  }

  @observable
  bool isEnabledAutoGenerateSubaddress = true;

  @override
  set address(String addr) {
    if (addressPageType == SilentPaymentsAddresType.p2sp) {
      activeSilentAddress = addr;
      return;
    }

    if (addr.startsWith('bitcoincash:')) {
      addr = toLegacy(addr);
    }
    final addressRecord = addresses.firstWhere((addressRecord) => addressRecord.address == addr);

    previousAddressRecord = addressRecord;
    receiveAddresses.remove(addressRecord);
    receiveAddresses.insert(0, addressRecord);
  }

  @override
  String get primaryAddress => getAddress(index: 0, hd: mainHd);

  int currentReceiveAddressIndex;
  int currentChangeAddressIndex;

  int currentSilentAddressIndex;

  @observable
  BitcoinAddressRecord? previousAddressRecord;

  @computed
  int get totalCountOfReceiveAddresses => addresses.fold(0, (acc, addressRecord) {
        if (!addressRecord.isHidden) {
          return acc + 1;
        }
        return acc;
      });

  @computed
  int get totalCountOfChangeAddresses => addresses.fold(0, (acc, addressRecord) {
        if (addressRecord.isHidden) {
          return acc + 1;
        }
        return acc;
      });

  Future<void> discoverAddresses() async {
    await _discoverAddresses(mainHd, false);
    await _discoverAddresses(sideHd, true);
    await updateAddressesInBox();
  }

  @override
  Future<void> init() async {
    await _generateInitialAddresses();
    updateReceiveAddresses();
    updateChangeAddresses();
    await updateAddressesInBox();

    if (currentReceiveAddressIndex >= receiveAddresses.length) {
      currentReceiveAddressIndex = 0;
    }

    if (currentChangeAddressIndex >= changeAddresses.length) {
      currentChangeAddressIndex = 0;
    }
  }

  @action
  Future<String> getChangeAddress() async {
    updateChangeAddresses();

    if (changeAddresses.isEmpty) {
      final newAddresses = await _createNewAddresses(gap,
          hd: sideHd,
          startIndex: totalCountOfChangeAddresses > 0 ? totalCountOfChangeAddresses - 1 : 0,
          isHidden: true);
      _addAddresses(newAddresses);
    }

    if (currentChangeAddressIndex >= changeAddresses.length) {
      currentChangeAddressIndex = 0;
    }

    updateChangeAddresses();
    final address = changeAddresses[currentChangeAddressIndex].address;
    currentChangeAddressIndex += 1;
    return address;
  }

  Map<String, String> get labels {
    final labels = <String, String>{};
    for (int i = 0; i < silentAddresses.length; i++) {
      final silentAddressRecord = silentAddresses[i];
      final silentAddress =
          SilentPaymentDestination.fromAddress(silentAddressRecord.address, 0).B_spend.toHex();

      if (silentAddressRecord.silentPaymentTweak != null)
        labels[silentAddress] = silentAddressRecord.silentPaymentTweak!;
    }
    return labels;
  }

  BitcoinAddressRecord generateNewAddress({String label = ''}) {
    if (addressPageType == SilentPaymentsAddresType.p2sp) {
      currentSilentAddressIndex += 1;

      final tweak = BigInt.from(currentSilentAddressIndex);

      final address = BitcoinAddressRecord(
        SilentPaymentAddress.createLabeledSilentPaymentAddress(
                primarySilentAddress!.B_scan, primarySilentAddress!.B_spend, tweak,
                hrp: primarySilentAddress!.hrp, version: primarySilentAddress!.version)
            .toString(),
        index: currentSilentAddressIndex,
        isHidden: false,
        name: label,
        silentPaymentTweak: tweak.toString(),
        network: network,
        type: SilentPaymentsAddresType.p2sp,
      );

      silentAddresses.add(address);

      return address;
    }

    final newAddressIndex = addressesByReceiveType.fold(
        0, (int acc, addressRecord) => addressRecord.isHidden == false ? acc + 1 : acc);

    final newAddressIndex = addresses.fold(
        0, (int acc, addressRecord) => isHidden == addressRecord.isHidden ? acc + 1 : acc);

    final address = BitcoinAddressRecord(getAddress(index: newAddressIndex, hd: hd ?? sideHd),
        index: newAddressIndex, isHidden: isHidden, name: label ?? '');
    addresses.add(address);
    return address;
  }

  String getAddress({required int index, required bitcoin.HDWallet hd}) => '';

  @override
  Future<void> updateAddressesInBox() async {
    try {
      addressesMap.clear();
      addressesMap[address] = '';
      await saveAddressesInBox();
    } catch (e) {
      print(e.toString());
    }
  }

  @action
  void updateAddress(String address, String label) {
    if (address.startsWith('bitcoincash:')) {
      address = toLegacy(address);
    }
    final addressRecord = addresses.firstWhere((addressRecord) => addressRecord.address == address);
    addressRecord.setNewName(label);
    final index = addresses.indexOf(addressRecord);
    addresses.remove(addressRecord);
    addresses.insert(index, addressRecord);
  }

  @action
  void updateReceiveAddresses() {
    receiveAddresses.removeRange(0, receiveAddresses.length);
    final newAddresses =
        addresses.where((addressRecord) => !addressRecord.isHidden && !addressRecord.isUsed);
    receiveAddresses.addAll(newAddresses);
  }

  @action
  void updateChangeAddresses() {
    changeAddresses.removeRange(0, changeAddresses.length);
    final newAddresses =
        addresses.where((addressRecord) => addressRecord.isHidden && !addressRecord.isUsed);
    changeAddresses.addAll(newAddresses);
  }

  Future<void> _discoverAddresses(bitcoin.HDWallet hd, bool isHidden) async {
    var hasAddrUse = true;
    List<BitcoinAddressRecord> addrs;

    if (addresses.isNotEmpty) {


      if(!isHidden) {
        final receiveAddressesList = addresses.where((addr) => !addr.isHidden).toList();
        validateSideHdAddresses(receiveAddressesList);
      }

      addrs = addresses.where((addr) => addr.isHidden == isHidden).toList();
    } else {
      addrs = await _createNewAddresses(
          isHidden ? defaultChangeAddressesCount : defaultReceiveAddressesCount,
          startIndex: 0,
          hd: hd,
          isHidden: isHidden);
    }

    while (hasAddrUse) {
      final addr = addrs.last.address;
      hasAddrUse = await _hasAddressUsed(addr);

      if (!hasAddrUse) {
        break;
      }

      final start = addrs.length;
      final count = start + gap;
      final batch = await _createNewAddresses(count, startIndex: start, hd: hd, isHidden: isHidden);
      addrs.addAll(batch);
    }

    if (addresses.length < addrs.length) {
      _addAddresses(addrs);
    }
  }

  Future<void> _generateInitialAddresses() async {
    var countOfReceiveAddresses = 0;
    var countOfHiddenAddresses = 0;

    addresses.forEach((addr) {
      if (addr.isHidden) {
        countOfHiddenAddresses += 1;
        return;
      }

      countOfReceiveAddresses += 1;
    });

    if (countOfReceiveAddresses < defaultReceiveAddressesCount) {
      final addressesCount = defaultReceiveAddressesCount - countOfReceiveAddresses;
      final newAddresses = await _createNewAddresses(addressesCount,
          startIndex: countOfReceiveAddresses, hd: mainHd, isHidden: false);
      addresses.addAll(newAddresses);
    }

    if (countOfHiddenAddresses < defaultChangeAddressesCount) {
      final addressesCount = defaultChangeAddressesCount - countOfHiddenAddresses;
      final newAddresses = await _createNewAddresses(addressesCount,
          startIndex: countOfHiddenAddresses, hd: sideHd, isHidden: true);
      addresses.addAll(newAddresses);
    }
  }

  Future<List<BitcoinAddressRecord>> _createNewAddresses(int count,
      {required bitcoin.HDWallet hd, int startIndex = 0, bool isHidden = false}) async {
    final list = <BitcoinAddressRecord>[];

    for (var i = startIndex; i < count + startIndex; i++) {
      final address =
          BitcoinAddressRecord(getAddress(index: i, hd: hd), index: i, isHidden: isHidden);
      list.add(address);
    }

    return list;
  }

  void _addAddresses(Iterable<BitcoinAddressRecord> addresses) {
    final addressesSet = this.addresses.toSet();
    addressesSet.addAll(addresses);
    this.addresses.removeRange(0, this.addresses.length);
    this.addresses.addAll(addressesSet);
  }

  Future<bool> _hasAddressUsed(String address) async {
    final sh = scriptHash(address, networkType: networkType);
    final transactionHistory = await electrumClient.getHistory(sh);
    return transactionHistory.isNotEmpty;
  }

  void validateSideHdAddresses(List<BitcoinAddressRecord> addrWithTransactions) {
    addrWithTransactions.forEach((element) {
      if (element.address != getAddress(index: element.index, hd: mainHd)) element.isHidden = true;
    });
  }
}
