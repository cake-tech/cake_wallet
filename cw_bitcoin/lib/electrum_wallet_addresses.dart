import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_core/utils/print_verbose.dart';
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
    Map<String, int>? initialRegularAddressIndex,
    Map<String, int>? initialChangeAddressIndex,
    BitcoinAddressType? initialAddressPageType,
  })  : _allAddresses = ObservableList.of(initialAddresses ?? []),
        currentReceiveAddressIndexByType = initialRegularAddressIndex ?? {},
        currentChangeAddressIndexByType = initialChangeAddressIndex ?? {},
        _addressPageType = initialAddressPageType ??
            (walletInfo.addressPageType != null
                ? BitcoinAddressType.fromValue(walletInfo.addressPageType!)
                : SegwitAddressType.p2wpkh),
        super(walletInfo);

  static const defaultReceiveAddressesCount = 22;
  static const defaultChangeAddressesCount = 17;
  static const gap = 20;

  final walletAddressTypes = <BitcoinAddressType>[];

  final ObservableList<BitcoinAddressRecord> _allAddresses;
  @observable
  Map<BitcoinAddressType, List<BaseBitcoinAddressRecord>> receiveAddressesByType = {};
  @observable
  Map<BitcoinAddressType, List<BaseBitcoinAddressRecord>> changeAddressesByType = {};

  final BasedUtxoNetwork network;

  final Map<CWBitcoinDerivationType, Bip32Slip10Secp256k1> hdWallets;
  Bip32Slip10Secp256k1 get hdWallet =>
      hdWallets[CWBitcoinDerivationType.bip39] ?? hdWallets[CWBitcoinDerivationType.electrum]!;

  final bool isHardwareWallet;

  @observable
  late BitcoinAddressType _addressPageType;

  @computed
  List<BitcoinAddressRecord> get allChangeAddresses =>
      _allAddresses.where((addr) => addr.isChange).toList();

  @computed
  List<BaseBitcoinAddressRecord> get selectedReceiveAddresses =>
      receiveAddressesByType[_addressPageType]!;

  @computed
  List<BaseBitcoinAddressRecord> get selectedChangeAddresses =>
      receiveAddressesByType[_addressPageType]!;

  List<BaseBitcoinAddressRecord> getAddressesByType(
    BitcoinAddressType type, [
    bool isChange = false,
  ]) =>
      isChange ? changeAddressesByType[type]! : receiveAddressesByType[type]!;

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

  // TODO: toggle to switch
  @observable
  BitcoinAddressType changeAddressType = SegwitAddressType.p2wpkh;

  @override
  @computed
  String get address {
    String receiveAddress = "";

    final typeMatchingReceiveAddresses = selectedReceiveAddresses.where(
      (addressRecord) => !addressRecord.isUsed,
    );

    if ((isEnabledAutoGenerateSubaddress && selectedReceiveAddresses.isEmpty) ||
        typeMatchingReceiveAddresses.isEmpty) {
      receiveAddress = generateNewAddress().address;
    } else {
      final previousAddressMatchesType =
          previousAddressRecord != null && previousAddressRecord!.type == addressPageType;

      if (typeMatchingReceiveAddresses.isNotEmpty) {
        if (previousAddressMatchesType &&
            typeMatchingReceiveAddresses.first.address != selectedReceiveAddresses.first.address) {
          receiveAddress = previousAddressRecord!.address;
        } else {
          receiveAddress = typeMatchingReceiveAddresses.first.address;
        }
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

  Map<String, int> currentReceiveAddressIndexByType;

  int get currentReceiveAddressIndex =>
      currentReceiveAddressIndexByType[_addressPageType.toString()] ?? 0;

  void set currentReceiveAddressIndex(int index) =>
      currentReceiveAddressIndexByType[_addressPageType.toString()] = index;

  Map<String, int> currentChangeAddressIndexByType;

  int get currentChangeAddressIndex =>
      currentChangeAddressIndexByType[_addressPageType.toString()] ?? 0;

  void set currentChangeAddressIndex(int index) =>
      currentChangeAddressIndexByType[_addressPageType.toString()] = index;

  @observable
  BitcoinAddressRecord? previousAddressRecord;

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
    updateAddressesByType();
    updateHiddenAddresses();
    await updateAddressesInBox();
  }

  @action
  Future<BaseBitcoinAddressRecord> getChangeAddress() async {
    final address = selectedChangeAddresses.firstWhere(
      (addr) => _isUnusedChangeAddressByType(addr, changeAddressType),
    );
    return address;
  }

  BaseBitcoinAddressRecord generateNewAddress({String label = ''}) {
    final newAddressIndex = selectedReceiveAddresses.fold(
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
  void updateAddressesByType() {
    receiveAddressesByType.clear();
    walletAddressTypes.forEach((type) {
      receiveAddressesByType[type] =
          _allAddresses.where((addr) => _isAddressByType(addr, type)).toList();
      changeAddressesByType[type] =
          _allAddresses.where((addr) => _isAddressByType(addr, type)).toList();
    });
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

    final startIndex = (isChange ? selectedChangeAddresses : selectedReceiveAddresses)
        .where((addr) =>
            (addr as BitcoinAddressRecord).cwDerivationType == derivationType &&
            addr.type == addressType)
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
      updateAddressesByType();
    }
  }

  @action
  void addAddresses(Iterable<BitcoinAddressRecord> addresses) {
    this._allAddresses.addAll(addresses);

    updateHiddenAddresses();
    updateAddressesByType();
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
    updateAddressesByType();
    walletInfo.addressPageType = addressPageType.toString();
    await walletInfo.save();
  }

  bool _isAddressByType(BitcoinAddressRecord addr, BitcoinAddressType type) => addr.type == type;

  bool _isUnusedChangeAddressByType(BaseBitcoinAddressRecord addr, BitcoinAddressType type) {
    return addr.isChange && !addr.isUsed && addr.type == type;
  }

  bool isUnusedReceiveAddress(BaseBitcoinAddressRecord addr) {
    return !addr.isChange && !addr.isUsed;
  }

  bool isUnusedReceiveAddressByType(BaseBitcoinAddressRecord addr, BitcoinAddressType type) {
    return isUnusedReceiveAddress(addr) && addr.type == type;
  }

  Map<String, dynamic> toJson() => {
        'allAddresses': _allAddresses.map((address) => address.toJSON()).toList(),
        'addressPageType': addressPageType.toString(),
        // 'receiveAddressIndexByType': receiveAddressIndexByType,
        // 'changeAddressIndexByType': changeAddressIndexByType,
      };

  static Map<String, dynamic> fromSnapshot(Map<dynamic, dynamic> data) {
    final addressesTmp = data['addresses'] as List? ?? <Object>[];
    final addresses = addressesTmp
        .whereType<String>()
        .map((addr) => BitcoinAddressRecord.fromJSON(addr))
        .toList();

    var receiveAddressIndexByType = {SegwitAddressType.p2wpkh.toString(): 0};
    var changeAddressIndexByType = {SegwitAddressType.p2wpkh.toString(): 0};

    try {
      receiveAddressIndexByType = {
        SegwitAddressType.p2wpkh.toString(): int.parse(data['account_index'] as String? ?? '0')
      };
      changeAddressIndexByType = {
        SegwitAddressType.p2wpkh.toString():
            int.parse(data['change_address_index'] as String? ?? '0')
      };
    } catch (_) {
      try {
        receiveAddressIndexByType = data["account_index"] as Map<String, int>? ?? {};
        changeAddressIndexByType = data["change_address_index"] as Map<String, int>? ?? {};
      } catch (_) {}
    }

    return {
      'allAddresses': addresses,
      'addressPageType': data['address_page_type'] as String?,
      'receiveAddressIndexByType': receiveAddressIndexByType,
      'changeAddressIndexByType': changeAddressIndexByType,
    };
  }

  static ElectrumWalletAddressesBase fromJson(
    Map<String, dynamic> json,
    WalletInfo walletInfo, {
    required Map<CWBitcoinDerivationType, Bip32Slip10Secp256k1> hdWallets,
    required BasedUtxoNetwork network,
    required bool isHardwareWallet,
    List<BitcoinAddressRecord>? initialAddresses,
    List<BitcoinSilentPaymentAddressRecord>? initialSilentAddresses,
    List<BitcoinReceivedSPAddressRecord>? initialReceivedSPAddresses,
  }) {
    initialAddresses ??= (json['allAddresses'] as List)
        .map((record) => BitcoinAddressRecord.fromJSON(record as String))
        .toList();

    return ElectrumWalletAddresses(
      walletInfo,
      hdWallets: hdWallets,
      network: network,
      isHardwareWallet: isHardwareWallet,
      initialAddresses: initialAddresses,
    );
  }
}
