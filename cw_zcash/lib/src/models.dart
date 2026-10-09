import "package:cw_core/hardware/hardware_wallet_service.dart";
import 'package:cw_core/wallet_credentials.dart';

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
    this.accountIndex = 0,
    this.network = 0,
    super.hardwareWalletType,
  }) : super(name: name, password: password, height: height);
  final String? privateKey;
  final int accountIndex;
  int network;
}

class ZcashRestoreWalletFromHardware extends WalletCredentials {
  ZcashRestoreWalletFromHardware({
    required super.name,
    required super.height,
    required this.hardwareWalletService,
    this.accountIndex = 0,
    this.network = 0,
  });
  final HardwareWalletService hardwareWalletService;
  final int accountIndex;
  int network;
}
