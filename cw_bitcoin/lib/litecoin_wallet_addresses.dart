import 'dart:async';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_unspent.dart';
import 'package:cw_bitcoin/electrum_wallet_addresses.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_mweb/cw_mweb.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';

part 'litecoin_wallet_addresses.g.dart';

class LitecoinWalletAddresses = LitecoinWalletAddressesBase with _$LitecoinWalletAddresses;

abstract class LitecoinWalletAddressesBase extends ElectrumWalletAddresses with Store {
  LitecoinWalletAddressesBase(
    WalletInfo walletInfo, {
    required super.hdWallets,
    required super.network,
    required super.isHardwareWallet,
    required this.mwebEnabled,
    super.initialAddresses,
    List<LitecoinMWEBAddressRecord>? initialMwebAddresses,
  })  : mwebAddresses =
            ObservableList<LitecoinMWEBAddressRecord>.of((initialMwebAddresses ?? []).toSet()),
        super(walletInfo) {
    mwebHd = hdWallet.derivePath("m/1000'") as Bip32Slip10Secp256k1;

    for (int i = 0; i < mwebAddresses.length; i++) {
      mwebAddrs.add(mwebAddresses[i].address);
    }
    printV("initialized with ${mwebAddrs.length} mweb addresses");
  }

  final ObservableList<LitecoinMWEBAddressRecord> mwebAddresses;

  late final Bip32Slip10Secp256k1? mwebHd;
  bool mwebEnabled;
  int mwebTopUpIndex = 1000;
  List<String> mwebAddrs = [];
  bool generating = false;

  List<int> get scanSecret => mwebHd!.childKey(Bip32KeyIndex(0x80000000)).privateKey.privKey.raw;
  List<int> get spendPubkey =>
      mwebHd!.childKey(Bip32KeyIndex(0x80000001)).publicKey.pubKey.compressed;

  @override
  Future<void> init() async {
    if (!super.isHardwareWallet) await initMwebAddresses();

    await generateInitialAddresses(type: SegwitAddressType.p2wpkh);
    if ((Platform.isAndroid || Platform.isIOS) && !isHardwareWallet) {
      await generateInitialAddresses(type: SegwitAddressType.mweb);
    }

    await super.init();
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

    final startIndex = getAddressesByType(addressType, isChange)
        .where((addr) => (addr as BitcoinAddressRecord).cwDerivationType == derivationType)
        .length;

    final mwebAddresses = <LitecoinMWEBAddressRecord>[];
    final newAddresses = <BitcoinAddressRecord>[];

    for (var i = startIndex; i < count + startIndex; i++) {
      final addressString = await getAddressAsync(
        derivationType: derivationType,
        isChange: isChange,
        index: i,
        addressType: addressType,
        derivationInfo: derivationInfo,
      );

      if (addressType == SegwitAddressType.mweb) {
        final address = LitecoinMWEBAddressRecord(addressString, index: i);
        mwebAddresses.add(address);
      } else {
        final address = BitcoinAddressRecord(
          addressString,
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
    }

    addAddresses(newAddresses);
    addMwebAddresses(mwebAddresses);
    return newAddresses;
  }

  Future<void> ensureMwebAddressUpToIndexExists(int index) async {
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      return null;
    }

    Uint8List scan = Uint8List.fromList(scanSecret);
    Uint8List spend = Uint8List.fromList(spendPubkey);

    if (index < mwebAddresses.length && index < mwebAddrs.length) {
      return;
    }

    while (generating) {
      printV("generating.....");
      // this function was called multiple times in multiple places:
      await Future.delayed(const Duration(milliseconds: 100));
    }

    printV("Generating MWEB addresses up to index $index");
    generating = true;
    try {
      while (mwebAddrs.length <= (index + 1)) {
        final addresses =
            await CwMweb.addresses(scan, spend, mwebAddrs.length, mwebAddrs.length + 50);
        printV("generated up to index ${mwebAddrs.length}");
        // sleep for a bit to avoid making the main thread unresponsive:
        await Future.delayed(Duration(milliseconds: 200));
        mwebAddrs.addAll(addresses!);
      }
    } catch (_) {}
    generating = false;
    printV("Done generating MWEB addresses len: ${mwebAddrs.length}");

    // ensure mweb addresses are up to date:
    // This is the Case if the Litecoin Wallet is a hardware Wallet
    if (mwebHd == null) return;

    if (mwebAddresses.length < mwebAddrs.length) {
      List<LitecoinMWEBAddressRecord> addressRecords = mwebAddrs
          .asMap()
          .entries
          .map(
            (e) => LitecoinMWEBAddressRecord(e.value, index: e.key),
          )
          .toList();
      addMwebAddresses(addressRecords);
      printV("set ${addressRecords.length} mweb addresses");
    }
  }

  Future<void> initMwebAddresses() async {
    if (mwebAddrs.length < 1000) {
      await ensureMwebAddressUpToIndexExists(20);
      return;
    }
  }

  @override
  BitcoinBaseAddress generateAddress({
    required CWBitcoinDerivationType derivationType,
    required bool isChange,
    required int index,
    required BitcoinAddressType addressType,
    required BitcoinDerivationInfo derivationInfo,
  }) {
    if (addressType == SegwitAddressType.mweb) {
      return MwebAddress.fromAddress(address: mwebAddrs[isChange ? index + 1 : 0]);
    }

    return P2wpkhAddress.fromDerivation(
      bip32: hdWallets[derivationType]!,
      derivationInfo: derivationInfo,
      isChange: isChange,
      index: index,
    );
  }

  @override
  Future<String> getAddressAsync({
    required CWBitcoinDerivationType derivationType,
    required bool isChange,
    required int index,
    required BitcoinAddressType addressType,
    required BitcoinDerivationInfo derivationInfo,
  }) async {
    if (addressType == SegwitAddressType.mweb) {
      await ensureMwebAddressUpToIndexExists(index);
    }

    return getAddress(
      derivationType: derivationType,
      isChange: isChange,
      index: index,
      addressType: addressType,
      derivationInfo: derivationInfo,
    );
  }

  @action
  @override
  Future<BaseBitcoinAddressRecord> getChangeAddress({
    List<BitcoinUnspent>? inputs,
    List<BitcoinOutput>? outputs,
    bool isPegIn = false,
  }) async {
    // use regular change address on peg in, otherwise use mweb for change address:

    if (!mwebEnabled || isPegIn) {
      return super.getChangeAddress();
    }

    if (inputs != null && outputs != null) {
      // check if this is a PEGIN:
      bool outputsToMweb = false;
      bool comesFromMweb = false;

      for (var i = 0; i < outputs.length; i++) {
        // TODO: probably not the best way to tell if this is an mweb address
        // (but it doesn't contain the "mweb" text at this stage)
        if (outputs[i].address.toAddress(network).length > 110) {
          outputsToMweb = true;
        }
      }

      inputs.forEach((element) {
        if (!element.isSending || element.isFrozen) {
          return;
        }
        if (element.address.contains("mweb")) {
          comesFromMweb = true;
        }
      });

      bool isPegIn = !comesFromMweb && outputsToMweb;

      if (isPegIn && mwebEnabled) {
        return super.getChangeAddress();
      }

      // use regular change address if it's not an mweb tx:
      if (!comesFromMweb && !outputsToMweb) {
        return super.getChangeAddress();
      }
    }

    if (mwebEnabled) {
      await ensureMwebAddressUpToIndexExists(1);
      return LitecoinMWEBAddressRecord(mwebAddrs[0], index: 0);
    }

    return super.getChangeAddress();
  }

  @override
  String get addressForExchange {
    // don't use mweb addresses for exchange refund address:
    final addresses = selectedReceiveAddresses
        .where((element) => element.type == SegwitAddressType.p2wpkh && !element.isUsed);
    return addresses.first.address;
  }

  @override
  Future<void> updateAddressesInBox() async {
    super.updateAddressesInBox();

    final lastP2wpkh =
        allAddresses.where((addressRecord) => isUnusedReceiveAddress(addressRecord)).toList().last;
    if (lastP2wpkh.address != address) {
      addressesMap[lastP2wpkh.address] = 'P2WPKH';
    } else {
      addressesMap[address] = 'Active - P2WPKH';
    }

    final lastMweb = mwebAddresses.firstWhere(
      (addressRecord) => isUnusedReceiveAddress(addressRecord),
    );
    if (lastMweb.address != address) {
      addressesMap[lastMweb.address] = 'MWEB';
    } else {
      addressesMap[address] = 'Active - MWEB';
    }

    await saveAddressesInBox();
  }

  @override
  @action
  void updateAddress(String address, String label) {
    BaseBitcoinAddressRecord? foundAddress;
    allAddresses.forEach((addressRecord) {
      if (addressRecord.address == address) {
        foundAddress = addressRecord;
      }
    });
    mwebAddresses.forEach((addressRecord) {
      if (addressRecord.address == address) {
        foundAddress = addressRecord;
      }
    });

    if (foundAddress != null) {
      foundAddress!.setNewName(label);

      if (foundAddress is BitcoinAddressRecord) {
        final index = allAddresses.indexOf(foundAddress! as BitcoinAddressRecord);
        allAddresses.remove(foundAddress);
        allAddresses.insert(index, foundAddress as BitcoinAddressRecord);
      }
    }
  }

  @action
  void addMwebAddresses(Iterable<LitecoinMWEBAddressRecord> addresses) {
    final addressesSet = this.mwebAddresses.toSet();
    addressesSet.addAll(addresses);
    this.mwebAddresses.clear();
    this.mwebAddresses.addAll(addressesSet);
    updateAddressesByType();
  }

  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['mwebAddresses'] = mwebAddresses.map((address) => address.toJSON()).toList();
    // json['mwebAddressIndex'] =
    return json;
  }

  static Map<String, dynamic> fromSnapshot(Map<dynamic, dynamic> data) {
    final electrumSnapshot = ElectrumWalletAddressesBase.fromSnapshot(data);

    final mwebAddresses = data['mweb_addresses'] as List? ??
        <Object>[].map((e) => LitecoinMWEBAddressRecord.fromJSON(e as String)).toList();

    // var mwebAddressIndex = 0;

    // try {
    //   mwebAddressIndex = int.parse(data['silent_address_index'] as String? ?? '0');
    // } catch (_) {}

    return {
      'allAddresses': electrumSnapshot["addresses"],
      'addressPageType': data['address_page_type'] as String?,
      'receiveAddressIndexByType': electrumSnapshot["receiveAddressIndexByType"],
      'changeAddressIndexByType': electrumSnapshot["changeAddressIndexByType"],
      'mwebAddresses': mwebAddresses,
    };
  }

  static LitecoinWalletAddressesBase fromJson(
    Map<String, dynamic> json,
    WalletInfo walletInfo, {
    required Map<CWBitcoinDerivationType, Bip32Slip10Secp256k1> hdWallets,
    required BasedUtxoNetwork network,
    required bool isHardwareWallet,
    List<BitcoinAddressRecord>? initialAddresses,
    List<LitecoinMWEBAddressRecord>? initialMwebAddresses,
  }) {
    initialAddresses ??= (json['allAddresses'] as List)
        .map((record) => BitcoinAddressRecord.fromJSON(record as String))
        .toList();

    initialMwebAddresses ??= (json['mwebAddresses'] as List)
        .map(
          (address) => LitecoinMWEBAddressRecord.fromJSON(address as String),
        )
        .toList();

    return LitecoinWalletAddresses(
      walletInfo,
      hdWallets: hdWallets,
      network: network,
      isHardwareWallet: isHardwareWallet,
      initialAddresses: initialAddresses,
      initialMwebAddresses: initialMwebAddresses,
      mwebEnabled: true, // TODO
    );
  }
}
