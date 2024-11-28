import 'dart:io' show Platform;

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_unspent.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';

part 'electrum_wallet_addresses.g.dart';

enum CWBitcoinDerivationType { old_electrum, electrum, old_bip39, bip39, mweb }

const OLD_DERIVATION_TYPES = [
  CWBitcoinDerivationType.old_electrum,
  CWBitcoinDerivationType.old_bip39
];

class ElectrumWalletAddresses = ElectrumWalletAddressesBase with _$ElectrumWalletAddresses;

abstract class ElectrumWalletAddressesBase extends WalletAddresses with Store {
  ElectrumWalletAddressesBase(
    WalletInfo walletInfo, {
    required this.hdWallets,
    required this.network,
    required this.isHardwareWallet,
    List<BitcoinAddressRecord>? initialAddresses,
    List<BitcoinAddressRecord>? initialMwebAddresses,
    BitcoinAddressType? initialAddressPageType,
  })  : _allAddresses = ObservableList.of(initialAddresses ?? []),
        addressesByReceiveType =
            ObservableList<BaseBitcoinAddressRecord>.of((<BitcoinAddressRecord>[]).toSet()),
        receiveAddresses = ObservableList<BitcoinAddressRecord>.of(
            (initialAddresses ?? []).where((addressRecord) => !addressRecord.isChange).toSet()),
        // TODO: feature to change change address type. For now fixed to p2wpkh, the cheapest type
        changeAddresses = ObservableList<BitcoinAddressRecord>.of(
            (initialAddresses ?? []).where((addressRecord) => addressRecord.isChange).toSet()),
        _addressPageType = initialAddressPageType ??
            (walletInfo.addressPageType != null
                ? BitcoinAddressType.fromValue(walletInfo.addressPageType!)
                : SegwitAddresType.p2wpkh),
        mwebAddresses =
            ObservableList<BitcoinAddressRecord>.of((initialMwebAddresses ?? []).toSet()),
        super(walletInfo) {
    updateAddressesByMatch();
  }

  static const defaultReceiveAddressesCount = 22;
  static const defaultChangeAddressesCount = 17;
  static const gap = 20;

  final ObservableList<BitcoinAddressRecord> _allAddresses;
  final ObservableList<BaseBitcoinAddressRecord> addressesByReceiveType;
  final ObservableList<BitcoinAddressRecord> receiveAddresses;
  final ObservableList<BitcoinAddressRecord> changeAddresses;
  // TODO: add this variable in `litecoin_wallet_addresses` and just add a cast in cw_bitcoin to use it
  final ObservableList<BitcoinAddressRecord> mwebAddresses;
  final BasedUtxoNetwork network;

  final Map<CWBitcoinDerivationType, Bip32Slip10Secp256k1> hdWallets;
  Bip32Slip10Secp256k1 get hdWallet =>
      hdWallets[CWBitcoinDerivationType.bip39] ?? hdWallets[CWBitcoinDerivationType.electrum]!;

  final bool isHardwareWallet;

  @observable
  late BitcoinAddressType _addressPageType;

  @computed
  BitcoinAddressType get addressPageType => _addressPageType;

  @computed
  List<BitcoinAddressRecord> get allAddresses => _allAddresses.toList();

  @computed
  Set<String> get allScriptHashes =>
      _allAddresses.map((addressRecord) => addressRecord.scriptHash).toSet();

  BitcoinAddressRecord getFromAddresses(String address) {
    return _allAddresses.firstWhere((element) => element.address == address);
  }

  @override
  @computed
  String get address {
    String receiveAddress;

    final typeMatchingReceiveAddresses =
        receiveAddresses.where(_isAddressPageTypeMatch).where((addr) => !addr.isUsed);

    if ((isEnabledAutoGenerateSubaddress && receiveAddresses.isEmpty) ||
        typeMatchingReceiveAddresses.isEmpty) {
      receiveAddress = generateNewAddress().address;
    } else {
      final previousAddressMatchesType =
          previousAddressRecord != null && previousAddressRecord!.addressType == addressPageType;

      if (previousAddressMatchesType &&
          typeMatchingReceiveAddresses.first.address != addressesByReceiveType.first.address) {
        receiveAddress = previousAddressRecord!.address;
      } else {
        receiveAddress = typeMatchingReceiveAddresses.first.address;
      }
    }

    return receiveAddress;
  }

  @observable
  bool isEnabledAutoGenerateSubaddress = true;

  @override
  set address(String addr) {
    try {
      final addressRecord = _allAddresses.firstWhere(
        (addressRecord) => addressRecord.address == addr,
      );

      previousAddressRecord = addressRecord;
    } catch (e) {
      print("ElectrumWalletAddressBase: set address ($addr): $e");
    }
  }

  @override
  String get primaryAddress => _allAddresses.first.address;

  @observable
  BitcoinAddressRecord? previousAddressRecord;

  @computed
  int get totalCountOfReceiveAddresses => addressesByReceiveType.fold(0, (acc, addressRecord) {
        if (!addressRecord.isChange) {
          return acc + 1;
        }
        return acc;
      });

  @computed
  int get totalCountOfChangeAddresses => addressesByReceiveType.fold(0, (acc, addressRecord) {
        if (addressRecord.isChange) {
          return acc + 1;
        }
        return acc;
      });

  @override
  Future<void> init() async {
    if (walletInfo.type == WalletType.bitcoinCash) {
      await generateInitialAddresses(addressType: P2pkhAddressType.p2pkh);
    } else if (walletInfo.type == WalletType.litecoin) {
      await generateInitialAddresses(addressType: SegwitAddresType.p2wpkh);
      if ((Platform.isAndroid || Platform.isIOS) && !isHardwareWallet) {
        await generateInitialAddresses(addressType: SegwitAddresType.mweb);
      }
    } else if (walletInfo.type == WalletType.bitcoin) {
      await generateInitialAddresses(addressType: SegwitAddresType.p2wpkh);
      if (!isHardwareWallet) {
        await generateInitialAddresses(addressType: P2pkhAddressType.p2pkh);
        await generateInitialAddresses(addressType: P2shAddressType.p2wpkhInP2sh);
        await generateInitialAddresses(addressType: SegwitAddresType.p2tr);
        await generateInitialAddresses(addressType: SegwitAddresType.p2wsh);
      }
    }

    updateAddressesByMatch();
    updateReceiveAddresses();
    updateChangeAddresses();
    await updateAddressesInBox();
  }

  @action
  Future<BitcoinAddressRecord> getChangeAddress({
    List<BitcoinUnspent>? inputs,
    List<BitcoinOutput>? outputs,
    bool isPegIn = false,
  }) async {
    updateChangeAddresses();

    final address = changeAddresses.firstWhere(
      // TODO: feature to choose change type
      (addressRecord) => _isUnusedChangeAddressByType(addressRecord, SegwitAddresType.p2wpkh),
    );
    return address;
  }

  @action
  BaseBitcoinAddressRecord generateNewAddress({String label = ''}) {
    final newAddressIndex = addressesByReceiveType.fold(
        0, (int acc, addressRecord) => addressRecord.isChange == false ? acc + 1 : acc);

    final derivationInfo = BitcoinAddressUtils.getDerivationFromType(addressPageType);
    final address = BitcoinAddressRecord(
      getAddress(
        derivationType: CWBitcoinDerivationType.bip39,
        isChange: false,
        index: newAddressIndex,
        addressType: addressPageType,
        derivationInfo: derivationInfo,
      ),
      index: newAddressIndex,
      isChange: false,
      name: label,
      addressType: addressPageType,
      network: network,
      derivationInfo: BitcoinAddressUtils.getDerivationFromType(addressPageType),
      derivationType: CWBitcoinDerivationType.bip39,
    );
    _allAddresses.add(address);
    Future.delayed(Duration.zero, () => updateAddressesByMatch());
    return address;
  }

  BitcoinBaseAddress generateAddress({
    required CWBitcoinDerivationType derivationType,
    required bool isChange,
    required int index,
    required BitcoinAddressType addressType,
    required BitcoinDerivationInfo derivationInfo,
  }) {
    throw UnimplementedError();
  }

  String getAddress({
    required CWBitcoinDerivationType derivationType,
    required bool isChange,
    required int index,
    required BitcoinAddressType addressType,
    required BitcoinDerivationInfo derivationInfo,
  }) {
    return generateAddress(
      derivationType: derivationType,
      isChange: isChange,
      index: index,
      addressType: addressType,
      derivationInfo: derivationInfo,
    ).toAddress(network);
  }

  Future<String> getAddressAsync({
    required CWBitcoinDerivationType derivationType,
    required bool isChange,
    required int index,
    required BitcoinAddressType addressType,
    required BitcoinDerivationInfo derivationInfo,
  }) async =>
      getAddress(
        derivationType: derivationType,
        isChange: isChange,
        index: index,
        addressType: addressType,
        derivationInfo: derivationInfo,
      );

  @action
  void addBitcoinAddressTypes() {
    final lastP2wpkh = _allAddresses
        .where((addressRecord) =>
            _isUnusedReceiveAddressByType(addressRecord, SegwitAddresType.p2wpkh))
        .toList()
        .last;
    if (lastP2wpkh.address != address) {
      addressesMap[lastP2wpkh.address] = 'P2WPKH' + ': ${lastP2wpkh.address}';
    } else {
      addressesMap[address] = 'Active - P2WPKH' + ': $address';
    }

    final lastP2pkh = _allAddresses.firstWhere(
        (addressRecord) => _isUnusedReceiveAddressByType(addressRecord, P2pkhAddressType.p2pkh));
    if (lastP2pkh.address != address) {
      addressesMap[lastP2pkh.address] = 'P2PKH' + ': ${lastP2pkh.address}';
    } else {
      addressesMap[address] = 'Active - P2PKH' + ': $address';
    }

    final lastP2sh = _allAddresses.firstWhere((addressRecord) =>
        _isUnusedReceiveAddressByType(addressRecord, P2shAddressType.p2wpkhInP2sh));
    if (lastP2sh.address != address) {
      addressesMap[lastP2sh.address] = 'P2SH' + ': ${lastP2sh.address}';
    } else {
      addressesMap[address] = 'Active - P2SH' + ': $address';
    }

    final lastP2tr = _allAddresses.firstWhere(
        (addressRecord) => _isUnusedReceiveAddressByType(addressRecord, SegwitAddresType.p2tr));
    if (lastP2tr.address != address) {
      addressesMap[lastP2tr.address] = 'P2TR' + ': ${lastP2tr.address}';
    } else {
      addressesMap[address] = 'Active - P2TR' + ': $address';
    }

    final lastP2wsh = _allAddresses.firstWhere(
        (addressRecord) => _isUnusedReceiveAddressByType(addressRecord, SegwitAddresType.p2wsh));
    if (lastP2wsh.address != address) {
      addressesMap[lastP2wsh.address] = 'P2WSH' + ': ${lastP2wsh.address}';
    } else {
      addressesMap[address] = 'Active - P2WSH' + ': $address';
    }
  }

  @action
  void addLitecoinAddressTypes() {
    final lastP2wpkh = _allAddresses
        .where((addressRecord) =>
            _isUnusedReceiveAddressByType(addressRecord, SegwitAddresType.p2wpkh))
        .toList()
        .last;
    if (lastP2wpkh.address != address) {
      addressesMap[lastP2wpkh.address] = 'P2WPKH' + ': ${lastP2wpkh.address}';
    } else {
      addressesMap[address] = 'Active - P2WPKH' + ': $address';
    }

    final lastMweb = _allAddresses.firstWhere(
        (addressRecord) => _isUnusedReceiveAddressByType(addressRecord, SegwitAddresType.mweb));
    if (lastMweb.address != address) {
      addressesMap[lastMweb.address] = 'MWEB' + ': ${lastMweb.address}';
    } else {
      addressesMap[address] = 'Active - MWEB' + ': $address';
    }
  }

  @action
  void addBitcoinCashAddressTypes() {
    final lastP2pkh = _allAddresses.firstWhere(
        (addressRecord) => _isUnusedReceiveAddressByType(addressRecord, P2pkhAddressType.p2pkh));
    if (lastP2pkh.address != address) {
      addressesMap[lastP2pkh.address] = 'P2PKH' + ': $address';
    } else {
      addressesMap[address] = 'Active - P2PKH' + ': $address';
    }
  }

  @override
  @action
  Future<void> updateAddressesInBox() async {
    try {
      addressesMap.clear();
      addressesMap[address] = 'Active - ' + addressPageType.toString() + ': $address';

      allAddressesMap.clear();
      _allAddresses.forEach((addressRecord) {
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
      print("updateAddresses $e");
    }
  }

  @action
  void updateAddress(String address, String label) {
    BaseBitcoinAddressRecord? foundAddress;
    _allAddresses.forEach((addressRecord) {
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
    }
  }

  @action
  void updateAddressesByMatch() {
    addressesByReceiveType.clear();
    addressesByReceiveType.addAll(_allAddresses.where(_isAddressPageTypeMatch).toList());
  }

  @action
  void updateReceiveAddresses() {
    receiveAddresses.removeRange(0, receiveAddresses.length);
    final newAddresses = _allAddresses.where((addressRecord) => !addressRecord.isChange);
    receiveAddresses.addAll(newAddresses);
  }

  @action
  void updateChangeAddresses() {
    changeAddresses.removeRange(0, changeAddresses.length);
    final newAddresses = _allAddresses.where((addressRecord) =>
        addressRecord.isChange &&
        (walletInfo.type != WalletType.bitcoin ||
            addressRecord.addressType == SegwitAddresType.p2wpkh));
    changeAddresses.addAll(newAddresses);
  }

  @action
  Future<List<BitcoinAddressRecord>> discoverNewAddresses({
    required CWBitcoinDerivationType derivationType,
    required bool isChange,
    required BitcoinAddressType addressType,
    required BitcoinDerivationInfo derivationInfo,
  }) async {
    final count = isChange
        ? ElectrumWalletAddressesBase.defaultChangeAddressesCount
        : ElectrumWalletAddressesBase.defaultReceiveAddressesCount;

    final startIndex = (isChange ? changeAddresses : receiveAddresses)
        .where((addr) => addr.derivationType == derivationType && addr.addressType == addressType)
        .length;

    final newAddresses = <BitcoinAddressRecord>[];

    for (var i = startIndex; i < count + startIndex; i++) {
      final address = BitcoinAddressRecord(
        await getAddressAsync(
          derivationType: derivationType,
          isChange: isChange,
          index: i,
          addressType: addressType,
          derivationInfo: derivationInfo,
        ),
        index: i,
        isChange: isChange,
        isHidden: OLD_DERIVATION_TYPES.contains(derivationType),
        addressType: addressType,
        network: network,
        derivationInfo: derivationInfo,
        derivationType: derivationType,
      );
      newAddresses.add(address);
    }

    addAddresses(newAddresses);
    return newAddresses;
  }

  @action
  Future<void> generateInitialAddresses({required BitcoinAddressType addressType}) async {
    if (_allAddresses.where((addr) => addr.addressType == addressType).isNotEmpty) {
      return;
    }

    for (final derivationType in hdWallets.keys) {
      // p2wpkh has always had the right derivations, skip if creating old derivations
      if (OLD_DERIVATION_TYPES.contains(derivationType) && addressType == SegwitAddresType.p2wpkh) {
        continue;
      }

      final isElectrum = derivationType == CWBitcoinDerivationType.electrum ||
          derivationType == CWBitcoinDerivationType.old_electrum;

      final derivationInfos = walletInfo.derivations?.where(
        (element) => element.scriptType == addressType.toString(),
      );

      if (derivationInfos == null || derivationInfos.isEmpty) {
        final bitcoinDerivationInfo = BitcoinDerivationInfo(
          derivationType: isElectrum ? BitcoinDerivationType.electrum : BitcoinDerivationType.bip39,
          derivationPath: walletInfo.derivationInfo!.derivationPath!,
          scriptType: addressType,
        );

        await discoverNewAddresses(
          derivationType: derivationType,
          isChange: false,
          addressType: addressType,
          derivationInfo: bitcoinDerivationInfo,
        );
        await discoverNewAddresses(
          derivationType: derivationType,
          isChange: true,
          addressType: addressType,
          derivationInfo: bitcoinDerivationInfo,
        );
        continue;
      }

      for (final derivationInfo in derivationInfos) {
        final bitcoinDerivationInfo = BitcoinDerivationInfo(
          derivationType: isElectrum ? BitcoinDerivationType.electrum : BitcoinDerivationType.bip39,
          derivationPath: derivationInfo.derivationPath!,
          scriptType: addressType,
        );

        await discoverNewAddresses(
          derivationType: derivationType,
          isChange: false,
          addressType: addressType,
          derivationInfo: bitcoinDerivationInfo,
        );
        await discoverNewAddresses(
          derivationType: derivationType,
          isChange: true,
          addressType: addressType,
          derivationInfo: bitcoinDerivationInfo,
        );
      }
    }
  }

  @action
  void updateAdresses(Iterable<BitcoinAddressRecord> addresses) {
    for (final address in addresses) {
      final index = _allAddresses.indexWhere((element) => element.address == address.address);
      _allAddresses.replaceRange(index, index + 1, [address]);

      updateAddressesByMatch();
      updateReceiveAddresses();
      updateChangeAddresses();
    }
  }

  @action
  void addAddresses(Iterable<BitcoinAddressRecord> addresses) {
    this._allAddresses.addAll(addresses);
    updateAddressesByMatch();
    updateReceiveAddresses();
    updateChangeAddresses();

    this.hiddenAddresses.addAll(addresses
        .where((addressRecord) => addressRecord.isHidden)
        .map((addressRecord) => addressRecord.address));
  }

  @action
  void updateHiddenAddresses() {
    this.hiddenAddresses.clear();
    this.hiddenAddresses.addAll(_allAddresses
        .where((addressRecord) => addressRecord.isHidden)
        .map((addressRecord) => addressRecord.address));
  }

  @action
  void addMwebAddresses(Iterable<BitcoinAddressRecord> addresses) {
    final addressesSet = this.mwebAddresses.toSet();
    addressesSet.addAll(addresses);
    this.mwebAddresses.clear();
    this.mwebAddresses.addAll(addressesSet);
    updateAddressesByMatch();
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

  bool _isAddressByType(BitcoinAddressRecord addr, BitcoinAddressType type) =>
      addr.addressType == type;

  bool _isUnusedChangeAddressByType(BitcoinAddressRecord addr, BitcoinAddressType type) {
    return addr.isChange && !addr.isUsed && addr.addressType == type;
  }

  bool _isUnusedReceiveAddressByType(BitcoinAddressRecord addr, BitcoinAddressType type) {
    return !addr.isChange && !addr.isUsed && addr.addressType == type;
  }

  Map<String, dynamic> toJson() {
    return {
      'allAddresses': _allAddresses.map((address) => address.toJSON()).toList(),
      'addressPageType': addressPageType.toString(),
    };
  }
}
