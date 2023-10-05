import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';

class NanoNewWalletCredentials extends WalletCredentials {
  NanoNewWalletCredentials({required String name, String? password})
      : super(name: name, password: password);
}

class NanoRestoreWalletFromSeedCredentials extends WalletCredentials {
  NanoRestoreWalletFromSeedCredentials({
    required String name,
    required this.mnemonic,
    int height = 0,
    String? password,
    DerivationType? derivationType,
  }) : super(
          name: name,
          password: password,
          height: height,
          derivationType: derivationType,
        );

  final String mnemonic;
}

class NanoWalletLoadingException implements Exception {
  @override
  String toString() => 'Failure to load the wallet.';
}

class NanoRestoreWalletFromKeysCredentials extends WalletCredentials {
  NanoRestoreWalletFromKeysCredentials({
    required String name,
    required String password,
    required this.seedKey,
    this.derivationType,
  }) : super(name: name, password: password);

  final String seedKey;
  final DerivationType? derivationType;
}