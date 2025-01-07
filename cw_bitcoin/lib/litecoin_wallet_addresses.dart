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
    required super.network,
    required super.isHardwareWallet,
    required this.mwebHd,
    required this.mwebEnabled,
    required super.hdWallets,
    super.initialAddresses,
    List<LitecoinMWEBAddressRecord>? initialMwebAddresses,
  })  : mwebAddresses =
            ObservableList<LitecoinMWEBAddressRecord>.of((initialMwebAddresses ?? []).toSet()),
        super(walletInfo) {
    for (int i = 0; i < mwebAddresses.length; i++) {
      mwebAddrs.add(mwebAddresses[i].address);
    }
    printV("initialized with ${mwebAddrs.length} mweb addresses");
  }

  final ObservableList<LitecoinMWEBAddressRecord> mwebAddresses;

  final Bip32Slip10Secp256k1? mwebHd;
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

    await generateInitialAddresses(type: SegwitAddresType.p2wpkh);
    if ((Platform.isAndroid || Platform.isIOS) && !isHardwareWallet) {
      await generateInitialAddresses(type: SegwitAddresType.mweb);
    }

    await super.init();
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
    if (addressType == SegwitAddresType.mweb) {
      return MwebAddress.fromAddress(address: mwebAddrs[0], network: network);
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
    if (addressType == SegwitAddresType.mweb) {
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
  BaseBitcoinAddressRecord getChangeAddress({
    List<BitcoinUnspent>? inputs,
    List<BitcoinOutput>? outputs,
    bool isPegIn = false,
  }) {
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
      // TODO:
      // await ensureMwebAddressUpToIndexExists(1);
      return LitecoinMWEBAddressRecord(mwebAddrs[0], index: 0);
    }

    return super.getChangeAddress();
  }

  @override
  String get addressForExchange {
    // don't use mweb addresses for exchange refund address:
    final addresses = receiveAddresses
        .where((element) => element.type == SegwitAddresType.p2wpkh && !element.isUsed);
    return addresses.first.address;
  }

  @override
  Future<void> updateAddressesInBox() async {
    super.updateAddressesInBox();

    final lastP2wpkh = allAddresses
        .where(
            (addressRecord) => isUnusedReceiveAddressByType(addressRecord, SegwitAddresType.p2wpkh))
        .toList()
        .last;
    if (lastP2wpkh.address != address) {
      addressesMap[lastP2wpkh.address] = 'P2WPKH';
    } else {
      addressesMap[address] = 'Active - P2WPKH';
    }

    final lastMweb = allAddresses.firstWhere(
        (addressRecord) => isUnusedReceiveAddressByType(addressRecord, SegwitAddresType.mweb));
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
    updateAddressesOnReceiveScreen();
  }
}
