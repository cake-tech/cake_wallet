import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';

// class NanoNewWalletCredentials extends WalletCredentials {
//   NanoNewWalletCredentials({required String name, WalletInfo? walletInfo})
//       : super(name: name, walletInfo: walletInfo);
// }

// class NanoRestoreWalletFromSeedCredentials extends WalletCredentials {
//   NanoRestoreWalletFromSeedCredentials(
//       {required String name,
//       required String password,
//       required this.mnemonic,
//       WalletInfo? walletInfo})
//       : super(name: name, password: password, walletInfo: walletInfo);

//   final String mnemonic;
// }

// class NanoRestoreWalletFromWIFCredentials extends WalletCredentials {
//   NanoRestoreWalletFromWIFCredentials(
//       {required String name, required String password, required this.wif, WalletInfo? walletInfo})
//       : super(name: name, password: password, walletInfo: walletInfo);

//   final String wif;
// }


// class NanoNewWalletCredentials extends WalletCredentials {
//   NanoNewWalletCredentials({required String name, required this.language, String? password})
//       : super(name: name, password: password);

//   final String language;
// }

// class NanoRestoreWalletFromSeedCredentials extends WalletCredentials {
//   NanoRestoreWalletFromSeedCredentials(
//       {required String name, required this.mnemonic, int height = 0, String? password})
//       : super(name: name, password: password, height: height);

//   final String mnemonic;
// }

// class NanoWalletLoadingException implements Exception {
//   @override
//   String toString() => 'Failure to load the wallet.';
// }
