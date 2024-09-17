import 'package:cw_core/hardware/hardware_account_data.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';

class BitcoinCashNewWalletCredentials extends WalletCredentials {
  BitcoinCashNewWalletCredentials(
      {required String name, WalletInfo? walletInfo, String? password, String? passphrase})
      : super(name: name, walletInfo: walletInfo, password: password, passphrase: passphrase);
}

class BitcoinCashRestoreWalletFromSeedCredentials extends WalletCredentials {
  BitcoinCashRestoreWalletFromSeedCredentials({
    required String name,
    required String password,
    required this.mnemonic,
    WalletInfo? walletInfo,
    String? passphrase,
  }) : super(name: name, password: password, walletInfo: walletInfo, passphrase: passphrase);

  final String mnemonic;
}

class BitcoinCashRestoreWalletFromWIFCredentials extends WalletCredentials {
  BitcoinCashRestoreWalletFromWIFCredentials(
      {required String name, required String password, required this.wif, WalletInfo? walletInfo})
      : super(name: name, password: password, walletInfo: walletInfo);

  final String wif;
}

class BitcoinCashRestoreWalletFromHardware extends WalletCredentials {
  BitcoinCashRestoreWalletFromHardware({
    required String name,
    required this.hwAccountData,
    WalletInfo? walletInfo,
  }) : super(name: name, walletInfo: walletInfo);

  final HardwareAccountData hwAccountData;
}
