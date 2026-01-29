import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/decred/decred.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/wownero/wownero.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';

Future<void> createNewAddress(WalletBase wallet, String label) async {
  final isElectrum = wallet.type == WalletType.bitcoin ||
      wallet.type == WalletType.bitcoinCash ||
      wallet.type == WalletType.litecoin ||
      wallet.type == WalletType.dogecoin;

  if (isElectrum) {
    await bitcoin!.generateNewAddress(wallet, label);
    await wallet.save();
  }

  if (wallet.type == WalletType.decred) {
    await decred!.generateNewAddress(wallet, label);
    await wallet.save();
  }

  if (wallet.type == WalletType.monero) {
    await monero!
        .getSubaddressList(wallet)
        .addSubaddress(wallet, accountIndex: monero!.getCurrentAccount(wallet).id, label: label);
    final addr = await monero!
        .getSubaddressList(wallet)
        .subaddresses
        .first
        .address; // first because the order is reversed
    wallet.walletAddresses.manualAddresses.add(addr);
    await wallet.save();
  }

  if (wallet.type == WalletType.wownero) {
    await wownero!
        .getSubaddressList(wallet)
        .addSubaddress(wallet, accountIndex: wownero!.getCurrentAccount(wallet).id, label: label);
    final addr = await wownero!
        .getSubaddressList(wallet)
        .subaddresses
        .first
        .address; // first because the order is reversed
    wallet.walletAddresses.manualAddresses.add(addr);
    await wallet.save();
  }
}
