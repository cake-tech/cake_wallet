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

  @observable
  SilentPaymentOwner? silentPaymentWallet;
  final ObservableList<BitcoinSilentPaymentAddressRecord> silentPaymentAddresses;
  final ObservableList<BitcoinReceivedSPAddressRecord> receivedSPAddresses;

  List<BitcoinSilentPaymentAddressRecord> get usableSilentPaymentAddresses => silentPaymentAddresses
      .where((addressRecord) =>
          addressRecord.type != SegwitAddressType.p2tr &&
          addressRecord.derivationPath == BitcoinDerivationPaths.SILENT_PAYMENTS_SPEND)
      .toList();

  @observable
  List<SilentPaymentOwner> silentPaymentWallets = [];

  @observable
  String? activeSilentAddress;

  @override
  Future<void> init() async {
    await generateInitialAddresses(type: SegwitAddressType.p2wpkh);

    if (!isHardwareWallet) {
      await generateInitialAddresses(type: P2pkhAddressType.p2pkh);
      await generateInitialAddresses(type: P2shAddressType.p2wpkhInP2sh);
      await generateInitialAddresses(type: SegwitAddressType.p2tr);
      await generateInitialAddresses(type: SegwitAddressType.p2wsh);
    }

    if (silentPaymentAddresses.length == 0) {
      Bip32Path? oldSpendPath;
      Bip32Path? oldScanPath;

      for (final derivationInfo in walletInfo.derivations ?? <DerivationInfo>[]) {
        if (derivationInfo.description?.contains("SP") ?? false) {
          if (derivationInfo.description?.toLowerCase().contains("spend") ?? false) {
            oldSpendPath = Bip32PathParser.parse(derivationInfo.derivationPath ?? "");
          } else if (derivationInfo.description?.toLowerCase().contains("scan") ?? false) {
            oldScanPath = Bip32PathParser.parse(derivationInfo.derivationPath ?? "");
          }
        }
      }

      if (oldSpendPath != null && oldScanPath != null) {
        final oldSpendPriv = hdWallet.derive(oldSpendPath).privateKey;
        final oldScanPriv = hdWallet.derive(oldScanPath).privateKey;

        final oldSilentPaymentWallet = SilentPaymentOwner(
          b_scan: ECPrivate(oldScanPriv),
          b_spend: ECPrivate(oldSpendPriv),
          B_scan: ECPublic.fromBip32(oldScanPriv.publicKey),
          B_spend: ECPublic.fromBip32(oldSpendPriv.publicKey),
          version: 0,
        );
        silentPaymentWallets.add(oldSilentPaymentWallet);

        silentPaymentAddresses.addAll(
          [
            BitcoinSilentPaymentAddressRecord(
              oldSilentPaymentWallet.toString(),
              labelIndex: 1,
              name: "",
              type: SilentPaymentsAddresType.p2sp,
              derivationPath: oldSpendPath.toString(),
              isHidden: true,
            ),
            BitcoinSilentPaymentAddressRecord(
              oldSilentPaymentWallet.toLabeledSilentPaymentAddress(0).toString(),
              name: "",
              labelIndex: 0,
              labelHex: BytesUtils.toHexString(oldSilentPaymentWallet.generateLabel(0)),
              type: SilentPaymentsAddresType.p2sp,
              derivationPath: oldSpendPath.toString(),
              isHidden: true,
            ),
          ],
        );
      }

      silentPaymentAddresses.addAll([
        BitcoinSilentPaymentAddressRecord(
          silentPaymentWallet.toString(),
          labelIndex: 1,
          name: "",
          type: SilentPaymentsAddresType.p2sp,
        ),
        BitcoinSilentPaymentAddressRecord(
          silentPaymentWallet!.toLabeledSilentPaymentAddress(0).toString(),
          name: "",
          labelIndex: 0,
          labelHex: BytesUtils.toHexString(silentPaymentWallet!.generateLabel(0)),
          type: SilentPaymentsAddresType.p2sp,
        ),
      ]);
    }

    await updateAddressesInBox();
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
      final currentSPLabelIndex = usableSilentPaymentAddresses.length - 1;

      final address = BitcoinSilentPaymentAddressRecord(
        silentPaymentWallet!.toLabeledSilentPaymentAddress(currentSPLabelIndex).toString(),
        labelIndex: currentSPLabelIndex,
        name: label,
        labelHex: BytesUtils.toHexString(silentPaymentWallet!.generateLabel(currentSPLabelIndex)),
        type: SilentPaymentsAddresType.p2sp,
      );

      silentPaymentAddresses.add(address);
      Future.delayed(Duration.zero, () => updateAddressesOnReceiveScreen());

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
    this.hiddenAddresses.addAll(silentPaymentAddresses
        .where((addressRecord) => addressRecord.isHidden)
        .map((addressRecord) => addressRecord.address));
  }

  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['silentPaymentAddresses'] =
        silentPaymentAddresses.map((address) => address.toJSON()).toList();
    json['receivedSPAddresses'] = receivedSPAddresses.map((address) => address.toJSON()).toList();
    return json;
  }
}
