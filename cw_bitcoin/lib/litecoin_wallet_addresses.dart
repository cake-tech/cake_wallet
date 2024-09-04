import 'package:bech32/bech32.dart';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/bech32/bech32_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
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

// class Keychain {
//   // ECPrivate scan;
//   // ECPrivate? spend;
//   ECPrivate scan;
//   ECPrivate? spend;
//   ECPublic? spendPubKey;

//   Keychain({required this.scan, this.spend, this.spendPubKey}) {
//     if (this.spend != null) {
//       spendPubKey = this.spend!.getPublic();
//     }
//   }

//   static const HashTagAddress = 'A';

//   ECPrivate mi(int index) {
//     final input = BytesBuilder();

//     // Write HashTagAddress to the input
//     input.addByte(HashTagAddress.codeUnitAt(0));

//     // Write index to the input in little endian
//     final indexBytes = Uint8List(4);
//     final byteData = ByteData.view(indexBytes.buffer);
//     byteData.setUint32(0, index, Endian.little);
//     input.add(indexBytes);

//     // Write scan to the input
//     input.add(scan.prive.raw);

//     // Hash the input using Blake3 with a length of 32 bytes
//     final hash = rHash.hashString(HashType.blake3(length: 32), input.toString());

//     // Return the hash digest
//     var res = Uint8List.fromList(hash);
//     return ECPrivate.fromBytes(res);
//   }

//   Keychain address(int index) {

//     final miPub = this.mi(index).getPublic();
//     final Bi = spendPubKey!.pubkeyAdd(miPub);
//     // final Ai = Bi.pubkeyMult(ECPublic.fromBytes(scan.toBytes()));
//     final Ai = Bi.tweakMul(scan.toBigInt());

//     // final miPubKey = ECCurve_secp256k1().G * BigInt.parse(hex.encode(mi), radix: 16);
//     // final Bi = spendPubKey + miPubKey;
//     // return Uint8List.fromList(Ai.getEncoded(compressed: true) + Bi.getEncoded(compressed: true));
//     final AiPriv = ECPrivate.fromBytes(Ai.toBytes());
//     final BiPriv = ECPrivate.fromBytes(Bi.toBytes());

//     return Keychain(scan: AiPriv, spend: BiPriv);
//   }

//   String addressString(int index) {
//     final address = this.address(index);
//     List<int> bytes = [];
//     bytes.addAll(address.scan.toBytes());
//     bytes.addAll(address.spend!.toBytes());
//     return encodeMwebAddress(bytes);
//   }

//   // Uint8List spendKey(int index) {
//   //   final mi = this.mi(index);
//   //   final spendKey = spend + ECCurve_secp256k1().G * BigInt.parse(hex.encode(mi), radix: 16);
//   //   return spendKey.getEncoded(compressed: true);
//   // }

//   String encodeMwebAddress(List<int> scriptPubKey) {
//     return bech32.encode(Bech32("ltcmweb", scriptPubKey));
//   }
// }

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
    while (oldMwebAddrs.length - index < 1000) {
      final length = oldMwebAddrs.length;
      final resp = await stub.addresses(AddressRequest(
        fromIndex: length,
        toIndex: index + 1000,
        scanSecret: scanSecret,
        spendPubkey: spendPubkey,
      ));
      if (oldMwebAddrs.length == length) {
        oldMwebAddrs.addAll(resp.address);
      }
    }

    // Keychain k = Keychain(scan: ECPrivate.fromBytes(scanSecret), spendPubKey: ECPublic.fromBytes(spendPubkey),);

    for (int i = 0; i < 10; i++) {
      // final address = k.addressString(i + 1000);
      final addressHex =
          await CwMweb.address(hex.encode(scanSecret), hex.encode(spendPubkey), index);
      // print(addressHex);
      // print(hex.decode(addressHex!).length);
      // return;
      final address = encodeMwebAddress(hex.decode(addressHex!));
      mwebAddrs.add(address);
    }
    print("old function: ${oldMwebAddrs.first} new function!: ${mwebAddrs.first}");
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
