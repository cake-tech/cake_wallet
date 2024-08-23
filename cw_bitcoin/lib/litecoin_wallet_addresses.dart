import 'package:convert/convert.dart';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
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
    required super.network,
    required this.mwebHd,
    required this.mwebEnabled,
    super.initialAddresses,
    super.initialRegularAddressIndex,
    super.initialChangeAddressIndex,
  }) : super(walletInfo) {
    if (mwebEnabled) {
      topUpMweb(0);
    }
  }

  final Bip32Slip10Secp256k1 mwebHd;
  bool mwebEnabled;

  List<int> get scanSecret => mwebHd.childKey(Bip32KeyIndex(0x80000000)).privateKey.privKey.raw;
  List<int> get spendPubkey =>
      mwebHd.childKey(Bip32KeyIndex(0x80000001)).publicKey.pubKey.compressed;

  List<String> mwebAddrs = [];

  Future<void> topUpMweb(int index) async {
    while (mwebAddrs.length - index < 1000) {
      final length = mwebAddrs.length;
      final stub = await CwMweb.stub();
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
  Future<String> getChangeAddress() async {
    if (mwebEnabled) {
      await topUpMweb(0);
      return mwebAddrs[0];
    }
    return super.getChangeAddress();
  }
}
