import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_bitcoin/bitcoin_unspent.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
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
    BitcoinAddressType? initialAddressPageType,
  })  : _allAddresses = ObservableList.of(initialAddresses ?? []),
        addressesOnReceiveScreen =
            ObservableList<BaseBitcoinAddressRecord>.of((<BitcoinAddressRecord>[]).toSet()),
        receiveAddresses = ObservableList<BitcoinAddressRecord>.of(
            (initialAddresses ?? []).where((addressRecord) => !addressRecord.isChange).toSet()),
        changeAddresses = ObservableList<BitcoinAddressRecord>.of(
            (initialAddresses ?? []).where((addressRecord) => addressRecord.isChange).toSet()),
        _addressPageType = initialAddressPageType ??
            (walletInfo.addressPageType != null
                ? BitcoinAddressType.fromValue(walletInfo.addressPageType!)
                : SegwitAddressType.p2wpkh),
        super(walletInfo) {
    updateAddressesOnReceiveScreen();
  }

  static const defaultReceiveAddressesCount = 22;
  static const defaultChangeAddressesCount = 17;
  static const gap = 20;

  final ObservableList<BitcoinAddressRecord> _allAddresses;
  final ObservableList<BaseBitcoinAddressRecord> addressesOnReceiveScreen;
  final ObservableList<BitcoinAddressRecord> receiveAddresses;
  final ObservableList<BitcoinAddressRecord> changeAddresses;
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

  @observable
  BitcoinAddressType changeAddressType = SegwitAddressType.p2wpkh;

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
          previousAddressRecord != null && previousAddressRecord!.type == addressPageType;

      if (previousAddressMatchesType &&
          typeMatchingReceiveAddresses.first.address != addressesOnReceiveScreen.first.address) {
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
      printV("ElectrumWalletAddressBase: set address ($addr): $e");
    }
  }

  @override
  String get primaryAddress => _allAddresses.first.address;

  @observable
  BitcoinAddressRecord? previousAddressRecord;

  @computed
  int get totalCountOfReceiveAddresses => addressesOnReceiveScreen.fold(0, (acc, addressRecord) {
        if (!addressRecord.isChange) {
          return acc + 1;
        }
        return acc;
      });

  @computed
  int get totalCountOfChangeAddresses => addressesOnReceiveScreen.fold(0, (acc, addressRecord) {
        if (addressRecord.isChange) {
          return acc + 1;
        }
        return acc;
      });

  CWBitcoinDerivationType getHDWalletType() {
    if (hdWallets.containsKey(CWBitcoinDerivationType.bip39)) {
      return CWBitcoinDerivationType.bip39;
    } else if (hdWallets.containsKey(CWBitcoinDerivationType.electrum)) {
      return CWBitcoinDerivationType.electrum;
    } else {
      return hdWallets.keys.first;
    }
  }

  @override
  Future<void> init() async {
    updateAddressesOnReceiveScreen();
    updateReceiveAddresses();
    updateChangeAddresses();
    await updateAddressesInBox();
  }

  @action
  Future<BaseBitcoinAddressRecord> getChangeAddress({
    List<BitcoinUnspent>? inputs,
    List<BitcoinOutput>? outputs,
    bool isPegIn = false,
  }) async {
    updateChangeAddresses();

    final address = changeAddresses.firstWhere(
      (addressRecord) => _isUnusedChangeAddressByType(addressRecord, changeAddressType),
    );
    return address;
  }

  @action
  BaseBitcoinAddressRecord generateNewAddress({String label = ''}) {
    final newAddressIndex = addressesOnReceiveScreen.fold(
      0,
      (int acc, addressRecord) => addressRecord.isChange == false ? acc + 1 : acc,
    );

    final derivationInfo = BitcoinAddressUtils.getDerivationFromType(addressPageType);
    final address = BitcoinAddressRecord(
      getAddress(
        derivationType: getHDWalletType(),
        isChange: false,
        index: newAddressIndex,
        addressType: addressPageType,
        derivationInfo: derivationInfo,
      ),
      index: newAddressIndex,
      isChange: false,
      name: label,
      type: addressPageType,
      network: network,
      derivationInfo: BitcoinAddressUtils.getDerivationFromType(addressPageType),
      cwDerivationType: getHDWalletType(),
    );
    addAddresses([address]);
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

  @override
  @action
  Future<void> updateAddressesInBox() async {
    addressesMap.clear();
    addressesMap[address] = 'Active - ' + addressPageType.toString() + ': $address';

    allAddressesMap.clear();
    _allAddresses.forEach((addressRecord) {
      allAddressesMap[addressRecord.address] = addressRecord.name;
    });
  }

  @action
  void updateAddress(String address, String label) {
    BaseBitcoinAddressRecord? foundAddress;
    _allAddresses.forEach((addressRecord) {
      if (addressRecord.address == address) {
        foundAddress = addressRecord;
      }
    });

    if (foundAddress != null) {
      foundAddress!.setNewName(label);
    }
  }

  @action
  void updateAddressesOnReceiveScreen() {
    addressesOnReceiveScreen.clear();
    addressesOnReceiveScreen.addAll(_allAddresses.where(_isAddressPageTypeMatch).toList());
  }

  @action
  void updateReceiveAddresses() {
    receiveAddresses.clear();
    receiveAddresses.addAll(_allAddresses.where((addressRecord) => !addressRecord.isChange));
  }

  @action
  void updateChangeAddresses() {
    changeAddresses.clear();
    changeAddresses.addAll(_allAddresses.where((addressRecord) => addressRecord.isChange));
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
        .where((addr) => addr.cwDerivationType == derivationType && addr.type == addressType)
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
        isHidden: OLD_DERIVATION_TYPES.contains(derivationType) || isChange,
        type: addressType,
        network: network,
        derivationInfo: derivationInfo,
        cwDerivationType: derivationType,
      );
      newAddresses.add(address);
    }

    return newAddresses;
  }

  @action
  Future<void> generateInitialAddresses({required BitcoinAddressType type}) async {
    for (final derivationType in hdWallets.keys) {
      // p2wpkh has always had the right derivations, skip if creating old derivations
      if (OLD_DERIVATION_TYPES.contains(derivationType) && type == SegwitAddressType.p2wpkh) {
        continue;
      }

      final isElectrum = derivationType == CWBitcoinDerivationType.electrum ||
          derivationType == CWBitcoinDerivationType.old_electrum;

      final derivationInfos = walletInfo.derivations?.where(
        (element) => element.scriptType == type.toString(),
      );

      if (derivationInfos == null || derivationInfos.isEmpty) {
        final bitcoinDerivationInfo = BitcoinDerivationInfo(
          derivationType: isElectrum ? BitcoinDerivationType.electrum : BitcoinDerivationType.bip39,
          derivationPath: walletInfo.derivationInfo!.derivationPath!,
          scriptType: type,
        );

        final newReceiveAddresses = await discoverNewAddresses(
          derivationType: derivationType,
          isChange: false,
          addressType: type,
          derivationInfo: bitcoinDerivationInfo,
        );
        updateAdresses(newReceiveAddresses);

        final newChangeAddresses = await discoverNewAddresses(
          derivationType: derivationType,
          isChange: true,
          addressType: type,
          derivationInfo: bitcoinDerivationInfo,
        );
        updateAdresses(newChangeAddresses);

        continue;
      }

      for (final derivationInfo in derivationInfos) {
        final bitcoinDerivationInfo = BitcoinDerivationInfo(
          derivationType: isElectrum ? BitcoinDerivationType.electrum : BitcoinDerivationType.bip39,
          derivationPath: derivationInfo.derivationPath!,
          scriptType: type,
        );

        final newReceiveAddresses = await discoverNewAddresses(
          derivationType: derivationType,
          isChange: false,
          addressType: type,
          derivationInfo: bitcoinDerivationInfo,
        );
        updateAdresses(newReceiveAddresses);

        final newChangeAddresses = await discoverNewAddresses(
          derivationType: derivationType,
          isChange: true,
          addressType: type,
          derivationInfo: bitcoinDerivationInfo,
        );
        updateAdresses(newChangeAddresses);
      }
    }
  }

  @action
  void updateAdresses(Iterable<BitcoinAddressRecord> newAddresses) {
    final replacedAddresses = newAddresses.toList();
    for (final address in newAddresses) {
      final index = _allAddresses.indexWhere((element) => element.address == address.address);
      if (index >= 0) {
        _allAddresses.replaceRange(index, index + 1, [address]);
        replacedAddresses.remove(address);
      }
    }

    if (replacedAddresses.isNotEmpty) {
      _allAddresses.addAll(replacedAddresses);
    } else {
      updateAddressesOnReceiveScreen();
      updateReceiveAddresses();
      updateChangeAddresses();
    }
  }

  @action
  void addAddresses(Iterable<BitcoinAddressRecord> addresses) {
    this._allAddresses.addAll(addresses);

    updateHiddenAddresses();
    updateAddressesOnReceiveScreen();
    updateReceiveAddresses();
    updateChangeAddresses();
  }

  @action
  void updateHiddenAddresses() {
    this.hiddenAddresses.clear();
    this.hiddenAddresses.addAll(_allAddresses
        .where((addressRecord) => addressRecord.isHidden)
        .map((addressRecord) => addressRecord.address));
  }

  @action
  Future<void> setAddressType(BitcoinAddressType type) async {
    _addressPageType = type;
    updateAddressesOnReceiveScreen();
    walletInfo.addressPageType = addressPageType.toString();
    await walletInfo.save();
  }

  bool _isAddressPageTypeMatch(BitcoinAddressRecord addressRecord) {
    return _isAddressByType(addressRecord, addressPageType);
  }

  bool _isAddressByType(BitcoinAddressRecord addr, BitcoinAddressType type) => addr.type == type;

  bool _isUnusedChangeAddressByType(BitcoinAddressRecord addr, BitcoinAddressType type) {
    return addr.isChange && !addr.isUsed && addr.type == type;
  }

  bool isUnusedReceiveAddress(BaseBitcoinAddressRecord addr) {
    return !addr.isChange && !addr.isUsed;
  }

  bool isUnusedReceiveAddressByType(BaseBitcoinAddressRecord addr, BitcoinAddressType type) {
    return isUnusedReceiveAddress(addr) && addr.type == type;
  }

  Map<String, dynamic> toJson() {
    return {
      'allAddresses': _allAddresses.map((address) => address.toJSON()).toList(),
      'addressPageType': addressPageType.toString(),
    };
  }
}
