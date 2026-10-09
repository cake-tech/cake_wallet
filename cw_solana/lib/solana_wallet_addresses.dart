import "package:cw_core/crypto_currency.dart";
import 'package:cw_core/payment_uris.dart';
import "package:cw_core/receive_page_option.dart";
import "package:cw_core/spl_token.dart";
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:mobx/mobx.dart';

part 'solana_wallet_addresses.g.dart';

class SolanaWalletAddresses = SolanaWalletAddressesBase with _$SolanaWalletAddresses;

abstract class SolanaWalletAddressesBase extends WalletAddresses with Store {
  SolanaWalletAddressesBase(WalletInfo walletInfo)
      : address = '',
        super(walletInfo);

  @override
  String address;

  @override
  String get primaryAddress => address;

  @override
  Future<void> init() async {
    address = walletInfo.address;
    await updateAddressesInBox();
  }

  @override
  Future<void> updateAddressesInBox() async {
    try {
      addressesMap.clear();
      addressesMap[address] = '';
      await saveAddressesInBox();
    } catch (e) {
      printV(e.toString());
    }
  }

  @override
  PaymentURI getPaymentUri(String amount) => SolanaURI(address: address, amount: amount);

  @override
  PaymentURI paymentUriFor(ReceivePageOption type, String amount, {CryptoCurrency? token}) =>
      SolanaURI(
        address: address,
        amount: amount,
        contractAddress: token is SPLToken ? token.mintAddress : null,
      );
}
