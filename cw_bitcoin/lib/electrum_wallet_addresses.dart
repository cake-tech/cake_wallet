import 'dart:collection';
import 'package:collection/collection.dart';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/seedbyte_types.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:mobx/mobx.dart';

part 'electrum_wallet_addresses.g.dart';

class ElectrumWalletAddresses = ElectrumWalletAddressesBase with _$ElectrumWalletAddresses;

abstract class ElectrumWalletAddressesBase extends WalletAddresses with Store {
  static const INITIAL_RECEIVE_COUNT = 22;
  static const INITIAL_CHANGE_COUNT = 17;
  static const GAP = 20;

  ElectrumWalletAddressesBase(
    WalletInfo walletInfo, {
    required this.hdWallets,
    required this.network,
    required this.isHardwareWallet,
    BitcoinAddressRecordMap? initialAddressesRecords,
    Map<BitcoinAddressType, int>? initialActiveAddressIndex,
    BitcoinDiscoveredAddressesMap? initialDiscoveredAddresses,
    BitcoinAddressType? initialAddressPageType,
  })  : addressesRecords = initialAddressesRecords ?? BitcoinAddressRecordMap(),
        activeIndexByType = initialActiveAddressIndex ?? {},
        discoveredAddresses = initialDiscoveredAddresses ?? BitcoinDiscoveredAddressesMap(),
        addressPageType = initialAddressPageType ??
            (walletInfo.addressPageType != null
                ? BitcoinAddressType.fromValue(walletInfo.addressPageType!)
                : SegwitAddressType.p2wpkh),
        super(walletInfo) {
    updateAllAddresses();
  }

  final walletAddressTypes = <BitcoinAddressType>[];

  @observable
  BitcoinDiscoveredAddressesMap discoveredAddresses;
  @observable
  BitcoinAddressRecordMap addressesRecords;

  @observable
  List<BitcoinAddressRecord> _allAddresses = [];
  @computed
  List<BitcoinAddressRecord> get allAddresses => _allAddresses;

  @action
  List<BitcoinAddressRecord> updateAllAddresses() {
    _allAddresses = addressesRecords.allRecords().whereType<BitcoinAddressRecord>().toList();

    updateAllScriptHashes();
    updateSelectedReceiveAddresses();
    updateSelectedChangeAddresses();
    return _allAddresses;
  }

  final BasedUtxoNetwork network;

  final Map<SeedBytesType, Bip32Slip10Secp256k1> hdWallets;

  Bip32Slip10Secp256k1 get hdWallet =>
      hdWallets[SeedBytesType.bip39] ?? hdWallets[SeedBytesType.electrum]!;

  String get xpub => hdWallet.publicKey.toExtended;

  SeedBytesType get walletSeedBytesType => hdWallets.containsKey(SeedBytesType.bip39)
      ? SeedBytesType.bip39
      : (hdWallets.containsKey(SeedBytesType.electrum)
          ? SeedBytesType.electrum
          : hdWallets.keys.first);

  final bool isHardwareWallet;

  @observable
  BitcoinAddressType addressPageType;

  @action
  Future<void> setAddressPageType(BitcoinAddressType type) async {
    addressPageType = type;

    updateSelectedReceiveAddresses();
    updateSelectedChangeAddresses();

    walletInfo.addressPageType = addressPageType.toString();
    await updateAddressesInBox();
  }

  @computed
  BitcoinDerivationInfo get _defaultAddressPageDerivationInfo =>
      BitcoinAddressUtils.getDerivationFromType(
        addressPageType,
        isElectrum: walletSeedBytesType.isElectrum,
      );

  @observable
  List<BaseBitcoinAddressRecord> _selectedReceiveAddresses = [];
  @computed
  List<BaseBitcoinAddressRecord> get selectedReceiveAddresses => _selectedReceiveAddresses;

  @action
  List<BaseBitcoinAddressRecord> updateSelectedReceiveAddresses() {
    _selectedReceiveAddresses = addressesRecords.getRecords(
      addressType: addressPageType,
      seedBytesType: walletSeedBytesType,
      derivationPath: _defaultAddressPageDerivationInfo.derivationPath.toString(),
      isChange: false,
    );
    updateNextReceiveAddress();
    return _selectedReceiveAddresses;
  }

  @observable
  BitcoinAddressRecord? _nextReceiveAddress;
  @computed
  BitcoinAddressRecord? get nextReceiveAddress => _nextReceiveAddress;

  @action
  BitcoinAddressRecord? updateNextReceiveAddress() {
    final receiveAddresses = selectedReceiveAddresses.whereType<BitcoinAddressRecord>();
    if (receiveAddresses.isEmpty) {
      return null;
    }

    _nextReceiveAddress = receiveAddresses.firstWhereOrNull(
          (addressRecord) =>
              addressRecord.getIsStillReceiveable(isEnabledAutoGenerateNewAddress) &&
              !addressRecord.isChange,
        ) ??
        receiveAddresses.first;
    return _nextReceiveAddress;
  }

  @observable
  List<BaseBitcoinAddressRecord> _selectedChangeAddresses = [];
  @computed
  List<BaseBitcoinAddressRecord> get selectedChangeAddresses => _selectedChangeAddresses;

  @action
  List<BaseBitcoinAddressRecord> updateSelectedChangeAddresses() {
    _selectedChangeAddresses = addressesRecords.getRecords(
      addressType: addressPageType,
      seedBytesType: walletSeedBytesType,
      derivationPath: _defaultAddressPageDerivationInfo.derivationPath.toString(),
      isChange: true,
    );
    updateNextChangeAddress();
    return _selectedChangeAddresses;
  }

  @observable
  BitcoinAddressRecord? _nextChangeAddress;
  @computed
  BitcoinAddressRecord? get nextChangeAddress => _nextChangeAddress;

  @action
  BitcoinAddressRecord? updateNextChangeAddress() {
    final changeAddresses = selectedChangeAddresses.whereType<BitcoinAddressRecord>();
    if (changeAddresses.isEmpty) {
      return null;
    }

    _nextChangeAddress = changeAddresses.firstWhereOrNull(
          (addressRecord) =>
              addressRecord.getIsStillReceiveable(isEnabledAutoGenerateNewAddress) &&
              addressRecord.isChange,
        ) ??
        changeAddresses.first;
    return _nextChangeAddress;
  }

  @observable
  List<String> _allScriptHashes = [];
  @computed
  List<String> get allScriptHashes => _allScriptHashes;

  @action
  List<String> updateAllScriptHashes() {
    _allScriptHashes.clear();
    _allScriptHashes.addAll(allAddresses.map((address) => address.scriptHash));
    return _allScriptHashes;
  }

  BaseBitcoinAddressRecord getFromAddresses(String address) =>
      allAddresses.firstWhere((element) => element.address == address);

  // TODO: feature with toggle to switch change address type
  @observable
  BitcoinAddressType changeAddressType = SegwitAddressType.p2wpkh;

  @observable
  BitcoinAddressRecord? activeBitcoinAddress;

  @observable
  bool isEnabledAutoGenerateNewAddress = true;

  @action
  void resetActiveAddress() {
    final activeReceiveAddresses = selectedReceiveAddresses.whereType<BitcoinAddressRecord>();

    activeBitcoinAddress = activeReceiveAddresses.firstWhereOrNull(
          (addressRecord) => addressRecord.index == activeIndexByType[addressPageType],
        ) ??
        activeReceiveAddresses.first;
  }

  @override
  @computed
  String get address {
    if (activeBitcoinAddress != null) {
      return activeBitcoinAddress!.address;
    }

    final receiveAddress = selectedReceiveAddresses
        .firstWhereOrNull(
          (addr) => addr.getIsStillReceiveable(isEnabledAutoGenerateNewAddress) && !addr.isChange,
        )
        ?.address;

    return receiveAddress ?? '';
  }

  @override
  set address(String addr) {
    final addressRecord = _allAddresses.firstWhereOrNull(
      (addressRecord) => addressRecord.address == addr,
    );

    activeBitcoinAddress = addressRecord;

    if (addressRecord != null &&
        addressRecord.getIsStillReceiveable(isEnabledAutoGenerateNewAddress) &&
        !addressRecord.isChange) {
      activeAddressIndex = addressRecord.index;
    }
  }

  @override
  @computed
  String get primaryAddress =>
      selectedReceiveAddresses
          .firstWhereOrNull(
            (addressRecord) =>
                addressRecord.getIsStillReceiveable(isEnabledAutoGenerateNewAddress) &&
                !addressRecord.isChange,
          )
          ?.address ??
      '';

  Map<BitcoinAddressType, int> activeIndexByType;

  int get activeAddressIndex => activeIndexByType[addressPageType] ?? 0;

  set activeAddressIndex(int index) => activeIndexByType[addressPageType] = index;

  @override
  Future<void> init() async {
    throw UnimplementedError();
  }

  Future<BaseBitcoinAddressRecord> getChangeAddress() async {
    final address = selectedChangeAddresses.firstWhere(
      (addr) => !addr.getIsUsed() && addr.type == changeAddressType,
    );
    return address;
  }

  BaseBitcoinAddressRecord generateNewAddress({String label = '', bool? isHidden}) {
    final newAddressIndex = selectedReceiveAddresses.fold(
      0,
      (int acc, addressRecord) => addressRecord.isChange == false ? acc + 1 : acc,
    );

    final derivationInfo = BitcoinAddressUtils.getDerivationFromType(addressPageType);
    final address = BitcoinAddressRecord(
      getAddress(
        derivationType: walletSeedBytesType,
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
      derivationInfo: derivationInfo,
      seedBytesType: walletSeedBytesType,
    );
    return address;
  }

  static BitcoinBaseAddress generateAddress({
    required SeedBytesType seedBytesType,
    required bool isChange,
    required int index,
    required BitcoinAddressType addressType,
    required BitcoinDerivationInfo derivationInfo,
    required String xpriv,
    required BasedUtxoNetwork network,
  }) {
    final hdWallet = Bip32Slip10Secp256k1.fromExtendedKey(
      xpriv,
      BitcoinAddressUtils.getKeyNetVersion(network),
    );

    switch (addressType) {
      case P2pkhAddressType.p2pkh:
        return P2pkhAddress.fromDerivation(
          bip32: hdWallet,
          derivationInfo: derivationInfo,
          isChange: isChange,
          index: index,
        );
      case SegwitAddressType.p2tr:
        return P2trAddress.fromDerivation(
          bip32: hdWallet,
          derivationInfo: derivationInfo,
          isChange: isChange,
          index: index,
        );
      case SegwitAddressType.p2wsh:
        return P2wshAddress.fromDerivation(
          bip32: hdWallet,
          derivationInfo: derivationInfo,
          isChange: isChange,
          index: index,
        );
      case P2shAddressType.p2wpkhInP2sh:
        return P2shAddress.fromDerivation(
          bip32: hdWallet,
          derivationInfo: derivationInfo,
          isChange: isChange,
          index: index,
          type: P2shAddressType.p2wpkhInP2sh,
        );
      case SegwitAddressType.p2wpkh:
        return P2wpkhAddress.fromDerivation(
          bip32: hdWallet,
          derivationInfo: derivationInfo,
          isChange: isChange,
          index: index,
        );
      default:
        throw ArgumentError('Invalid address type');
    }
  }

  String getAddress({
    required SeedBytesType derivationType,
    required bool isChange,
    required int index,
    required BitcoinAddressType addressType,
    required BitcoinDerivationInfo derivationInfo,
  }) {
    return generateAddress(
      seedBytesType: derivationType,
      isChange: isChange,
      index: index,
      addressType: addressType,
      derivationInfo: derivationInfo,
      xpriv: hdWallets[derivationType]!.privateKey.toExtended,
      network: network,
    ).toAddress(network);
  }

  Future<String> getAddressAsync({
    required SeedBytesType derivationType,
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

    await saveAddressesInBox();
  }

  @action
  void updateAddress(String address, String label) {
    BaseBitcoinAddressRecord? foundAddress;

    for (final addressRecord in _allAddresses) {
      if (addressRecord.address == address) {
        foundAddress = addressRecord;
        break;
      }
    }

    // TODO: verify this updates and keeps on re-open
    if (foundAddress != null) {
      foundAddress.setNewName(label);
    }
  }

  @action
  void updateAddresses(Iterable<BitcoinAddressRecord> newAddresses) {
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
    }
  }

  @action
  void addAddresses(Iterable<BitcoinAddressRecord> addresses) {
    final firstAddress = addresses.first;

    addressesRecords.addAddress(
      addressType: firstAddress.type,
      seedBytesType: firstAddress.seedBytesType!,
      derivationPath: firstAddress.derivationInfo.derivationPath.toString(),
      addressRecord: firstAddress,
    );
    updateAllAddresses();
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['addressesRecords'] = addressesRecords.toJson();
    json['discoveredAddresses'] = discoveredAddresses.toJson();
    json['addressPageType'] = addressPageType.toString();
    json['activeIndexByType'] = activeIndexByType.map(
      (key, value) => MapEntry(key.toString(), value),
    );
    return json;
  }

  static Map<String, dynamic> fromSnapshot(Map<dynamic, dynamic> data) {
    final addressesTmp = data['addresses'] as List? ?? <Object>[];
    final addresses = addressesTmp
        .whereType<String>()
        .map((addr) => BitcoinAddressRecord.fromJSON(addr))
        .toList();

    return {
      'allAddresses': addresses,
      'addressesRecords': data['addressesRecords'] as Map<String, dynamic>?,
      'discoveredAddresses': data['discoveredAddresses'] as Map<String, dynamic>?,
      'addressPageType': data['addressPageType'] as String?,
      'activeIndexByType': (data['activeIndexByType'] as Map<dynamic, dynamic>?) ?? {},
    };
  }

  static ElectrumWalletAddresses fromJson(
    Map<String, dynamic> json,
    WalletInfo walletInfo, {
    required Map<SeedBytesType, Bip32Slip10Secp256k1> hdWallets,
    required BasedUtxoNetwork network,
    required bool isHardwareWallet,
    List<BitcoinAddressRecord>? initialAddresses,
    BitcoinAddressRecordMap? initialAddressesRecords,
    BitcoinDiscoveredAddressesMap? initialDiscoveredAddresses,
  }) {
    // TODO: put this into records map (currently unused)
    if (json['allAddresses'] != null)
      initialAddresses ??= (json['allAddresses'] as List)
          .map((record) => BitcoinAddressRecord.fromJSON(record as String))
          .toList();

    if (json['addressesRecords'] != null)
      initialAddressesRecords ??= BitcoinAddressRecordMap.fromJson(
        json['addressesRecords'] as Map<String, dynamic>,
      );

    if (json['discoveredAddresses'] != null)
      initialDiscoveredAddresses ??= BitcoinDiscoveredAddressesMap.fromJson(
        json['discoveredAddresses'] as Map<String, dynamic>,
      );

    return ElectrumWalletAddresses(
      walletInfo,
      hdWallets: hdWallets,
      network: network,
      isHardwareWallet: isHardwareWallet,
      initialAddressesRecords: initialAddressesRecords,
      initialDiscoveredAddresses: initialDiscoveredAddresses,
      initialAddressPageType: json['addressPageType'] != null
          ? BitcoinAddressType.fromValue(json['addressPageType'] as String)
          : null,
      initialActiveAddressIndex: (json['activeIndexByType'] as Map<dynamic, dynamic>?)?.map(
        (key, value) => MapEntry(BitcoinAddressType.fromValue(key as String), value as int),
      ),
    );
  }
}

typedef AddressRecords = List<BaseBitcoinAddressRecord>;

typedef ItemsByIsChange<T> = Map<bool, T>;
typedef ItemsByDerivationPath<T> = Map<String, ItemsByIsChange<T>>;

// Maps by each different property with the final item being a list of addresses
typedef AddressRecordsBySeedType = Map<SeedBytesType, ItemsByDerivationPath<AddressRecords>>;

class ItemsRecordMap<T extends Map<SeedBytesType, ItemsByDerivationPath<dynamic>>>
    extends MapBase<BitcoinAddressType, T> {
  final Map<BitcoinAddressType, T> _data = {};

  @override
  T? operator [](Object? key) => _data[key];

  @override
  void operator []=(BitcoinAddressType key, T value) {
    _data[key] = value;
  }

  @override
  void clear() => _data.clear();

  @override
  Iterable<BitcoinAddressType> get keys => _data.keys;

  @override
  Iterable<T> get values => _data.values;

  @override
  T? remove(Object? key) => _data.remove(key);
}

class BitcoinAddressRecordMap extends ItemsRecordMap<AddressRecordsBySeedType> {
  void addAddress({
    required BitcoinAddressType addressType,
    required SeedBytesType seedBytesType,
    required String derivationPath,
    required BaseBitcoinAddressRecord addressRecord,
  }) {
    _data.putIfAbsent(
      addressType,
      () => {
        seedBytesType: {
          derivationPath: {addressRecord.isChange: []},
        },
      },
    );
    _data[addressType]!.putIfAbsent(
      seedBytesType,
      () => {
        derivationPath: {addressRecord.isChange: []},
      },
    );
    _data[addressType]![seedBytesType]!.putIfAbsent(
      derivationPath,
      () => {addressRecord.isChange: []},
    );
    _data[addressType]![seedBytesType]![derivationPath]!
        .putIfAbsent(addressRecord.isChange, () => []);

    _data[addressType]![seedBytesType]![derivationPath]![addressRecord.isChange]!
        .add(addressRecord);
  }

  List<BaseBitcoinAddressRecord> allRecords() {
    return _data.values
        .expand((seedTypeMap) => seedTypeMap.values)
        .expand((derivationMap) => derivationMap.values)
        .expand((changeMap) => changeMap.values)
        .fold<List<BaseBitcoinAddressRecord>>(
      [],
      (acc, records) => acc..addAll(records),
    );
  }

  List<BaseBitcoinAddressRecord> getRecords({
    required BitcoinAddressType addressType,
    required SeedBytesType seedBytesType,
    required String derivationPath,
    required bool isChange,
  }) {
    return _data[addressType]?[seedBytesType]?[derivationPath]?[isChange] ?? [];
  }

  Map<String, dynamic> toJson() => _data.map(
        (addressType, v) => MapEntry(
          addressType.value,
          v.map(
            (seedBytesType, v) => MapEntry(
              seedBytesType.value,
              v.map(
                (derivationPath, v) => MapEntry(
                  derivationPath.toString(),
                  v.map(
                    (isChange, v) => MapEntry(
                      isChange.toString(),
                      v.map((address) => address.toJSON()).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  static BitcoinAddressRecordMap fromJson(Map<String, dynamic> json) {
    final res = BitcoinAddressRecordMap();

    final mapped = json.map(
      (addressType, v) => MapEntry(
        BitcoinAddressType.fromValue(addressType),
        (v as Map<String, dynamic>).map(
          (seedBytesType, v) => MapEntry(
            SeedBytesType.fromValue(seedBytesType),
            (v as Map<String, dynamic>).map(
              (derivationPath, v) => MapEntry(
                derivationPath,
                (v as Map).map(
                  (isChange, v) => MapEntry(
                    isChange == 'true',
                    (v as List<dynamic>)
                        .map((address) => BaseBitcoinAddressRecord.fromJSON(address as String))
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    res.addAll(mapped);
    return res;
  }
}

// Maps by each different property with the final item being a boolean indicating addresses discovered
typedef DiscoveredAddressRecordsBySeedType = Map<SeedBytesType, ItemsByDerivationPath<bool>>;

class BitcoinDiscoveredAddressesMap extends ItemsRecordMap<DiscoveredAddressRecordsBySeedType> {
  void addDiscovered({
    required BitcoinAddressType addressType,
    required SeedBytesType seedBytesType,
    required String derivationPath,
    required BaseBitcoinAddressRecord addressRecord,
    required bool discovered,
  }) {
    _data.putIfAbsent(
      addressType,
      () => {
        seedBytesType: {
          derivationPath: {addressRecord.isChange: discovered},
        },
      },
    );
    _data[addressType]!.putIfAbsent(
      seedBytesType,
      () => {
        derivationPath: {addressRecord.isChange: discovered},
      },
    );
    _data[addressType]![seedBytesType]!.putIfAbsent(
      derivationPath,
      () => {addressRecord.isChange: discovered},
    );
    _data[addressType]![seedBytesType]![derivationPath]!
        .putIfAbsent(addressRecord.isChange, () => discovered);

    _data[addressType]![seedBytesType]![derivationPath]![addressRecord.isChange] = discovered;
  }

  bool getIsDiscovered({
    required BitcoinAddressType addressType,
    required SeedBytesType seedBytesType,
    required String derivationPath,
    required bool isChange,
  }) {
    return _data[addressType]?[seedBytesType]?[derivationPath]?[isChange] ?? false;
  }

  Map<String, dynamic> toJson() => _data.map(
        (addressType, v) => MapEntry(
          addressType.value,
          v.map(
            (seedBytesType, v) => MapEntry(
              seedBytesType.value,
              v.map(
                (derivationPath, v) => MapEntry(
                  derivationPath.toString(),
                  v.map(
                    (isChange, v) => MapEntry(isChange.toString(), v),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  static BitcoinDiscoveredAddressesMap fromJson(Map<String, dynamic> json) {
    final res = BitcoinDiscoveredAddressesMap();

    final mapped = json.map(
      (addressType, v) => MapEntry(
        BitcoinAddressType.fromValue(addressType),
        (v as Map<String, dynamic>).map(
          (seedBytesType, v) => MapEntry(
            SeedBytesType.fromValue(seedBytesType),
            (v as Map<String, dynamic>).map(
              (derivationPath, v) => MapEntry(
                derivationPath,
                (v as Map).map(
                  (isChange, v) => MapEntry(isChange == 'true', (v as bool)),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    res.addAll(mapped);
    return res;
  }
}
