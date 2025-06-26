import 'dart:async';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:bitcoin_base_old/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_unspent.dart';
import 'package:cw_bitcoin/litecoin_address_record.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_bitcoin/electrum_wallet_addresses.dart';
import 'package:cw_core/unspent_coin_type.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_mweb/cw_mweb.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';

part 'litecoin_wallet_addresses.g.dart';

class LitecoinWalletAddresses = LitecoinWalletAddressesBase with _$LitecoinWalletAddresses;

abstract class LitecoinWalletAddressesBase extends ElectrumWalletAddresses with Store {
  LitecoinWalletAddressesBase(
    WalletInfo walletInfo, {
    required super.mainHd,
    required super.sideHd,
    required super.network,
    required super.isHardwareWallet,
    required this.mwebHd,
    required this.mwebEnabled,
    super.initialAddresses,
    super.initialMwebAddresses,
    super.initialRegularAddressIndex,
    super.initialChangeAddressIndex,
  }) : _addressPageType = 
      (walletInfo.addressPageType != null
          ? BitcoinAddressType.fromValue(walletInfo.addressPageType!)
          : SegwitAddresType.p2wpkh), super(walletInfo) {
    for (int i = 0; i < mwebAddresses.length; i++) {
      mwebAddrs.add(mwebAddresses[i].address);
    }
    printV("initialized with ${mwebAddrs.length} mweb addresses");
  }

  final Bip32Slip10Secp256k1? mwebHd;
  bool mwebEnabled;
  int mwebTopUpIndex = 1000;
  List<String> mwebAddrs = [];
  bool generating = false;

  List<int> get scanSecret => mwebHd!.childKey(Bip32KeyIndex(0x80000000)).privateKey.privKey.raw;
  List<int> get spendPubkey =>
      mwebHd!.childKey(Bip32KeyIndex(0x80000001)).publicKey.pubKey.compressed;

  @override
  Future<void> init() async {
    if (!isHardwareWallet) await initMwebAddresses();
    await super.init();
  }

  @computed
  @override
  List<BitcoinAddressRecord> get allAddresses {
    return List.from(super.allAddresses)..addAll(mwebAddresses);
  }

  Future<void> ensureMwebAddressUpToIndexExists(int index) async {
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      return null;
    }

    Uint8List scan = Uint8List.fromList(scanSecret);
    Uint8List spend = Uint8List.fromList(spendPubkey);

    if (index < mwebAddresses.length && index < mwebAddrs.length) {
      return;
    }

    while (generating) {
      printV("generating.....");
      // this function was called multiple times in multiple places:
      await Future.delayed(const Duration(milliseconds: 100));
    }

    printV("Generating MWEB addresses up to index $index");
    generating = true;
    try {
      while (mwebAddrs.length <= (index + 1)) {
        final addresses =
            await CwMweb.addresses(scan, spend, mwebAddrs.length, mwebAddrs.length + 50);
        printV("generated up to index ${mwebAddrs.length}");
        // sleep for a bit to avoid making the main thread unresponsive:
        await Future.delayed(Duration(milliseconds: 200));
        mwebAddrs.addAll(addresses!);
      }
    } catch (_) {}
    generating = false;
    printV("Done generating MWEB addresses len: ${mwebAddrs.length}");

    // ensure mweb addresses are up to date:
    // This is the Case if the Litecoin Wallet is a hardware Wallet
    if (mwebHd == null) return;

    if (mwebAddresses.length < mwebAddrs.length) {
      List<BitcoinAddressRecord> addressRecords = mwebAddrs
          .asMap()
          .entries
          .map((e) => LitecoinAddressRecord(
                e.value,
                index: e.key,
                type: SegwitAddresType.mweb,
                network: network,
              ))
          .toList();
      addMwebAddresses(addressRecords);
      printV("set ${addressRecords.length} mweb addresses");
    }
  }

  Future<void> initMwebAddresses() async {
    if (mwebAddrs.length < 1000) {
      await ensureMwebAddressUpToIndexExists(20);
      return;
    }
  }

  @override
  String getAddress({
    required int index,
    required Bip32Slip10Secp256k1 hd,
    BitcoinAddressType? addressType,
  }) {
    if (addressType == SegwitAddresType.mweb) {
      return hd == sideHd ? mwebAddrs[0] : mwebAddrs[index + 1];
    }
    return generateP2WPKHAddress(hd: hd, index: index, network: network);
  }

  @override
  Future<String> getAddressAsync({
    required int index,
    required Bip32Slip10Secp256k1 hd,
    BitcoinAddressType? addressType,
  }) async {
    if (addressType == SegwitAddresType.mweb) {
      await ensureMwebAddressUpToIndexExists(index);
    }
    return getAddress(index: index, hd: hd, addressType: addressType);
  }

  @action
  @override
  Future<BitcoinAddressRecord> getChangeAddress(
      {List<BitcoinUnspent>? inputs,
      List<BitcoinOutput>? outputs,
      UnspentCoinType coinTypeToSpendFrom = UnspentCoinType.any}) async {
    // use regular change address on peg in, otherwise use mweb for change address:

    if (!mwebEnabled || coinTypeToSpendFrom == UnspentCoinType.nonMweb) {
      return super.getChangeAddress();
    }

    if (inputs != null && outputs != null) {
      // check if this is a PEGIN:
      bool outputsToMweb = false;
      bool comesFromMweb = false;

      for (var i = 0; i < outputs.length; i++) {
        // TODO: probably not the best way to tell if this is an mweb address
        // (but it doesn't contain the "mweb" text at this stage)
        if (outputs[i].address.toAddress(network).length > 110) {
          outputsToMweb = true;
        }
      }

      inputs.forEach((element) {
        if (!element.isSending || element.isFrozen) {
          return;
        }
        if (element.address.contains("mweb")) {
          comesFromMweb = true;
        }
      });

      bool isPegIn = !comesFromMweb && outputsToMweb;
      bool isNonMweb = !comesFromMweb && !outputsToMweb;

      // use regular change address if it's not an mweb tx or if it's a peg in:
      if (isPegIn || isNonMweb) {
        return super.getChangeAddress();
      }
    }

    if (mwebEnabled) {
      await ensureMwebAddressUpToIndexExists(1);
      updateChangeAddresses();
      return BitcoinAddressRecord(
        mwebAddrs[0],
        index: 0,
        type: SegwitAddresType.mweb,
        network: network,
      );
    }

    return super.getChangeAddress();
  }

  @override
  String get addressForExchange {
    // don't use mweb addresses for exchange refund address:
    final addresses = receiveAddresses
        .where((element) => element.type == SegwitAddresType.p2wpkh && !element.isUsed);
    return addresses.first.address;
  }

  static const defaultReceiveAddressesCount = 22;
  static const defaultChangeAddressesCount = 17;
  static const gap = 20;

  @observable
  late BitcoinAddressType _addressPageType;

  @computed
  BitcoinAddressType get addressPageType => _addressPageType;


  @override
  @computed
  String get address {
    if (addressPageType == SilentPaymentsAddresType.p2sp) {
      if (activeSilentAddress != null) {
        return activeSilentAddress!;
      }

      return silentAddress.toString();
    }

    final typeMatchingAddresses = super.allAddresses.where((addr) => !addr.isHidden && _isAddressPageTypeMatch(addr)).toList();
    final typeMatchingReceiveAddresses = typeMatchingAddresses.where((addr) => !addr.isUsed).toList();

    if (!isEnabledAutoGenerateSubaddress) {
      if (previousAddressRecord != null &&
          previousAddressRecord!.type == addressPageType) {
        return previousAddressRecord!.address;
      }

      if (typeMatchingAddresses.isNotEmpty) {
        return typeMatchingAddresses.first.address;
      }

      return generateNewAddress().address;
    }

    if (typeMatchingAddresses.isEmpty || typeMatchingReceiveAddresses.isEmpty) {
      return generateNewAddress().address;
    }

    final prev = previousAddressRecord;
    if (prev != null && prev.type == addressPageType && !prev.isUsed) {
      return prev.address;
    }

    return typeMatchingReceiveAddresses.first.address;
  }

  @observable
  bool isEnabledAutoGenerateSubaddress = true;

  @override
  set address(String addr) {
    if (addr == "Silent Payments" && SilentPaymentsAddresType.p2sp != addressPageType) {
      return;
    }
    if (addressPageType == SilentPaymentsAddresType.p2sp) {
      final selected = silentAddresses.firstWhere((addressRecord) => addressRecord.address == addr);

      if (selected.silentPaymentTweak != null && silentAddress != null) {
        activeSilentAddress =
            silentAddress!.toLabeledSilentPaymentAddress(selected.index).toString();
      } else {
        activeSilentAddress = silentAddress!.toString();
      }
      return;
    }
    try {
      final addressRecord = super.allAddresses.firstWhere(
            (addressRecord) => addressRecord.address == addr,
      );

      previousAddressRecord = addressRecord;
      receiveAddresses.remove(addressRecord);
      receiveAddresses.insert(0, addressRecord);
    } catch (e) {
      printV("ElectrumWalletAddressBase: set address ($addr): $e");
    }
  }

  @override
  String get primaryAddress => getAddress(index: 0, hd: mainHd, addressType: addressPageType);

  int get currentReceiveAddressIndex =>
      currentReceiveAddressIndexByType[_addressPageType.toString()] ?? 0;

  void set currentReceiveAddressIndex(int index) =>
      currentReceiveAddressIndexByType[_addressPageType.toString()] = index;

  int get currentChangeAddressIndex =>
      currentChangeAddressIndexByType[_addressPageType.toString()] ?? 0;

  void set currentChangeAddressIndex(int index) =>
      currentChangeAddressIndexByType[_addressPageType.toString()] = index;

  @observable
  BitcoinAddressRecord? previousAddressRecord;

  @computed
  int get totalCountOfReceiveAddresses => addressesByReceiveType.fold(0, (acc, addressRecord) {
    if (!addressRecord.isHidden) {
      return acc + 1;
    }
    return acc;
  });

  @computed
  int get totalCountOfChangeAddresses => addressesByReceiveType.fold(0, (acc, addressRecord) {
    if (addressRecord.isHidden) {
      return acc + 1;
    }
    return acc;
  });

  Map<String, String> get labels {
    final G = ECPublic.fromBytes(BigintUtils.toBytes(Curves.generatorSecp256k1.x, length: 32));
    final labels = <String, String>{};
    for (int i = 0; i < silentAddresses.length; i++) {
      final silentAddressRecord = silentAddresses[i];
      final silentPaymentTweak = silentAddressRecord.silentPaymentTweak;

      if (silentPaymentTweak != null &&
          SilentPaymentAddress.regex.hasMatch(silentAddressRecord.address)) {
        labels[G
            .tweakMul(BigintUtils.fromBytes(BytesUtils.fromHexString(silentPaymentTweak)))
            .toHex()] = silentPaymentTweak;
      }
    }
    return labels;
  }

  @action
  BaseBitcoinAddressRecord generateNewAddress({String label = ''}) {
    final newAddressIndex = addressesByReceiveType.fold(
        0, (int acc, addressRecord) => addressRecord.isHidden == false ? acc + 1 : acc);

    final address = BitcoinAddressRecord(
      getAddress(index: newAddressIndex, hd: mainHd, addressType: addressPageType),
      index: newAddressIndex,
      isHidden: false,
      name: label,
      type: addressPageType,
      network: network,
    );
    Future.delayed(Duration.zero, () {
      super.allAddresses.add(address);
      updateAddressesByMatch();
    });
    return address;
  }

  void addLitecoinAddressTypes() {
    final lastP2wpkh = super.allAddresses
        .where((addressRecord) =>
        _isUnusedReceiveAddressByType(addressRecord, SegwitAddresType.p2wpkh))
        .toList()
        .last;
    if (lastP2wpkh.address != address) {
      addressesMap[lastP2wpkh.address] = 'P2WPKH';
    } else {
      addressesMap[address] = 'Active - P2WPKH';
    }

    final lastMweb = super.allAddresses.firstWhere(
            (addressRecord) => _isUnusedReceiveAddressByType(addressRecord, SegwitAddresType.mweb));
    if (lastMweb.address != address) {
      addressesMap[lastMweb.address] = 'MWEB';
    } else {
      addressesMap[address] = 'Active - MWEB';
    }
  }

  @override
  Future<void> updateAddressesInBox() async {
    try {
      addressesMap.clear();
      addressesMap[address] = 'Active';

      allAddressesMap.clear();
      super.allAddresses.forEach((addressRecord) {
        allAddressesMap[addressRecord.address] = addressRecord.name;
      });

      switch (walletInfo.type) {
        case WalletType.bitcoin:
          addBitcoinAddressTypes();
          break;
        case WalletType.litecoin:
          addLitecoinAddressTypes();
          break;
        case WalletType.bitcoinCash:
          addBitcoinCashAddressTypes();
          break;
        default:
          break;
      }

      await saveAddressesInBox();
    } catch (e) {
      printV("updateAddresses $e");
    }
  }

  @action
  void updateAddress(String address, String label) {
    BaseBitcoinAddressRecord? foundAddress;
    super.allAddresses.forEach((addressRecord) {
      if (addressRecord.address == address) {
        foundAddress = addressRecord;
      }
    });
    silentAddresses.forEach((addressRecord) {
      if (addressRecord.address == address) {
        foundAddress = addressRecord;
      }
    });
    mwebAddresses.forEach((addressRecord) {
      if (addressRecord.address == address) {
        foundAddress = addressRecord;
      }
    });

    if (foundAddress != null) {
      foundAddress!.setNewName(label);

      if (foundAddress is BitcoinAddressRecord) {
        final index = super.allAddresses.indexOf(foundAddress as BitcoinAddressRecord);
        super.allAddresses.remove(foundAddress);
        super.allAddresses.insert(index, foundAddress as BitcoinAddressRecord);
      } else {
        final index = silentAddresses.indexOf(foundAddress as BitcoinSilentPaymentAddressRecord);
        silentAddresses.remove(foundAddress);
        silentAddresses.insert(index, foundAddress as BitcoinSilentPaymentAddressRecord);
      }
    }
  }

  @action
  void updateAddressesByMatch() {
    if (addressPageType == SilentPaymentsAddresType.p2sp) {
      addressesByReceiveType.clear();
      addressesByReceiveType.addAll(silentAddresses);
      return;
    }

    addressesByReceiveType.clear();
    addressesByReceiveType.addAll(super.allAddresses.where(_isAddressPageTypeMatch).toList());
  }

  @action
  void updateReceiveAddresses() {
    receiveAddresses.removeRange(0, receiveAddresses.length);
    final newAddresses =
    super.allAddresses.where((addressRecord) => !addressRecord.isHidden && !addressRecord.isUsed);
    receiveAddresses.addAll(newAddresses);
  }

  @action
  void updateChangeAddresses() {
    changeAddresses.removeRange(0, changeAddresses.length);
    final newAddresses = super.allAddresses.where((addressRecord) =>
    addressRecord.isHidden &&
        !addressRecord.isUsed &&
        // TODO: feature to change change address type. For now fixed to p2wpkh, the cheapest type
        (walletInfo.type != WalletType.bitcoin || addressRecord.type == SegwitAddresType.p2wpkh));
    changeAddresses.addAll(newAddresses);
  }

  @action
  Future<void> discoverAddresses(List<BitcoinAddressRecord> addressList, bool isHidden,
      Future<String?> Function(BitcoinAddressRecord) getAddressHistory,
      {BitcoinAddressType type = SegwitAddresType.p2wpkh}) async {
    final newAddresses = await _createNewAddresses(gap,
        startIndex: addressList.length, isHidden: isHidden, type: type);
    addAddresses(newAddresses);

    final addressesWithHistory = await Future.wait(newAddresses.map(getAddressHistory));
    final isLastAddressUsed = addressesWithHistory.last == addressList.last.address;

    if (isLastAddressUsed) {
      discoverAddresses(addressList, isHidden, getAddressHistory, type: type);
    }
  }

  Future<void> _generateInitialAddresses(
      {BitcoinAddressType type = SegwitAddresType.p2wpkh}) async {
    var countOfReceiveAddresses = 0;
    var countOfHiddenAddresses = 0;

    super.allAddresses.forEach((addr) {
      if (addr.type == type) {
        if (addr.isHidden) {
          countOfHiddenAddresses += 1;
          return;
        }

        countOfReceiveAddresses += 1;
      }
    });

    if (countOfReceiveAddresses < defaultReceiveAddressesCount) {
      final addressesCount = defaultReceiveAddressesCount - countOfReceiveAddresses;
      final newAddresses = await _createNewAddresses(addressesCount,
          startIndex: countOfReceiveAddresses, isHidden: false, type: type);
      addAddresses(newAddresses);
    }

    if (countOfHiddenAddresses < defaultChangeAddressesCount) {
      final addressesCount = defaultChangeAddressesCount - countOfHiddenAddresses;
      final newAddresses = await _createNewAddresses(addressesCount,
          startIndex: countOfHiddenAddresses, isHidden: true, type: type);
      addAddresses(newAddresses);
    }
  }

  Future<List<BitcoinAddressRecord>> _createNewAddresses(int count,
      {int startIndex = 0, bool isHidden = false, BitcoinAddressType? type}) async {
    final list = <BitcoinAddressRecord>[];

    for (var i = startIndex; i < count + startIndex; i++) {
      final address = BitcoinAddressRecord(
        await getAddressAsync(index: i, hd: _getHd(isHidden), addressType: type ?? addressPageType),
        index: i,
        isHidden: isHidden,
        type: type ?? addressPageType,
        network: network,
      );
      list.add(address);
    }

    return list;
  }

  @action
  void addAddresses(Iterable<BitcoinAddressRecord> addresses) {
    final addressesSet = super.allAddresses.toSet();
    addressesSet.addAll(addresses);
    super.allAddresses.clear();
    super.allAddresses.addAll(addressesSet);
    updateAddressesByMatch();
  }

  @action
  void addSilentAddresses(Iterable<BitcoinSilentPaymentAddressRecord> addresses) {
    final addressesSet = this.silentAddresses.toSet();
    addressesSet.addAll(addresses);
    this.silentAddresses.clear();
    this.silentAddresses.addAll(addressesSet);
    updateAddressesByMatch();
  }

  @action
  void addMwebAddresses(Iterable<BitcoinAddressRecord> addresses) {
    final addressesSet = this.mwebAddresses.toSet();
    addressesSet.addAll(addresses);
    this.mwebAddresses.clear();
    this.mwebAddresses.addAll(addressesSet);
    updateAddressesByMatch();
  }

  void _validateAddresses() {
    super.allAddresses.forEach((element) async {
      if (element.type == SegwitAddresType.mweb) {
        // this would add a ton of startup lag for mweb addresses since we have 1000 of them
        return;
      }
      if (!element.isHidden &&
          element.address !=
              await getAddressAsync(index: element.index, hd: mainHd, addressType: element.type)) {
        element.isHidden = true;
      } else if (element.isHidden &&
          element.address !=
              await getAddressAsync(index: element.index, hd: sideHd, addressType: element.type)) {
        element.isHidden = false;
      }
    });
  }

  @action
  Future<void> setAddressType(BitcoinAddressType type) async {
    _addressPageType = type;
    updateAddressesByMatch();
    walletInfo.addressPageType = addressPageType.toString();
    await walletInfo.save();
  }

  bool _isAddressPageTypeMatch(BitcoinAddressRecord addressRecord) {
    return _isAddressByType(addressRecord, addressPageType);
  }

  Bip32Slip10Secp256k1 _getHd(bool isHidden) => isHidden ? sideHd : mainHd;

  bool _isAddressByType(BitcoinAddressRecord addr, BitcoinAddressType type) => addr.type == type;

  bool _isUnusedReceiveAddressByType(BitcoinAddressRecord addr, BitcoinAddressType type) =>
      !addr.isHidden && !addr.isUsed && addr.type == type;
}
