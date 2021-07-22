import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:cake_wallet/bitcoin/bitcoin_mnemonic.dart';
import 'package:cake_wallet/bitcoin/utils.dart';
import 'package:cake_wallet/bitcoin/bitcoin_address_record.dart';
import 'package:cake_wallet/bitcoin/electrum_wallet_addresses.dart';
import 'package:cake_wallet/entities/wallet_info.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';

part 'litecoin_wallet_addresses.g.dart';

class LitecoinWalletAddresses = LitecoinWalletAddressesBase
    with _$LitecoinWalletAddresses;

abstract class LitecoinWalletAddressesBase extends ElectrumWalletAddresses
    with Store {
  LitecoinWalletAddressesBase(
      WalletInfo walletInfo,
      {@required List<BitcoinAddressRecord> initialAddresses,
        int accountIndex = 0,
        @required bitcoin.HDWallet hd,
        @required this.networkType,
        @required this.mnemonic})
      : super(
      walletInfo,
      initialAddresses: initialAddresses,
      accountIndex: accountIndex,
      hd: hd);

  bitcoin.NetworkType networkType;

  final String mnemonic;

  @override
  String getAddress({@required int index, @required bitcoin.HDWallet hd}) =>
      generateP2WPKHAddress(hd: hd, index: index, networkType: networkType);

  @override
  Future<void> generateAddresses() async {
    if (addresses.length < 33) {
      final addressesCount = 22 - addresses.length;
      await generateNewAddresses(addressesCount,
          hd: hd, startIndex: addresses.length);

      final changeRoot = bitcoin.HDWallet.fromSeed(
          mnemonicToSeedBytes(mnemonic),
          network: networkType)
          .derivePath("m/0'/1");

      await generateNewAddresses(11,
          startIndex: 0, hd: changeRoot, isHidden: true);
    }
  }
}