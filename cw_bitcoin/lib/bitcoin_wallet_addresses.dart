import 'dart:convert';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/electrum_wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:mobx/mobx.dart';

part 'bitcoin_wallet_addresses.g.dart';

class BitcoinWalletAddresses = BitcoinWalletAddressesBase with _$BitcoinWalletAddresses;

abstract class BitcoinWalletAddressesBase extends ElectrumWalletAddresses with Store {
  BitcoinWalletAddressesBase(
    WalletInfo walletInfo, {
    required super.hdWallets,
    required super.network,
    required super.isHardwareWallet,
    super.initialAddresses,
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

  static const OLD_SP_SPEND_PATH = "m/352'/1'/0'/0'/0";
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
  String? activeSilentAddress;

  @override
  Future<void> init() async {
    // TODO: if restored from snapshot

    if (allAddresses.where((address) => address.type == SegwitAddressType.p2wpkh).isEmpty) {
      await generateInitialAddresses(type: SegwitAddressType.p2wpkh);
    }

    if (!isHardwareWallet) {
      if (allAddresses.where((address) => address.type == P2pkhAddressType.p2pkh).isEmpty)
        await generateInitialAddresses(type: P2pkhAddressType.p2pkh);

      if (allAddresses.where((address) => address.type == P2shAddressType.p2wpkhInP2sh).isEmpty)
        await generateInitialAddresses(type: P2shAddressType.p2wpkhInP2sh);

      if (allAddresses.where((address) => address.type == SegwitAddressType.p2tr).isEmpty)
        await generateInitialAddresses(type: SegwitAddressType.p2tr);

      if (allAddresses.where((address) => address.type == SegwitAddressType.p2wsh).isEmpty)
        await generateInitialAddresses(type: SegwitAddressType.p2wsh);

      if (silentPaymentAddresses.isEmpty) {
        if (walletInfo.isRecovery) {
          final oldScanPath = Bip32PathParser.parse("m/352'/1'/0'/1'/0");
          final oldSpendPath = Bip32PathParser.parse("m/352'/1'/0'/0'/0");

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
    }

    super.init();
  }

  @action
  Future<void> generateSilentPaymentAddresses({required BitcoinAddressType type}) async {
    // final hasOldSPAddresses = silentPaymentAddresses.any((address) =>
    //     address.type == SilentPaymentsAddresType.p2sp &&
    //     address.derivationPath == OLD_SP_SPEND_PATH);

    if (walletInfo.isRecovery) {
      final oldScanPath = Bip32PathParser.parse("m/352'/1'/0'/1'/0");
      final oldSpendPath = Bip32PathParser.parse("m/352'/1'/0'/0'/0");

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

    updateHiddenAddresses();
  }

  @override
  @computed
  String get address {
    if (addressPageType == SilentPaymentsAddresType.p2sp) {
      if (activeSilentAddress != null) {
        return activeSilentAddress!;
      }

      return silentPaymentWallet.toString();
    }

    return super.address;
  }

  @override
  set address(String addr) {
    if (addr == "Silent Payments" && SilentPaymentsAddresType.p2sp != addressPageType) {
      return;
    }

    if (addressPageType == SilentPaymentsAddresType.p2sp) {
      late BitcoinSilentPaymentAddressRecord selected;
      try {
        selected =
            silentPaymentAddresses.firstWhere((addressRecord) => addressRecord.address == addr);
      } catch (_) {
        selected = silentPaymentAddresses[0];
      }

      if (selected.labelHex != null) {
        activeSilentAddress =
            silentPaymentWallet!.toLabeledSilentPaymentAddress(selected.labelIndex).toString();
      } else {
        activeSilentAddress = silentPaymentWallet.toString();
      }
      return;
    }

    super.address = addr;
  }

  @override
  BitcoinBaseAddress generateAddress({
    required CWBitcoinDerivationType derivationType,
    required bool isChange,
    required int index,
    required BitcoinAddressType addressType,
    required BitcoinDerivationInfo derivationInfo,
  }) {
    final hdWallet = hdWallets[derivationType]!;

    // if (OLD_DERIVATION_TYPES.contains(derivationType)) {
    //   final pub = hdWallet
    //       .childKey(Bip32KeyIndex(isChange ? 1 : 0))
    //       .childKey(Bip32KeyIndex(index))
    //       .publicKey;

    //   switch (addressType) {
    //     case P2pkhAddressType.p2pkh:
    //       return ECPublic.fromBip32(pub).toP2pkhAddress();
    //     case SegwitAddressType.p2tr:
    //       return ECPublic.fromBip32(pub).toP2trAddress();
    //     case SegwitAddressType.p2wsh:
    //       return ECPublic.fromBip32(pub).toP2wshAddress();
    //     case P2shAddressType.p2wpkhInP2sh:
    //       return ECPublic.fromBip32(pub).toP2wpkhInP2sh();
    //     case SegwitAddressType.p2wpkh:
    //       return ECPublic.fromBip32(pub).toP2wpkhAddress();
    //     default:
    //       throw ArgumentError('Invalid address type');
    //   }
    // }

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

  @override
  @action
  BaseBitcoinAddressRecord generateNewAddress({String label = ''}) {
    if (addressPageType == SilentPaymentsAddresType.p2sp) {
      final usableSilentPaymentAddresses = silentPaymentAddresses
          .where((a) =>
              a.type != SegwitAddressType.p2tr &&
              a.derivationPath != OLD_SP_SPEND_PATH &&
              a.isChange == false)
          .toList();
      final nextSPLabelIndex = usableSilentPaymentAddresses.length;

      final address = BitcoinSilentPaymentAddressRecord(
        silentPaymentWallet!.toLabeledSilentPaymentAddress(nextSPLabelIndex).toString(),
        labelIndex: nextSPLabelIndex,
        name: label,
        labelHex: BytesUtils.toHexString(silentPaymentWallet!.generateLabel(nextSPLabelIndex)),
        type: SilentPaymentsAddresType.p2sp,
        isChange: false,
      );

      silentPaymentAddresses.add(address);
      updateAddressesOnReceiveScreen();

      return address;
    }

    return super.generateNewAddress(label: label);
  }

  // @override
  // @action
  // void addBitcoinAddressTypes() {
  //   super.addBitcoinAddressTypes();

  //   silentPaymentAddresses.forEach((addressRecord) {
  //     if (addressRecord.type != SilentPaymentsAddresType.p2sp || addressRecord.isChange) {
  //       return;
  //     }

  //     if (addressRecord.address != address) {
  //       addressesMap[addressRecord.address] = addressRecord.name.isEmpty
  //           ? "Silent Payments" + ': ${addressRecord.address}'
  //           : "Silent Payments - " + addressRecord.name + ': ${addressRecord.address}';
  //     } else {
  //       addressesMap[address] = 'Active - Silent Payments' + ': $address';
  //     }
  //   });
  // }

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
  void updateAddressesOnReceiveScreen() {
    if (addressPageType == SilentPaymentsAddresType.p2sp) {
      addressesOnReceiveScreen.clear();
      addressesOnReceiveScreen.addAll(silentPaymentAddresses);
      return;
    }

    super.updateAddressesOnReceiveScreen();
  }

  @action
  void addSilentAddresses(Iterable<BitcoinSilentPaymentAddressRecord> addresses) {
    final addressesSet = this.silentPaymentAddresses.toSet();
    addressesSet.addAll(addresses);
    this.silentPaymentAddresses.clear();
    this.silentPaymentAddresses.addAll(addressesSet);
    updateAddressesOnReceiveScreen();
  }

  @action
  void addReceivedSPAddresses(Iterable<BitcoinReceivedSPAddressRecord> addresses) {
    final addressesSet = this.receivedSPAddresses.toSet();
    addressesSet.addAll(addresses);
    this.receivedSPAddresses.clear();
    this.receivedSPAddresses.addAll(addressesSet);
    updateAddressesOnReceiveScreen();
  }

  @action
  void deleteSilentPaymentAddress(String address) {
    final addressRecord = silentPaymentAddresses.firstWhere((addressRecord) =>
        addressRecord.type == SilentPaymentsAddresType.p2sp && addressRecord.address == address);

    silentPaymentAddresses.remove(addressRecord);
    updateAddressesOnReceiveScreen();
  }

  Map<String, String> get labels {
    final G = ECPublic.fromBytes(BigintUtils.toBytes(Curves.generatorSecp256k1.x, length: 32));
    final labels = <String, String>{};
    for (int i = 0; i < silentPaymentAddresses.length; i++) {
      final silentAddressRecord = silentPaymentAddresses[i];
      final silentPaymentTweak = silentAddressRecord.labelHex;

      if (silentPaymentTweak != null &&
          SilentPaymentAddress.regex.hasMatch(silentAddressRecord.address)) {
        labels[G
            .tweakMul(BigintUtils.fromBytes(BytesUtils.fromHexString(silentPaymentTweak)))
            .toHex()] = silentPaymentTweak;
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

  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['silentPaymentAddresses'] =
        silentPaymentAddresses.map((address) => address.toJSON()).toList();
    json['receivedSPAddresses'] = receivedSPAddresses.map((address) => address.toJSON()).toList();
    // json['silentAddressIndex'] = silentAddressIndex.toString();
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
    );
  }
}
