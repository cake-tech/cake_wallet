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
  ElectrumWalletAddressesBase(
    WalletInfo walletInfo, {
    required this.hdWallets,
    required this.network,
    required this.isHardwareWallet,
    List<BitcoinAddressRecord>? initialAddresses,
    Map<String, int>? initialRegularAddressIndex,
    Map<String, int>? initialChangeAddressIndex,
    BitcoinAddressType? initialAddressPageType,
    Map<BitcoinAddressType, Map<SeedBytesType, Map<String, List<BaseBitcoinAddressRecord>>>>
        initialReceiveAddressesMapped = const {},
    Map<BitcoinAddressType, Map<SeedBytesType, Map<String, List<BaseBitcoinAddressRecord>>>>
        initialChangeAddressesMapped = const {},
    Map<BitcoinAddressType, Map<SeedBytesType, Map<bool, bool>>> initialDiscoveredAddresses =
        const {},
  })  : _allAddresses = ObservableList.of(initialAddresses ?? []),
        currentReceiveAddressIndexByType = initialRegularAddressIndex ?? {},
        currentChangeAddressIndexByType = initialChangeAddressIndex ?? {},
        discoveredAddresses = initialDiscoveredAddresses,
        receiveAddressesMapped = initialReceiveAddressesMapped,
        changeAddressesMapped = initialChangeAddressesMapped,
        addressPageType = initialAddressPageType ??
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
  // { BitcoinAddressType: { SeedBytesType: { isChange: true = discovered } } }
  Map<BitcoinAddressType, Map<SeedBytesType, Map<bool, bool>>> discoveredAddresses;

  @observable
  // { BitcoinAddressType: { SeedBytesType: { derivationPath: [BaseBitcoinAddressRecord] } } }
  Map<BitcoinAddressType, Map<SeedBytesType, Map<String, List<BaseBitcoinAddressRecord>>>>
      receiveAddressesMapped;

  @observable
  // { BitcoinAddressType: { SeedBytesType: { derivationPath: [BaseBitcoinAddressRecord] } } }
  Map<BitcoinAddressType, Map<SeedBytesType, Map<String, List<BaseBitcoinAddressRecord>>>>
      changeAddressesMapped;

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

  @computed
  List<BitcoinAddressRecord> get allChangeAddresses =>
      _allAddresses.where((addr) => addr.isChange).toList();

  BitcoinDerivationInfo get _defaultAddressPageDerivationInfo =>
      BitcoinAddressUtils.getDerivationFromType(
        addressPageType,
        isElectrum: walletSeedBytesType.isElectrum,
      );

  @computed
  List<BaseBitcoinAddressRecord> get selectedReceiveAddresses {
    return receiveAddressesMapped[addressPageType]?[walletSeedBytesType]
            ?[_defaultAddressPageDerivationInfo.derivationPath.toString()] ??
        [];
  }

  @computed
  List<BaseBitcoinAddressRecord> get selectedChangeAddresses =>
      changeAddressesMapped[addressPageType]?[walletSeedBytesType]
          ?[_defaultAddressPageDerivationInfo.derivationPath.toString()] ??
      [];

  @computed
  List<BitcoinAddressRecord> get allAddresses => _allAddresses.toList();

  @computed
  Set<String> get allScriptHashes =>
      _allAddresses.map((addressRecord) => addressRecord.scriptHash).toSet();

  BitcoinAddressRecord getFromAddresses(String address) {
    return _allAddresses.firstWhere((element) => element.address == address);
  }

  // TODO: feature with toggle to switch change address type
  @observable
  BitcoinAddressType changeAddressType = SegwitAddressType.p2wpkh;

  @observable
  BitcoinAddressRecord? activeAddress;

  // TODO: map by type
  @observable
  int activeAddressIndex = 0;

  @override
  @action
  void resetActiveChangeAddress() {
    if (isEnabledAutoGenerateSubaddress) {
      try {
        activeAddress = _allAddresses.firstWhere(
          (addressRecord) =>
              addressRecord.type == addressPageType &&
              addressRecord.index == activeAddressIndex &&
              getIsReceive(addressRecord),
        );

        return;
      } catch (_) {}

      try {
        activeAddress = _allAddresses.firstWhere(
          (addressRecord) => addressRecord.type == addressPageType && getIsReceive(addressRecord),
        );
        return;
      } catch (_) {}
    }

    try {
      activeAddress = _allAddresses.firstWhere(
        (addressRecord) =>
            addressRecord.type == addressPageType &&
            addressRecord.index == activeAddressIndex &&
            !addressRecord.isChange &&
            !addressRecord.isHidden,
      );
    } catch (_) {}
  }

  @override
  @computed
  String get address {
    if (activeAddress != null) {
      return activeAddress!.address;
    }

    String? receiveAddress = "";

    if (isEnabledAutoGenerateSubaddress && selectedReceiveAddresses.isEmpty) {
      receiveAddress =
          selectedReceiveAddresses.firstWhereOrNull((addr) => !getIsUsed(addr))?.address;
    } else {
      receiveAddress = selectedReceiveAddresses.first.address;
    }

    return receiveAddress ?? '';
  }

  @observable
  bool isEnabledAutoGenerateSubaddress = true;

  @override
  set address(String addr) {
    try {
      final addressRecord = _allAddresses.firstWhere(
        (addressRecord) => addressRecord.address == addr,
      );

      activeAddress = addressRecord;

      if (getIsReceive(addressRecord)) {
        activeAddressIndex = addressRecord.index;
      }
    } catch (e) {
      // printV("ElectrumWalletAddressBase: set address ($addr): $e");
    }
  }

  @override
  String get primaryAddress => _allAddresses.first.address;

  Map<String, int> currentReceiveAddressIndexByType;

  int get currentReceiveAddressIndex =>
      currentReceiveAddressIndexByType[addressPageType.toString()] ?? 0;

  void set currentReceiveAddressIndex(int index) =>
      currentReceiveAddressIndexByType[addressPageType.toString()] = index;

  Map<String, int> currentChangeAddressIndexByType;

  int get currentChangeAddressIndex =>
      currentChangeAddressIndexByType[addressPageType.toString()] ?? 0;

  void set currentChangeAddressIndex(int index) =>
      currentChangeAddressIndexByType[addressPageType.toString()] = index;

  @override
  Future<void> init() async {
    await updateAddressesInBox();
  }

  Future<BaseBitcoinAddressRecord> getChangeAddress() async {
    final address = selectedChangeAddresses.firstWhere(
      (addr) => addr.isChange && !getIsUsed(addr) && addr.type == changeAddressType,
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
      derivationInfo: BitcoinAddressUtils.getDerivationFromType(addressPageType),
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
    this._allAddresses.addAll(addresses);

    final firstAddress = addresses.first;
    final addressesMap = {
      ...(firstAddress.isChange ? changeAddressesMapped : receiveAddressesMapped)
    };

    addressesMap.putIfAbsent(
      firstAddress.type,
      () => {
        firstAddress.seedBytesType!: {
          firstAddress.derivationInfo.derivationPath.toString(): addresses.toList(),
        },
      },
    );
    addressesMap[firstAddress.type]!.putIfAbsent(
      firstAddress.seedBytesType!,
      () => {
        firstAddress.derivationInfo.derivationPath.toString(): addresses.toList(),
      },
    );
    addressesMap[firstAddress.type]![firstAddress.seedBytesType]!.putIfAbsent(
      firstAddress.derivationInfo.derivationPath.toString(),
      () => addresses.toList(),
    );

    if (firstAddress.isChange) {
      changeAddressesMapped = addressesMap;
    } else {
      receiveAddressesMapped = addressesMap;
    }
  }

  @action
  Future<void> setAddressType(BitcoinAddressType type) async {
    addressPageType = type;
    walletInfo.addressPageType = addressPageType.toString();
    await walletInfo.save();
  }

  bool isUnusedReceiveAddress(BaseBitcoinAddressRecord addr) {
    return !addr.isChange && !getIsUsed(addr);
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['allAddresses'] = _allAddresses.map((address) => address.toJSON()).toList();
    json['addressPageType'] = addressPageType.toString();
    json['discoveredAddresses'] = discoveredAddresses.map((addressType, v) {
      return MapEntry(addressType.value, v.map((seedBytesType, v) {
        return MapEntry(seedBytesType.value, v.map((isChange, v) {
          return MapEntry(isChange.toString(), v);
        }));
      }));
    });

    json['receiveAddressesMapped'] = receiveAddressesMapped.map((addressType, v) {
      return MapEntry(addressType.value, v.map((seedBytesType, v) {
        return MapEntry(seedBytesType.value, v.map((derivationPath, v) {
          return MapEntry(
            derivationPath.toString(),
            v.map((address) => address.toJSON()).toList(),
          );
        }));
      }));
    });
    json['changeAddressesMapped'] = receiveAddressesMapped.map((addressType, v) {
      return MapEntry(addressType.value, v.map((seedBytesType, v) {
        return MapEntry(seedBytesType.value, v.map((derivationPath, v) {
          return MapEntry(
            derivationPath.toString(),
            v.map((address) => address.toJSON()).toList(),
          );
        }));
      }));
    });
    return json;
  }

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
      'discoveredAddresses': data['discoveredAddresses'] as Map<String, dynamic>? ?? {},
      'receiveAddressesMapped': data['receiveAddressesMapped'] as Map<String, dynamic>? ?? {},
      'changeAddressesMapped': data['changeAddressesMapped'] as Map<String, dynamic>? ?? {},
    };
  }

  static ElectrumWalletAddresses fromJson(
    Map<String, dynamic> json,
    WalletInfo walletInfo, {
    required Map<SeedBytesType, Bip32Slip10Secp256k1> hdWallets,
    required BasedUtxoNetwork network,
    required bool isHardwareWallet,
    List<BitcoinAddressRecord>? initialAddresses,
    List<BitcoinSilentPaymentAddressRecord>? initialSilentAddresses,
    List<BitcoinReceivedSPAddressRecord>? initialReceivedSPAddresses,
    Map<BitcoinAddressType, Map<SeedBytesType, Map<String, List<BaseBitcoinAddressRecord>>>>?
        initialReceiveAddressesMapped,
    Map<BitcoinAddressType, Map<SeedBytesType, Map<String, List<BaseBitcoinAddressRecord>>>>?
        initialChangeAddressesMapped,
    Map<BitcoinAddressType, Map<SeedBytesType, Map<bool, bool>>>? initialDiscoveredAddresses,
  }) {
    initialAddresses ??= (json['allAddresses'] as List)
        .map((record) => BitcoinAddressRecord.fromJSON(record as String))
        .toList();

    initialReceiveAddressesMapped ??= (json['receiveAddressesMapped'] as Map).map(
      (addressType, v) => MapEntry(
        BitcoinAddressType.fromValue(addressType as String),
        (v as Map).map(
          (seedBytesType, v) => MapEntry(
            SeedBytesType.fromValue(seedBytesType as String),
            (v as Map).map(
              (derivationPath, v) => MapEntry(
                derivationPath as String,
                (v as List)
                    .map((addr) => BaseBitcoinAddressRecord.fromJSON(addr as String))
                    .toList(),
              ),
            ),
          ),
        ),
      ),
    );
    initialChangeAddressesMapped ??= (json['changeAddressesMapped'] as Map).map(
      (addressType, v) => MapEntry(
        BitcoinAddressType.fromValue(addressType as String),
        (v as Map).map(
          (seedBytesType, v) => MapEntry(
            SeedBytesType.fromValue(seedBytesType as String),
            (v as Map).map(
              (derivationPath, v) => MapEntry(
                derivationPath as String,
                (v as List)
                    .map((addr) => BaseBitcoinAddressRecord.fromJSON(addr as String))
                    .toList(),
              ),
            ),
          ),
        ),
      ),
    );

    initialDiscoveredAddresses ??= ((json['discoveredAddresses'] as Map?) ?? {}).map(
      (addressType, v) => MapEntry(
        BitcoinAddressType.fromValue(addressType as String),
        (v as Map).map(
          (seedBytesType, v) => MapEntry(
            SeedBytesType.fromValue(seedBytesType as String),
            (v as Map).map(
              (isChange, v) => MapEntry(isChange == "true", v as bool),
            ),
          ),
        ),
      ),
    );

    return ElectrumWalletAddresses(
      walletInfo,
      hdWallets: hdWallets,
      network: network,
      isHardwareWallet: isHardwareWallet,
      initialAddresses: initialAddresses,
      initialDiscoveredAddresses: initialDiscoveredAddresses,
      initialReceiveAddressesMapped: initialReceiveAddressesMapped,
      initialChangeAddressesMapped: initialChangeAddressesMapped,
    );
  }

  bool getIsUsed(BaseBitcoinAddressRecord addr) {
    return addr.isUsed || addr.txCount != 0 || addr.balance != 0;
  }

  bool getIsReceive(BaseBitcoinAddressRecord addr) {
    return !getIsUsed(addr) && !addr.isChange && !addr.isHidden;
  }

  bool getShouldHideAddress(Bip32Path path, BitcoinAddressType addressType) {
    if (walletSeedBytesType.isElectrum) {
      return path.toString() != BitcoinDerivationInfos.ELECTRUM.derivationPath.toString();
    }

    return path.toString() !=
        BitcoinAddressUtils.getDerivationFromType(
          addressType,
        ).derivationPath.toString();
  }
}
