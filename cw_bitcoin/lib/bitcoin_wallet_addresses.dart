import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/seedbyte_types.dart';
import 'package:cw_bitcoin/electrum_wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:mobx/mobx.dart';

part 'bitcoin_wallet_addresses.g.dart';

class BitcoinWalletAddresses = BitcoinWalletAddressesBase with _$BitcoinWalletAddresses;

const OLD_DERIVATION_TYPES = [SeedBytesType.old_electrum, SeedBytesType.old_bip39];

abstract class BitcoinWalletAddressesBase extends ElectrumWalletAddresses with Store {
  BitcoinWalletAddressesBase(
    WalletInfo walletInfo, {
    required super.hdWallets,
    required super.network,
    required super.isHardwareWallet,
    super.initialAddresses,
    this.loadedFromNewSnapshot = false,
    List<BitcoinSilentPaymentAddressRecord>? initialSilentAddresses,
    List<BitcoinReceivedSPAddressRecord>? initialReceivedSPAddresses,
  })  : silentPaymentAddresses = ObservableList<BitcoinSilentPaymentAddressRecord>.of(
          (initialSilentAddresses ?? []).toSet(),
        ),
        receivedSPAddresses = ObservableList<BitcoinReceivedSPAddressRecord>.of(
          (initialReceivedSPAddresses ?? []).toSet(),
        ),
        super(walletInfo) {
    silentPaymentWallet = SilentPaymentOwner.fromBip32(hdWallet);
    silentPaymentWallets = [silentPaymentWallet!];
  }

  final bool loadedFromNewSnapshot;

  static const OLD_SP_PATH = "m/352'/1'/0'/#'/0";

  @override
  final walletAddressTypes = BITCOIN_ADDRESS_TYPES;

  static const BITCOIN_ADDRESS_TYPES = [
    SegwitAddressType.p2wpkh,
    P2pkhAddressType.p2pkh,
    SegwitAddressType.p2tr,
    SegwitAddressType.p2wsh,
    P2shAddressType.p2wpkhInP2sh,
  ];

  @observable
  SilentPaymentOwner? silentPaymentWallet;
  final ObservableList<BitcoinSilentPaymentAddressRecord> silentPaymentAddresses;
  final ObservableList<BitcoinReceivedSPAddressRecord> receivedSPAddresses;

  @observable
  List<SilentPaymentOwner> silentPaymentWallets = [];

  @observable
  BitcoinSilentPaymentAddressRecord? activeSilentAddress;

  @observable
  String? scanningSilentAddress;

  @observable
  int silentAddressIndex = 0;

  @override
  Future<void> init() async {
    // If already loaded, no need to generate/discover all initial addresses
    // so skip
    if (!loadedFromNewSnapshot) {
      for (final seedBytesType in hdWallets.keys) {
        await generateInitialAddresses(
          addressType: SegwitAddressType.p2wpkh,
          seedBytesType: seedBytesType,
        );

        if (!isHardwareWallet) {
          await generateInitialAddresses(
            addressType: P2pkhAddressType.p2pkh,
            seedBytesType: seedBytesType,
          );

          await generateInitialAddresses(
            addressType: P2shAddressType.p2wpkhInP2sh,
            seedBytesType: seedBytesType,
          );

          await generateInitialAddresses(
            addressType: SegwitAddressType.p2tr,
            seedBytesType: seedBytesType,
          );

          await generateInitialAddresses(
            addressType: SegwitAddressType.p2wsh,
            seedBytesType: seedBytesType,
          );
        }
      }

      if (silentPaymentAddresses.isEmpty) {
        generateInitialSPAddresses();
      }

      super.init();
    }
  }

  @action
  Future<void> generateInitialSPAddresses() async {
    // Only initiate these old addresses if restoring a wallet and possibly wants the older cake derivation path
    if (walletInfo.isRecovery) {
      final oldScanPath = Bip32PathParser.parse(OLD_SP_PATH.replaceFirst("#", "1"));
      final oldSpendPath = Bip32PathParser.parse(OLD_SP_PATH.replaceFirst("#", "0"));

      final oldSilentPaymentWallet = SilentPaymentOwner.fromPrivateKeys(
        b_scan: ECPrivate(hdWallet.derive(oldScanPath).privateKey),
        b_spend: ECPrivate(hdWallet.derive(oldSpendPath).privateKey),
      );

      silentPaymentWallets.add(oldSilentPaymentWallet);
      silentPaymentAddresses.addAll(
        [
          BitcoinSilentPaymentAddressRecord(
            oldSilentPaymentWallet.toString(),
            labelIndex: 0,
            name: "",
            type: SilentPaymentsAddresType.p2sp,
            derivationPath: oldSpendPath.toString(),
            isHidden: true,
            isChange: false,
          ),
          BitcoinSilentPaymentAddressRecord(
            oldSilentPaymentWallet.toLabeledSilentPaymentAddress(0).toString(),
            name: "",
            labelIndex: 0,
            labelHex: BytesUtils.toHexString(oldSilentPaymentWallet.generateLabel(0)),
            type: SilentPaymentsAddresType.p2sp,
            derivationPath: oldSpendPath.toString(),
            isHidden: true,
            isChange: true,
          ),
        ],
      );
    }

    silentPaymentAddresses.addAll([
      BitcoinSilentPaymentAddressRecord(
        silentPaymentWallet!.toString(),
        labelIndex: 0,
        name: "",
        type: SilentPaymentsAddresType.p2sp,
        isChange: false,
      ),
      BitcoinSilentPaymentAddressRecord(
        silentPaymentWallet!.toLabeledSilentPaymentAddress(0).toString(),
        name: "",
        labelIndex: 0,
        labelHex: BytesUtils.toHexString(silentPaymentWallet!.generateLabel(0)),
        type: SilentPaymentsAddresType.p2sp,
        isChange: true,
      ),
    ]);
  }

  @override
  @action
  Future<void> generateInitialAddresses({
    required BitcoinAddressType addressType,
    required SeedBytesType seedBytesType,
    BitcoinDerivationInfo? bitcoinDerivationInfo,
  }) async {
    final isOldRestoration = OLD_DERIVATION_TYPES.contains(seedBytesType);

    // p2wpkh has always had the right derivations, skip if creating old derivations
    if (isOldRestoration && addressType == SegwitAddressType.p2wpkh) {
      return;
    }

    final bitcoinDerivationInfo = BitcoinAddressUtils.getDerivationFromType(
      addressType,
      isElectrum: seedBytesType.isElectrum,
    );

    if (isOldRestoration) {
      for (final derivationInfo in [
        BitcoinDerivationInfos.ELECTRUM,
        BitcoinDerivationInfos.BIP84
      ]) {
        if (derivationInfo.derivationPath.toString() ==
            bitcoinDerivationInfo.derivationPath.toString()) {
          continue;
        }

        await super.generateInitialAddresses(
          addressType: addressType,
          seedBytesType: seedBytesType,
          bitcoinDerivationInfo: derivationInfo,
        );
      }
    } else {
      await super.generateInitialAddresses(
        addressType: addressType,
        seedBytesType: seedBytesType,
        bitcoinDerivationInfo: bitcoinDerivationInfo,
      );
    }
  }

  @override
  @action
  void resetActiveChangeAddress() {
    if (activeSilentAddress != null &&
        (activeSilentAddress!.isChange || activeSilentAddress!.isHidden)) {
      try {
        activeSilentAddress = silentPaymentAddresses.firstWhere(
          (addressRecord) =>
              addressRecord.labelIndex == silentAddressIndex &&
              !addressRecord.isChange &&
              !addressRecord.isHidden,
        );

        return;
      } catch (_) {}
    }

    super.resetActiveChangeAddress();
  }

  @override
  @computed
  String get address {
    if (addressPageType == SilentPaymentsAddresType.p2sp) {
      if (activeSilentAddress != null) {
        return activeSilentAddress!.address;
      }

      return silentPaymentWallet.toString();
    }

    return super.address;
  }

  @override
  set address(String addr) {
    if (addressPageType == SilentPaymentsAddresType.p2sp) {
      final selected = silentPaymentAddresses
              .firstWhereOrNull((addressRecord) => addressRecord.address == addr) ??
          silentPaymentAddresses[0];

      activeSilentAddress = selected;

      if (!selected.isChange) {
        silentAddressIndex = selected.labelIndex;
      }

      return;
    }

    super.address = addr;
  }

  @override
  @action
  BaseBitcoinAddressRecord generateNewAddress({String label = '', bool? isHidden}) {
    if (addressPageType == SilentPaymentsAddresType.p2sp) {
      return generateNewSPAddress(label: label, isHidden: isHidden);
    }

    return super.generateNewAddress(label: label);
  }

  @action
  BaseBitcoinAddressRecord generateNewSPAddress({String label = '', bool? isHidden}) {
    isHidden ??= false;

    final existingSilentPaymentAddresses = silentPaymentAddresses
        .where(
          (a) => !a.isChange && (isHidden == true ? a.isHidden : !a.isHidden),
        )
        .toList();
    final nextSPLabelIndex = existingSilentPaymentAddresses.length;

    late BitcoinSilentPaymentAddressRecord address;
    if (isHidden == true) {
      final oldScanPath = Bip32PathParser.parse(OLD_SP_PATH.replaceFirst("#", "1"));
      final oldSpendPath = Bip32PathParser.parse(OLD_SP_PATH.replaceFirst("#", "0"));

      final oldSilentPaymentWallet = SilentPaymentOwner.fromPrivateKeys(
        b_scan: ECPrivate(hdWallet.derive(oldScanPath).privateKey),
        b_spend: ECPrivate(hdWallet.derive(oldSpendPath).privateKey),
      );

      address = BitcoinSilentPaymentAddressRecord(
        oldSilentPaymentWallet.toLabeledSilentPaymentAddress(nextSPLabelIndex).toString(),
        labelIndex: nextSPLabelIndex,
        derivationPath: oldSpendPath.toString(),
        name: label,
        labelHex: BytesUtils.toHexString(oldSilentPaymentWallet.generateLabel(nextSPLabelIndex)),
        type: SilentPaymentsAddresType.p2sp,
        isChange: false,
        isHidden: true,
      );
    } else {
      address = BitcoinSilentPaymentAddressRecord(
        silentPaymentWallet!.toLabeledSilentPaymentAddress(nextSPLabelIndex).toString(),
        labelIndex: nextSPLabelIndex,
        name: label,
        labelHex: BytesUtils.toHexString(silentPaymentWallet!.generateLabel(nextSPLabelIndex)),
        type: SilentPaymentsAddresType.p2sp,
        isChange: false,
        isHidden: false,
      );
    }

    silentPaymentAddresses.add(address);
    updateAddressesByType();
    updateHiddenAddresses();

    return address;
  }

  @override
  @action
  Future<void> updateAddressesInBox() async {
    receiveAddressesByType.entries.forEach((e) {
      final addressType = e.key;
      final addresses = e.value;

      for (final addr in addresses) {
        if (getIsReceive(addr)) {
          allAddressesMap[addr.address] = addr.name;

          final isCurrentType = addr.type == addressPageType;

          if (addressType == SilentPaymentsAddresType.p2sp) {
            final addressString =
                '${addr.address.substring(0, 9 + 5)}...${addr.address.substring(addr.address.length - 9, addr.address.length)}';

            if (!isCurrentType) {
              addressesMap[addr.address] = addr.name.isEmpty
                  ? "Silent Payments" + ': $addressString'
                  : "Silent Payments - " + addr.name + ': $addressString';
            } else {
              addressesMap[address] = 'Active - Silent Payments' + ': $addressString';
            }

            // Silent Payments address don't break the loop because all are used
            // break;
          } else {
            if (!isCurrentType) {
              addressesMap[addr.address] = '${addressType.value.toUpperCase()}: ${addr.address}';
            } else {
              addressesMap[address] = 'Active - ${addressType.value.toUpperCase()}: $address';
            }

            // Break the loop, already got the firt unused address
            break;
          }
        }
      }
    });

    await saveAddressesInBox();
  }

  @override
  @action
  void updateAddress(String address, String label) {
    super.updateAddress(address, label);

    BaseBitcoinAddressRecord? foundAddress;
    silentPaymentAddresses.forEach((addressRecord) {
      if (addressRecord.address == address) {
        foundAddress = addressRecord;
      }
    });

    if (foundAddress != null) {
      foundAddress!.setNewName(label);

      final index =
          silentPaymentAddresses.indexOf(foundAddress as BitcoinSilentPaymentAddressRecord);
      silentPaymentAddresses.remove(foundAddress);
      silentPaymentAddresses.insert(index, foundAddress as BitcoinSilentPaymentAddressRecord);
    }
  }

  @override
  @action
  void updateAddressesByType() {
    receiveAddressesByType[SilentPaymentsAddresType.p2sp] = silentPaymentAddresses
        .where((addressRecord) =>
            addressRecord.type == SilentPaymentsAddresType.p2sp && !addressRecord.isChange)
        .toList();

    super.updateAddressesByType();
  }

  @action
  void addSilentAddresses(Iterable<BitcoinSilentPaymentAddressRecord> addresses) {
    final addressesSet = this.silentPaymentAddresses.toSet();
    addressesSet.addAll(addresses);
    this.silentPaymentAddresses.clear();
    this.silentPaymentAddresses.addAll(addressesSet);
    updateAddressesByType();
  }

  @action
  void addReceivedSPAddresses(Iterable<BitcoinReceivedSPAddressRecord> addresses) {
    final addressesSet = this.receivedSPAddresses.toSet();
    addressesSet.addAll(addresses);
    this.receivedSPAddresses.clear();
    this.receivedSPAddresses.addAll(addressesSet);
    updateAddressesByType();
  }

  @action
  void deleteSilentPaymentAddress(String address) {
    final addressRecord = silentPaymentAddresses.firstWhereOrNull(
      (addressRecord) =>
          addressRecord.type == SilentPaymentsAddresType.p2sp && addressRecord.address == address,
    );

    if (addressRecord == null) {
      return;
    }

    silentPaymentAddresses.remove(addressRecord);
    updateAddressesByType();
  }

  Map<String, int> getLabels(String address) {
    final labels = <String, int>{};

    for (int i = 0; i < silentPaymentAddresses.length; i++) {
      final silentAddressRecord = silentPaymentAddresses[i];
      if (!silentAddressRecord.address.startsWith(address.substring(0, 9))) {
        continue;
      }

      final silentPaymentTweak = silentAddressRecord.labelHex;

      if (silentPaymentTweak != null) {
        labels[silentPaymentTweak] = silentAddressRecord.labelIndex;
      }
    }
    return labels;
  }

  @override
  @action
  void updateHiddenAddresses() {
    super.updateHiddenAddresses();

    hiddenAddresses.addAll(silentPaymentAddresses
        .where((addressRecord) => addressRecord.isHidden)
        .map((addressRecord) => addressRecord.address));
  }

  List<String> getUsableSilentPaymentAddresses() {
    final oldSpendPath = Bip32PathParser.parse(OLD_SP_PATH.replaceFirst("#", "0"));
    final primaryAddress = silentPaymentAddresses.firstWhere(
      (addressRecord) =>
          !addressRecord.isChange &&
          addressRecord.labelIndex == 0 &&
          addressRecord.derivationPath != oldSpendPath.toString(),
    );

    final hiddenAddress = silentPaymentAddresses.firstWhere(
      (addressRecord) =>
          !addressRecord.isChange &&
          addressRecord.labelIndex == 0 &&
          addressRecord.derivationPath == oldSpendPath.toString(),
    );

    return [primaryAddress.address, hiddenAddress.address];
  }

  @action
  void setSilentPaymentsScanWallet(String address) {
    scanningSilentAddress = address;
  }

  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['silentPaymentAddresses'] =
        silentPaymentAddresses.map((address) => address.toJSON()).toList();
    json['receivedSPAddresses'] = receivedSPAddresses.map((address) => address.toJSON()).toList();
    json['silentAddressIndex'] = silentAddressIndex.toString();
    json['loadedFromNewSnapshot'] = true;
    return json;
  }

  static Map<String, dynamic> fromSnapshot(Map<dynamic, dynamic> data) {
    final electrumSnapshot = ElectrumWalletAddressesBase.fromSnapshot(data);

    final silentAddressesTmp = data['silent_addresses'] as List? ?? <Object>[];
    final silentPaymentAddresses = <BitcoinReceivedSPAddressRecord>[];
    final receivedSPAddresses = <BitcoinSilentPaymentAddressRecord>[];

    silentAddressesTmp.whereType<String>().forEach((j) {
      final decoded = json.decode(j) as Map;
      if (decoded['tweak'] != null || decoded['silent_payment_tweak'] != null) {
        silentPaymentAddresses.add(BitcoinReceivedSPAddressRecord.fromJSON(j));
      } else {
        receivedSPAddresses.add(BitcoinSilentPaymentAddressRecord.fromJSON(j));
      }
    });
    var silentAddressIndex = 0;

    try {
      silentAddressIndex = int.parse(data['silent_address_index'] as String? ?? '0');
    } catch (_) {}

    return {
      'allAddresses': electrumSnapshot["addresses"],
      'addressPageType': data['address_page_type'] as String?,
      'receiveAddressIndexByType': electrumSnapshot["receiveAddressIndexByType"],
      'changeAddressIndexByType': electrumSnapshot["changeAddressIndexByType"],
      'silentPaymentAddresses': silentPaymentAddresses,
      'receivedSPAddresses': receivedSPAddresses,
      'silentAddressIndex': silentAddressIndex,
    };
  }

  static BitcoinWalletAddressesBase fromJson(
    Map<String, dynamic> json,
    WalletInfo walletInfo, {
    required Map<SeedBytesType, Bip32Slip10Secp256k1> hdWallets,
    required BasedUtxoNetwork network,
    required bool isHardwareWallet,
    // TODO: make it used
    List<BitcoinAddressRecord>? initialAddresses,
    List<BitcoinSilentPaymentAddressRecord>? initialSilentAddresses,
    List<BitcoinReceivedSPAddressRecord>? initialReceivedSPAddresses,
  }) {
    initialAddresses ??= (json['allAddresses'] as List)
        .map((record) => BitcoinAddressRecord.fromJSON(record as String))
        .toList();

    initialSilentAddresses ??= (json['silentPaymentAddresses'] as List)
        .map(
          (address) => BitcoinSilentPaymentAddressRecord.fromJSON(address as String),
        )
        .toList();
    initialReceivedSPAddresses ??= (json['receivedSPAddresses'] as List)
        .map(
          (address) => BitcoinReceivedSPAddressRecord.fromJSON(address as String),
        )
        .toList();

    return BitcoinWalletAddresses(
      walletInfo,
      hdWallets: hdWallets,
      network: network,
      isHardwareWallet: isHardwareWallet,
      initialAddresses: initialAddresses,
      initialSilentAddresses: initialSilentAddresses,
      initialReceivedSPAddresses: initialReceivedSPAddresses,
      loadedFromNewSnapshot: json['loadedFromNewSnapshot'] as bool? ?? false,
    );
  }
}
