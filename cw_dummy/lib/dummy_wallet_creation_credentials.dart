import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';

class DummyNewWalletCredentials extends WalletCredentials {
  DummyNewWalletCredentials({required String name, WalletInfo? walletInfo})
      : super(name: name, walletInfo: walletInfo);
}

class DummyRestoreWalletFromSeedCredentials extends WalletCredentials {
  DummyRestoreWalletFromSeedCredentials({required String name, WalletInfo? walletInfo})
      : super(name: name, walletInfo: walletInfo);
}

class DummyRestoreWalletFromKeyCredentials extends WalletCredentials {
  DummyRestoreWalletFromKeyCredentials({required String name, WalletInfo? walletInfo})
      : super(name: name, walletInfo: walletInfo);
}

