import 'package:bech32/bech32.dart';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/bech32/bech32_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_bitcoin/electrum_wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_mweb/cw_mweb.dart';
import 'package:cw_mweb/mwebd.pb.dart';
import 'package:mobx/mobx.dart';

// import 'dart:typed_data';
// import 'package:bech32/bech32.dart';
// import 'package:r_crypto/r_crypto.dart';

part 'litecoin_wallet_addresses.g.dart';

String encodeMwebAddress(List<int> scriptPubKey) {
  return bech32.encode(Bech32("ltcmweb1", scriptPubKey), 250);
}

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
    super.initialRegularAddressIndex,
    super.initialChangeAddressIndex,
  }) : super(walletInfo) {
    if (mwebEnabled) {
      // give the server a few seconds to start up before trying to get the addresses:
      Future.delayed(const Duration(seconds: 5), () async {
        await topUpMweb(0);
      });
    }
  }

  final Bip32Slip10Secp256k1 mwebHd;
  bool mwebEnabled;

  List<int> get scanSecret => mwebHd.childKey(Bip32KeyIndex(0x80000000)).privateKey.privKey.raw;
  List<int> get spendPubkey =>
      mwebHd.childKey(Bip32KeyIndex(0x80000001)).publicKey.pubKey.compressed;

  List<String> mwebAddrs = [];
  List<String> oldMwebAddrs = [];

  Future<void> topUpMweb(int index) async {
    final stub = await CwMweb.stub();
    while (mwebAddrs.length - index < 1000) {
      final length = mwebAddrs.length;
      final resp = await stub.addresses(AddressRequest(
        fromIndex: length,
        toIndex: index + 1000,
        scanSecret: scanSecret,
        spendPubkey: spendPubkey,
      ));
      if (mwebAddrs.length == length) {
        mwebAddrs.addAll(resp.address);
      }
    }

    // for (int i = 0; i < 10; i++) {
    //   final address = await CwMweb.address(
    //     hex.encode(scanSecret),
    //     hex.encode(spendPubkey),
    //     index + 1000,
    //   );
    //   mwebAddrs.add(address!);
    // }
    // print("old function: ${oldMwebAddrs.first} new function!: ${mwebAddrs.first}");
  }

  @override
  String getAddress({
    required int index,
    required Bip32Slip10Secp256k1 hd,
    BitcoinAddressType? addressType,
  }) {
    if (addressType == SegwitAddresType.mweb && mwebEnabled) {
      topUpMweb(index);
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
    // if mweb isn't enabled we'll just return the regular address type which does effectively nothing
    // sort of a hack but easier than trying to pull the mweb setting into the electrum_wallet_addresses initialization code
    // (we want to avoid initializing the mweb.stub() if it's not enabled or we'd be starting the whole server for no reason and it's slow)
    // TODO: find a way to do address generation without starting the whole mweb server
    if (addressType == SegwitAddresType.mweb && mwebEnabled) {
      await topUpMweb(index);
    }
    return getAddress(index: index, hd: hd, addressType: addressType);
  }

  @action
  @override
  Future<String> getChangeAddress({List<BitcoinOutput>? outputs, UtxoDetails? utxoDetails}) async {
    // use regular change address on peg in, otherwise use mweb for change address:

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
      utxoDetails.availableInputs.forEach((element) {
        if (element.address.contains("mweb")) {
          comesFromMweb = true;
        }
      });

      bool isPegIn = !comesFromMweb && outputsToMweb;
      if (isPegIn && mwebEnabled) {
        return super.getChangeAddress();
      }
    }

    if (mwebEnabled) {
      await topUpMweb(0);
      return mwebAddrs[0];
    }

    return super.getChangeAddress();
  }
}
