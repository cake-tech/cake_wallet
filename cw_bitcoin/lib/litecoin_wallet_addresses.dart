import 'dart:async';
import 'dart:typed_data';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_bitcoin/electrum_wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_mweb/cw_mweb.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';

part 'litecoin_wallet_addresses.g.dart';

class LitecoinWalletAddresses = LitecoinWalletAddressesBase with _$LitecoinWalletAddresses;

abstract class LitecoinWalletAddressesBase extends ElectrumWalletAddresses with Store {
  LitecoinWalletAddressesBase(
    WalletInfo walletInfo, {
    required super.mainHd,
    required super.sideHd,
    required super.network,
    required this.mwebHd,
    required this.mwebEnabled,
    super.initialAddresses,
    super.initialMwebAddresses,
    super.initialRegularAddressIndex,
    super.initialChangeAddressIndex,
  }) : super(walletInfo) {
    for (int i = 0; i < mwebAddresses.length; i++) {
      mwebAddrs.add(mwebAddresses[i].address);
    }
    print("initialized with ${mwebAddrs.length} mweb addresses");
  }

  final Bip32Slip10Secp256k1 mwebHd;
  bool mwebEnabled;
  int mwebTopUpIndex = 1000;
  List<String> mwebAddrs = [];

  List<int> get scanSecret => mwebHd.childKey(Bip32KeyIndex(0x80000000)).privateKey.privKey.raw;
  List<int> get spendPubkey =>
      mwebHd.childKey(Bip32KeyIndex(0x80000001)).publicKey.pubKey.compressed;

  @override
  Future<void> init() async {
    await initMwebAddresses();
    await super.init();
  }

  @computed
  @override
  List<BitcoinAddressRecord> get allAddresses {
    return List.from(super.allAddresses)..addAll(mwebAddresses);
  }

  Future<void> ensureMwebAddressUpToIndexExists(int index) async {
    Uint8List scan = Uint8List.fromList(scanSecret);
    Uint8List spend = Uint8List.fromList(spendPubkey);
    int count = 0;
    while (mwebAddrs.length <= (index + 1)) {
      final address = await CwMweb.address(scan, spend, mwebAddrs.length);
      mwebAddrs.add(address!);
      count++;
      // sleep for a bit to avoid making the main thread unresponsive:
      if (count > 50) {
        count = 0;
        await Future.delayed(Duration(milliseconds: 100));
      }
    }
  }

  Future<void> initMwebAddresses() async {
    if (mwebAddrs.length < 1000) {
      print("Generating MWEB addresses...");
      await ensureMwebAddressUpToIndexExists(1020);
      print("done generating MWEB addresses");
      List<BitcoinAddressRecord> addressRecords = mwebAddrs
          .asMap()
          .entries
          .map((e) => BitcoinAddressRecord(
                e.value,
                index: e.key,
                type: SegwitAddresType.mweb,
                network: network,
              ))
          .toList();
      addMwebAddresses(addressRecords);
      print("added ${addressRecords.length} mweb addresses");
      return;
    }
  }

  @override
  String getAddress({
    required int index,
    required Bip32Slip10Secp256k1 hd,
    BitcoinAddressType? addressType,
  }) {
    if (addressType == SegwitAddresType.mweb) {
      return hd == sideHd ? mwebAddrs[0] : mwebAddrs[index + 1];
    }
    return generateP2WPKHAddress(hd: hd, index: index, network: network);
  }

  @override
  Future<String> getAddressAsync({
    required int index,
    required Bip32Slip10Secp256k1 hd,
    BitcoinAddressType? addressType,
  }) async {
    if (addressType == SegwitAddresType.mweb) {
      await ensureMwebAddressUpToIndexExists(index);
    }
    return getAddress(index: index, hd: hd, addressType: addressType);
  }

  @action
  @override
  Future<String> getChangeAddress({List<BitcoinOutput>? outputs, UtxoDetails? utxoDetails}) async {
    // use regular change address on peg in, otherwise use mweb for change address:

    if (!mwebEnabled) {
      return super.getChangeAddress();
    }

    if (outputs != null && utxoDetails != null) {
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
      // TODO: this doesn't respect coin control because it doesn't know which available inputs are selected
      utxoDetails.availableInputs.forEach((element) {
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
      return mwebAddrs[0];
    }

    return super.getChangeAddress();
  }
}
