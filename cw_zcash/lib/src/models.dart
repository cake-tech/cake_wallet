import 'package:cw_core/hardware/hardware_wallet_service.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';

class ZcashNewWalletCredentials extends WalletCredentials {
  ZcashNewWalletCredentials({
    required final String name,
    final String? password,
    required final String? passphrase,
    final String? mnemonic,
    final int? seedPhraseLength,
    this.network = 0,
  }) : super(
         name: name,
         password: password,
         passphrase: passphrase,
         seedPhraseLength: seedPhraseLength,
       ) {
    this.mnemonic = mnemonic;
  }

  String? mnemonic;
  int network;
}

class ZcashFromSeedWalletCredentials extends WalletCredentials {
  ZcashFromSeedWalletCredentials({
    required final String name,
    final String? password,
    required final String? passphrase,
    required this.seed,
    required super.height,
    this.network = 0,
  }) : super(name: name, password: password, passphrase: passphrase);
  final String? seed;
  int network;
}

class ZcashFromKeysWalletCredentials extends WalletCredentials {
  ZcashFromKeysWalletCredentials({
    required final String name,
    final String? password,
    required final int? height,
    required this.privateKey,
    this.network = 0,
  }) : super(name: name, password: password, height: height);
  final String? privateKey;
  int network;
}

/// A watch-only wallet paired with a Ledger running the Official Zcash app.
///
/// The viewing key is fetched from the device while restoring, through
/// [hardwareWalletService], so the user approves the export on the device at
/// that point rather than up front in the account picker.
class ZcashRestoreWalletFromHardware extends WalletCredentials {
  ZcashRestoreWalletFromHardware({
    required final String name,
    required this.hardwareWalletService,
    required final int? height,
    this.accountIndex = 0,
    final WalletInfo? walletInfo,
    this.network = 0,
  }) : super(name: name, height: height, walletInfo: walletInfo);

  final HardwareWalletService hardwareWalletService;

  /// ZIP-32 account index on the device (m/32'/133'/index').
  final int accountIndex;
  int network;
}
