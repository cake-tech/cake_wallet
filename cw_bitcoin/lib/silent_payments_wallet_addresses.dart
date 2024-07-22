import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/electrum_wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:mobx/mobx.dart';

part 'silent_payments_wallet_addresses.g.dart';

class SilentPaymentsWalletAddresses = SilentPaymentsWalletAddressesBase
    with _$SilentPaymentsWalletAddresses;

abstract class SilentPaymentsWalletAddressesBase extends ElectrumWalletAddresses {
  SilentPaymentsWalletAddressesBase(
    WalletInfo walletInfo, {
    required Bip32Slip10Secp256k1 accountHD,
    required super.network,
    super.initialAddresses,
    super.initialRegularAddressIndex,
    super.initialChangeAddressIndex,
    super.initialAddressPageType,
    List<BitcoinSilentPaymentAddressRecord>? initialSilentAddresses,
    int initialSilentAddressIndex = 0,
  })  : silentAddresses = ObservableList<BitcoinSilentPaymentAddressRecord>.of(
            (initialSilentAddresses ?? []).toSet()),
        currentSilentAddressIndex = initialSilentAddressIndex,
        super(walletInfo, accountHD: accountHD) {
    silentAddress = SilentPaymentOwner.fromPrivateKeys(
      b_scan: ECPrivate(accountHD.derivePath(SCAN_PATH).privateKey),
      b_spend: ECPrivate(accountHD.derivePath(SPEND_PATH).privateKey),
      network: network,
    );

    if (silentAddresses.length == 0) {
      silentAddresses.add(BitcoinSilentPaymentAddressRecord(
        silentAddress.toString(),
        index: 0,
        isHidden: false,
        name: "",
        silentPaymentTweak: null,
        network: network,
        type: SilentPaymentsAddresType.p2sp,
      ));
      silentAddresses.add(BitcoinSilentPaymentAddressRecord(
        silentAddress!.toLabeledSilentPaymentAddress(0).toString(),
        index: 0,
        isHidden: true,
        name: "",
        silentPaymentTweak: BytesUtils.toHexString(silentAddress!.generateLabel(0)),
        network: network,
        type: SilentPaymentsAddresType.p2sp,
      ));
    }
  }

  final ObservableList<BitcoinSilentPaymentAddressRecord> silentAddresses;
  @observable
  SilentPaymentOwner? silentAddress;

  @observable
  String? activeSilentAddress;

  @override
  @computed
  String get address {
    if (addressPageType == SilentPaymentsAddresType.p2sp) {
      if (activeSilentAddress != null) {
        return activeSilentAddress!;
      }

      return silentAddress.toString();
    }

    return super.address;
  }

  @override
  set address(String addr) {
    if (addressPageType == SilentPaymentsAddresType.p2sp) {
      final selected = silentAddresses.firstWhere((addressRecord) => addressRecord.address == addr);

      if (selected.silentPaymentTweak != null && silentAddress != null) {
        activeSilentAddress =
            silentAddress!.toLabeledSilentPaymentAddress(selected.index).toString();
      } else {
        activeSilentAddress = silentAddress!.toString();
      }
      return;
    }

    super.address = addr;
  }

  int currentSilentAddressIndex;

  Map<String, String> get labels {
    final G = ECPublic.fromBytes(BigintUtils.toBytes(Curves.generatorSecp256k1.x, length: 32));
    final labels = <String, String>{};
    for (int i = 0; i < silentAddresses.length; i++) {
      final silentAddressRecord = silentAddresses[i];
      final silentPaymentTweak = silentAddressRecord.silentPaymentTweak;

      if (silentPaymentTweak != null &&
          SilentPaymentAddress.regex.hasMatch(silentAddressRecord.address)) {
        labels[G
            .tweakMul(BigintUtils.fromBytes(BytesUtils.fromHexString(silentPaymentTweak)))
            .toHex()] = silentPaymentTweak;
      }
    }
    return labels;
  }

  @action
  BaseBitcoinAddressRecord generateNewAddress({String label = ''}) {
    if (addressPageType == SilentPaymentsAddresType.p2sp && silentAddress != null) {
      final currentSilentAddressIndex = silentAddresses
              .where((addressRecord) => addressRecord.type != SegwitAddresType.p2tr)
              .length -
          1;

      this.currentSilentAddressIndex = currentSilentAddressIndex;

      final address = BitcoinSilentPaymentAddressRecord(
        silentAddress!.toLabeledSilentPaymentAddress(currentSilentAddressIndex).toString(),
        index: currentSilentAddressIndex,
        isHidden: false,
        name: label,
        silentPaymentTweak:
            BytesUtils.toHexString(silentAddress!.generateLabel(currentSilentAddressIndex)),
        network: network,
        type: SilentPaymentsAddresType.p2sp,
      );

      silentAddresses.add(address);
      updateAddressesByMatch();

      return address;
    } else {
      super.generateNewAddress(label: label);
    }
  }

  @override
  Future<void> updateAddressesInBox() async {
    super.updateAddressesInBox();

    silentAddresses.forEach((addressRecord) {
      if (addressRecord.type != SilentPaymentsAddresType.p2sp || addressRecord.isHidden) {
        return;
      }

      if (addressRecord.address != address) {
        addressesMap[addressRecord.address] = addressRecord.name.isEmpty
            ? "Silent Payments"
            : "Silent Payments - " + addressRecord.name;
      } else {
        addressesMap[address] = 'Active - Silent Payments';
      }
    });

    await saveAddressesInBox();
  }

  @action
  void updateAddress(String address, String label) {
    BaseBitcoinAddressRecord? foundAddress;
    _addresses.forEach((addressRecord) {
      if (addressRecord.address == address) {
        foundAddress = addressRecord;
      }
    });
    silentAddresses.forEach((addressRecord) {
      if (addressRecord.address == address) {
        foundAddress = addressRecord;
      }
    });

    if (foundAddress != null) {
      foundAddress!.setNewName(label);

      if (foundAddress is BitcoinAddressRecord) {
        final index = _addresses.indexOf(foundAddress);
        _addresses.remove(foundAddress);
        _addresses.insert(index, foundAddress as BitcoinAddressRecord);
      } else {
        final index = silentAddresses.indexOf(foundAddress as BitcoinSilentPaymentAddressRecord);
        silentAddresses.remove(foundAddress);
        silentAddresses.insert(index, foundAddress as BitcoinSilentPaymentAddressRecord);
      }
    }
  }

  @action
  void updateAddressesByMatch() {
    if (addressPageType == SilentPaymentsAddresType.p2sp) {
      addressesByReceiveType.clear();
      addressesByReceiveType.addAll(silentAddresses);
      return;
    }

    super.updateAddressesByMatch();
  }

  @action
  void addSilentAddresses(Iterable<BitcoinSilentPaymentAddressRecord> addresses) {
    final addressesSet = this.silentAddresses.toSet();
    addressesSet.addAll(addresses);
    this.silentAddresses.clear();
    this.silentAddresses.addAll(addressesSet);
    updateAddressesByMatch();
  }

  @action
  void deleteSilentPaymentAddress(String address) {
    final addressRecord = silentAddresses.firstWhere((addressRecord) =>
        addressRecord.type == SilentPaymentsAddresType.p2sp && addressRecord.address == address);

    silentAddresses.remove(addressRecord);
    updateAddressesByMatch();
  }
}
