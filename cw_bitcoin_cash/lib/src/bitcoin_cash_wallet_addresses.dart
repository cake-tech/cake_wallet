import 'package:bitbox/bitbox.dart' as Bitbox;
import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:bitcoin_flutter/bitcoin_flutter.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:mobx/mobx.dart';
import 'package:bip32/bip32.dart';

part 'bitcoin_cash_wallet_addresses.g.dart';

class BitcoinCashWalletAddresses = BitcoinCashWalletAddressesBase with _$BitcoinCashWalletAddresses;

abstract class BitcoinCashWalletAddressesBase extends WalletAddresses with Store {
  BitcoinCashWalletAddressesBase(WalletInfo walletInfo, {required this.mainHd}) : super(walletInfo);

  final BIP32 mainHd;

  @override
  String get address {
    final p2pkh =  P2PKH(
        data:  PaymentData(pubkey: mainHd.publicKey),
        network: bitcoin.NetworkType(
            messagePrefix: '\x18Bitcoin Signed Message:\n',
            bech32: 'bc',
            bip32: bitcoin.Bip32Type(
              public: 0x0488b21e,
              private: 0x0488ade4,
            ),
            pubKeyHash: 0x00,
            scriptHash: 0x05,
            wif: 0x80
        )
    );
    String address = p2pkh.data!.address!;
    return Bitbox.Address.toCashAddress(address);
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
