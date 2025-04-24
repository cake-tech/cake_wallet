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

abstract class BitcoinWalletAddressesBase extends ElectrumWalletAddresses with Store {
  static const _OLD_SP_PATH = "m/352'/1'/0'/#'/0";

  BitcoinWalletAddressesBase(
    WalletInfo walletInfo, {
    required super.hdWallets,
    required super.network,
    required super.isHardwareWallet,
    super.initialAddressesRecords,
    super.initialActiveAddressIndex,
    super.initialAddressPageType,
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

  // NOTE: ordered in priority: eg. p2wpkh always first, most used address, etc.
  @override
  final walletAddressTypes = [
    SegwitAddressType.p2wpkh,
    SegwitAddressType.p2tr,
    P2shAddressType.p2wpkhInP2sh,
    P2pkhAddressType.p2pkh,
    SegwitAddressType.p2wsh,
  ];

  List<BaseBitcoinAddressRecord> get otherAddresses => silentPaymentAddresses;

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
    generateInitialSPAddresses();
    super.init();
  }

  @action
  Future<void> generateInitialSPAddresses() async {
    final addAddresses = silentPaymentAddresses.isEmpty;

    // NOTE: Only initiate these old addresses if restoring a wallet and possibly wants the older cake derivation path
    if (walletInfo.isRecovery && silentPaymentWallets.length == 1) {
      final oldScanPath = Bip32PathParser.parse(_OLD_SP_PATH.replaceFirst("#", "1"));
      final oldSpendPath = Bip32PathParser.parse(_OLD_SP_PATH.replaceFirst("#", "0"));

      final oldSilentPaymentWallet = SilentPaymentOwner.fromPrivateKeys(
        b_scan: ECPrivate(hdWallet.derive(oldScanPath).privateKey),
        b_spend: ECPrivate(hdWallet.derive(oldSpendPath).privateKey),
      );

      silentPaymentWallets.add(oldSilentPaymentWallet);

      if (addAddresses)
        silentPaymentAddresses.addAll(
          [
            BitcoinSilentPaymentAddressRecord(
              oldSilentPaymentWallet.toString(),
              network: network,
              labelIndex: 0,
              name: "",
              type: SilentPaymentsAddresType.p2sp,
              derivationPath: oldSpendPath.toString(),
              isHidden: true,
              isChange: false,
            ),
            BitcoinSilentPaymentAddressRecord(
              oldSilentPaymentWallet.toLabeledSilentPaymentAddress(0).toString(),
              network: network,
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

    if (addAddresses)
      silentPaymentAddresses.addAll([
        BitcoinSilentPaymentAddressRecord(
          silentPaymentWallet!.toString(),
          network: network,
          labelIndex: 0,
          name: "",
          type: SilentPaymentsAddresType.p2sp,
          isChange: false,
        ),
        BitcoinSilentPaymentAddressRecord(
          silentPaymentWallet!.toLabeledSilentPaymentAddress(0).toString(),
          network: network,
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
  void resetActiveAddress() {
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

    super.resetActiveAddress();
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
      final oldScanPath = Bip32PathParser.parse(_OLD_SP_PATH.replaceFirst("#", "1"));
      final oldSpendPath = Bip32PathParser.parse(_OLD_SP_PATH.replaceFirst("#", "0"));

      final oldSilentPaymentWallet = SilentPaymentOwner.fromPrivateKeys(
        b_scan: ECPrivate(hdWallet.derive(oldScanPath).privateKey),
        b_spend: ECPrivate(hdWallet.derive(oldSpendPath).privateKey),
      );

      address = BitcoinSilentPaymentAddressRecord(
        oldSilentPaymentWallet.toLabeledSilentPaymentAddress(nextSPLabelIndex).toString(),
        network: network,
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
        network: network,
        labelIndex: nextSPLabelIndex,
        name: label,
        labelHex: BytesUtils.toHexString(silentPaymentWallet!.generateLabel(nextSPLabelIndex)),
        type: SilentPaymentsAddresType.p2sp,
        isChange: false,
        isHidden: false,
      );
    }

    silentPaymentAddresses.add(address);

    return address;
  }

  @override
  @action
  Future<void> updateAddressesInBox() async {
    await super.updateAddressesInBox();

    final addr = activeSilentAddress ??
        silentPaymentAddresses.firstWhereOrNull(
          (addressRecord) => !addressRecord.isHidden && !addressRecord.isChange,
        );

    if (addr != null) {
      final addressString =
          '${addr.address.substring(0, 9 + 5)}...${addr.address.substring(addr.address.length - 9, addr.address.length)}';

      final isCurrentType = addressPageType == SilentPaymentsAddresType.p2sp;

      if (!isCurrentType) {
        addressesMap[addr.address] = addr.name.isEmpty
            ? "Silent Payments" + ': $addressString'
            : "Silent Payments - " + addr.name + ': $addressString';
      } else {
        addressesMap[addr.address] = 'Active - Silent Payments' + ': $addressString';
      }
    }

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

  @action
  void addSilentAddresses(Iterable<BitcoinSilentPaymentAddressRecord> addresses) {
    final addressesSet = this.silentPaymentAddresses.toSet();
    addressesSet.addAll(addresses);
    this.silentPaymentAddresses.clear();
    this.silentPaymentAddresses.addAll(addressesSet);
  }

  @action
  void addReceivedSPAddresses(Iterable<BitcoinReceivedSPAddressRecord> addresses) {
    final addressesSet = this.receivedSPAddresses.toSet();
    addressesSet.addAll(addresses);
    this.receivedSPAddresses.clear();
    this.receivedSPAddresses.addAll(addressesSet);

    for (final receivedSPAddress in receivedSPAddresses) {
      for (final addressRecord in silentPaymentAddresses) {
        if (receivedSPAddress.spAddress == addressRecord.address) {
          addressRecord.balance.confirmed += receivedSPAddress.balance.confirmed;
          addressRecord.txCount += 1;
          break;
        }
      }
    }
  }

  @action
  void deleteSilentPaymentAddress(String address) {
    final addressRecord = silentPaymentAddresses.firstWhereOrNull(
      (addressRecord) => addressRecord.address == address,
    );

    if (addressRecord == null) {
      return;
    }

    silentPaymentAddresses.remove(addressRecord);
  }

  Map<String, int> getLabels(List<String> addresses) {
    final labels = <String, int>{};

    for (int i = 0; i < silentPaymentAddresses.length; i++) {
      final silentAddressRecord = silentPaymentAddresses[i];
      if (!addresses.any((addr) => addr.startsWith(silentAddressRecord.address.substring(0, 9)))) {
        continue;
      }

      final silentPaymentTweak = silentAddressRecord.labelHex;

      if (silentPaymentTweak != null) {
        labels[silentPaymentTweak] = silentAddressRecord.labelIndex;
      }
    }

    return labels;
  }

  List<String> getUsableSilentPaymentAddresses() {
    final oldSpendPath = Bip32PathParser.parse(_OLD_SP_PATH.replaceFirst("#", "0"));
    final primaryAddress = silentPaymentAddresses.firstWhere(
      (addressRecord) =>
          !addressRecord.isChange &&
          addressRecord.labelIndex == 0 &&
          addressRecord.indexedDerivationPath != oldSpendPath.toString(),
    );

    final list = [primaryAddress.address];

    final hiddenAddress = silentPaymentAddresses.firstWhereOrNull(
      (addressRecord) =>
          !addressRecord.isChange &&
          addressRecord.labelIndex == 0 &&
          addressRecord.indexedDerivationPath == oldSpendPath.toString(),
    );

    // Do it like this to keep in order,
    // the primary address always first in the list
    if (hiddenAddress != null) {
      list.add(hiddenAddress.address);
    }

    return list;
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

  static BitcoinWalletAddresses fromJson(
    Map<String, dynamic> snp,
    WalletInfo walletInfo, {
    required Map<SeedBytesType, Bip32Slip10Secp256k1> hdWallets,
    required BasedUtxoNetwork network,
    required bool isHardwareWallet,
  }) {
    final electrumJson = ElectrumWalletAddressesBase.fromJson(
      snp,
      walletInfo,
      hdWallets: hdWallets,
      network: network,
      isHardwareWallet: isHardwareWallet,
    );

    final initialSilentAddresses = (snp['silentPaymentAddresses'] as List)
        .map(
          (address) => BitcoinSilentPaymentAddressRecord.fromJSON(address as String),
        )
        .toList();
    final initialReceivedSPAddresses = (snp['receivedSPAddresses'] as List)
        .map(
          (address) => BitcoinReceivedSPAddressRecord.fromJSON(address as String),
        )
        .toList();

    return BitcoinWalletAddresses(
      walletInfo,
      hdWallets: hdWallets,
      network: network,
      isHardwareWallet: isHardwareWallet,
      initialAddressesRecords: electrumJson.addressesRecords,
      initialAddressPageType: electrumJson.addressPageType,
      initialActiveAddressIndex: electrumJson.activeIndexByType,
      initialSilentAddresses: initialSilentAddresses,
      initialReceivedSPAddresses: initialReceivedSPAddresses,
    );
  }
}
