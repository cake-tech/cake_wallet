import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:bitcoin_flutter/bitcoin_flutter.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:mobx/mobx.dart';

part 'bitcoin_cash_wallet_addresses.g.dart';

class BitcoinCashWalletAddresses = BitcoinCashWalletAddressesBase with _$BitcoinCashWalletAddresses;

abstract class BitcoinCashWalletAddressesBase extends WalletAddresses with Store {
  BitcoinCashWalletAddressesBase(WalletInfo walletInfo, {required this.mainHd}) : super(walletInfo);

  final bitcoin.HDWallet mainHd;

  @override
  String get address {
    // Derive the P2WPKH address from the mainHd at index 0 (or any desired index)
    int index = 0; // You can change the index to get different addresses.
    String p2wpkhAddress =
    P2WPKH(data: PaymentData(pubkey: mainHd.derive(index).publicKey), network: bitcoin.bitcoin)
        .data
        .address!;
    print(p2wpkhAddress);

    return p2wpkhAddress;
  }

  @override
  set address(String addr) => null;

  @override
  Future<void> init() async {
   UnimplementedError();
  }

  @override
  Future<void> updateAddressesInBox() async {
    UnimplementedError();
  }

  @override
  Future<void> saveAddressesInBox() async {
    UnimplementedError();
  }



}
