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
    required super.network,
    required super.isHardwareWallet,
    required super.hdWallets,
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
  }

  @observable
  late final SilentPaymentOwner silentPaymentWallet;
  final ObservableList<BitcoinSilentPaymentAddressRecord> silentPaymentAddresses;
  final ObservableList<BitcoinReceivedSPAddressRecord> receivedSPAddresses;

  @observable
  String? activeSilentAddress;

  @override
  Future<void> init() async {
    await generateInitialAddresses(addressType: SegwitAddresType.p2wpkh);

    if (!isHardwareWallet) {
      await generateInitialAddresses(addressType: P2pkhAddressType.p2pkh);
      await generateInitialAddresses(addressType: P2shAddressType.p2wpkhInP2sh);
      await generateInitialAddresses(addressType: SegwitAddresType.p2tr);
      await generateInitialAddresses(addressType: SegwitAddresType.p2wsh);
    }

    if (silentPaymentAddresses.length == 0) {
      silentPaymentAddresses.add(BitcoinSilentPaymentAddressRecord(
        silentPaymentWallet.toString(),
        labelIndex: 1,
        name: "",
        addressType: SilentPaymentsAddresType.p2sp,
      ));
      silentPaymentAddresses.add(BitcoinSilentPaymentAddressRecord(
        silentPaymentWallet.toLabeledSilentPaymentAddress(0).toString(),
        name: "",
        labelIndex: 0,
        labelHex: BytesUtils.toHexString(silentPaymentWallet.generateLabel(0)),
        addressType: SilentPaymentsAddresType.p2sp,
      ));
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
            silentPaymentWallet.toLabeledSilentPaymentAddress(selected.labelIndex).toString();
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

    if (derivationType == CWBitcoinDerivationType.old) {
      final pub = hdWallet
          .childKey(Bip32KeyIndex(isChange ? 1 : 0))
          .childKey(Bip32KeyIndex(index))
          .publicKey;

      switch (addressType) {
        case P2pkhAddressType.p2pkh:
          return ECPublic.fromBip32(pub).toP2pkhAddress();
        case SegwitAddresType.p2tr:
          return ECPublic.fromBip32(pub).toP2trAddress();
        case SegwitAddresType.p2wsh:
          return ECPublic.fromBip32(pub).toP2wshAddress();
        case P2shAddressType.p2wpkhInP2sh:
          return ECPublic.fromBip32(pub).toP2wpkhInP2sh();
        case SegwitAddresType.p2wpkh:
          return ECPublic.fromBip32(pub).toP2wpkhAddress();
        default:
          throw ArgumentError('Invalid address type');
      }
    }

    switch (addressType) {
      case P2pkhAddressType.p2pkh:
        return P2pkhAddress.fromDerivation(
          bip32: hdWallet,
          derivationInfo: derivationInfo,
          isChange: isChange,
          index: index,
        );
      case SegwitAddresType.p2tr:
        return P2trAddress.fromDerivation(
          bip32: hdWallet,
          derivationInfo: derivationInfo,
          isChange: isChange,
          index: index,
        );
      case SegwitAddresType.p2wsh:
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
      case SegwitAddresType.p2wpkh:
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
      final currentSPLabelIndex = silentPaymentAddresses
              .where((addressRecord) => addressRecord.addressType != SegwitAddresType.p2tr)
              .length -
          1;

      final address = BitcoinSilentPaymentAddressRecord(
        silentPaymentWallet.toLabeledSilentPaymentAddress(currentSPLabelIndex).toString(),
        labelIndex: currentSPLabelIndex,
        name: label,
        labelHex: BytesUtils.toHexString(silentPaymentWallet.generateLabel(currentSPLabelIndex)),
        addressType: SilentPaymentsAddresType.p2sp,
      );

      silentPaymentAddresses.add(address);
      Future.delayed(Duration.zero, () => updateAddressesByMatch());

      return address;
    }

    return super.generateNewAddress(label: label);
  }

  @override
  @action
  void addBitcoinAddressTypes() {
    super.addBitcoinAddressTypes();

    silentPaymentAddresses.forEach((addressRecord) {
      if (addressRecord.addressType != SilentPaymentsAddresType.p2sp || addressRecord.isChange) {
        return;
      }

      if (addressRecord.address != address) {
        addressesMap[addressRecord.address] = addressRecord.name.isEmpty
            ? "Silent Payments" + ': ${addressRecord.address}'
            : "Silent Payments - " + addressRecord.name + ': ${addressRecord.address}';
      } else {
        addressesMap[address] = 'Active - Silent Payments' + ': $address';
      }
    });
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
  void updateAddressesByMatch() {
    if (addressPageType == SilentPaymentsAddresType.p2sp) {
      addressesByReceiveType.clear();
      addressesByReceiveType.addAll(silentPaymentAddresses);
      return;
    }

    super.updateAddressesByMatch();
  }

  @action
  void addSilentAddresses(Iterable<BitcoinSilentPaymentAddressRecord> addresses) {
    final addressesSet = this.silentPaymentAddresses.toSet();
    addressesSet.addAll(addresses);
    this.silentPaymentAddresses.clear();
    this.silentPaymentAddresses.addAll(addressesSet);
    updateAddressesByMatch();
  }

  @action
  void deleteSilentPaymentAddress(String address) {
    final addressRecord = silentPaymentAddresses.firstWhere((addressRecord) =>
        addressRecord.addressType == SilentPaymentsAddresType.p2sp &&
        addressRecord.address == address);

    silentPaymentAddresses.remove(addressRecord);
    updateAddressesByMatch();
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

  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['silentPaymentAddresses'] =
        silentPaymentAddresses.map((address) => address.toJSON()).toList();
    json['receivedSPAddresses'] = receivedSPAddresses.map((address) => address.toJSON()).toList();
    return json;
  }
}
