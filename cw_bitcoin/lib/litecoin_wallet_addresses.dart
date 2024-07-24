import 'package:convert/convert.dart';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_bitcoin/electrum_wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_mweb/cw_mweb.dart';
import 'package:cw_mweb/mwebd.pb.dart';
import 'package:mobx/mobx.dart';

part 'litecoin_wallet_addresses.g.dart';

class LitecoinWalletAddresses = LitecoinWalletAddressesBase with _$LitecoinWalletAddresses;

abstract class LitecoinWalletAddressesBase extends ElectrumWalletAddresses with Store {
  LitecoinWalletAddressesBase(
    WalletInfo walletInfo, {
    required super.mainHd,
    required super.sideHd,
    required this.mwebHd,
    required super.network,
    super.initialAddresses,
    super.initialRegularAddressIndex,
    super.initialChangeAddressIndex,
  }) : super(walletInfo) {
    topUpMweb(0);
  }

  final HDWallet mwebHd;
  List<String> mwebAddrs = [];

  Future<void> topUpMweb(int index) async {
    while (mwebAddrs.length - index < 1000) {
      final length = mwebAddrs.length;
      final scanSecret = mwebHd.derive(0x80000000).privKey!;
      final spendPubkey = mwebHd.derive(0x80000001).pubKey!;
      final stub = await CwMweb.stub();
      final resp = await stub.addresses(AddressRequest(
        fromIndex: length,
        toIndex: index + 1000,
        scanSecret: hex.decode(scanSecret),
        spendPubkey: hex.decode(spendPubkey),
      ));
      if (mwebAddrs.length == length) {
        mwebAddrs.addAll(resp.address);
      }
    }
  }

  @override
  String getAddress({required int index, required HDWallet hd, BitcoinAddressType? addressType}) {
    if (addressType == SegwitAddresType.mweb) {
      topUpMweb(index);
      return hd == sideHd ? mwebAddrs[0] : mwebAddrs[index + 1];
    }
    return generateP2WPKHAddress(hd: hd, index: index, network: network);
  }

  @override
  Future<String> getAddressAsync(
      {required int index, required HDWallet hd, BitcoinAddressType? addressType}) async {
    if (addressType == SegwitAddresType.mweb) {
      await topUpMweb(index);
    }
    return getAddress(index: index, hd: hd, addressType: addressType);
  }

  @action
  @override
  Future<String> getChangeAddress() async {
    // super.getChangeAddress();
    // updateChangeAddresses();
    // print("getChangeAddress @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
    // this means all change addresses used will be mweb addresses!:
    await topUpMweb(0);
    return mwebAddrs[0];
  }
}
