import 'dart:typed_data';

import 'package:bech32/bech32.dart';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_bitcoin/electrum_wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_mweb/cw_mweb.dart';
import 'package:mobx/mobx.dart';

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
    topUpMweb(0);
  }

  final Bip32Slip10Secp256k1 mwebHd;
  bool mwebEnabled;

  List<int> get scanSecret => mwebHd.childKey(Bip32KeyIndex(0x80000000)).privateKey.privKey.raw;
  List<int> get spendPubkey =>
      mwebHd.childKey(Bip32KeyIndex(0x80000001)).publicKey.pubKey.compressed;

  List<String> mwebAddrs = [];

  Future<void> topUpMweb(int index) async {
    // generate up to index + 1000 addresses:
    while (mwebAddrs.length - index < 1000) {
      final length = mwebAddrs.length;
      final address = await CwMweb.address(
        Uint8List.fromList(scanSecret),
        Uint8List.fromList(spendPubkey),
        length,
      );
      mwebAddrs.add(address!);
    }
  }

  @override
  String getAddress({
    required int index,
    required Bip32Slip10Secp256k1 hd,
    BitcoinAddressType? addressType,
  }) {
    if (addressType == SegwitAddresType.mweb) {
      topUpMweb(index);
      return hd == sideHd ? mwebAddrs[0] : mwebAddrs[index + 1];
    }
    return generateP2WPKHAddress(hd: hd, index: index, network: network);
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
