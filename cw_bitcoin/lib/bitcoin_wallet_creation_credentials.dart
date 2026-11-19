import "package:cw_bitcoin/multisig/multisig_config.dart";
import "package:cw_core/hardware/hardware_account_data.dart";
import "package:cw_core/multisig/multisig_wallet_service.dart";
import "package:cw_core/wallet_credentials.dart";
import "package:cw_core/wallet_info.dart";

class BitcoinNewWalletCredentials extends WalletCredentials {
  BitcoinNewWalletCredentials({
    required super.name,
    super.walletInfo,
    super.password,
    super.passphrase,
    this.mnemonic,
    DerivationType? derivationType,
    String? derivationPath,
  }) : super(
          derivationInfo: DerivationInfo(
            derivationType: derivationType,
            derivationPath: derivationPath,
          ),
        );

  final String? mnemonic;
}

class BitcoinRestoreWalletFromSeedCredentials extends WalletCredentials {
  BitcoinRestoreWalletFromSeedCredentials({
    required super.name,
    required String super.password,
    required this.mnemonic,
    required DerivationType derivationType,
    required String derivationPath,
    super.walletInfo,
    super.passphrase,
  }) : super(
          derivationInfo: DerivationInfo(
            derivationType: derivationType,
            derivationPath: derivationPath,
          ),
        );

  final String mnemonic;
}

class BitcoinRestoreWalletFromWIFCredentials extends WalletCredentials {
  BitcoinRestoreWalletFromWIFCredentials({
    required super.name,
    required String super.password,
    required this.wif,
    super.walletInfo,
  });

  final String wif;
}

class BitcoinWalletFromKeysCredentials extends WalletCredentials {
  BitcoinWalletFromKeysCredentials({
    required super.name,
    required String super.password,
    required this.xpub,
    super.walletInfo,
    super.hardwareWalletType,
  });

  final String xpub;
}

class LitecoinWalletFromKeysCredentials extends WalletCredentials {
  LitecoinWalletFromKeysCredentials({
    required super.name,
    required String super.password,
    required this.xpub,
    required this.scanSecret,
    required this.spendPubkey,
    super.walletInfo,
    super.hardwareWalletType,
  });

  final String xpub;
  final String scanSecret;
  final String spendPubkey;
}

class BitcoinRestoreWalletFromHardware extends WalletCredentials {
  BitcoinRestoreWalletFromHardware({
    required super.name,
    required this.hwAccountData,
    super.walletInfo,
  });

  final HardwareAccountData hwAccountData;
}

class BitcoinMutiSigWalletCredentials extends MutiSigWalletCredentials {
  BitcoinMutiSigWalletCredentials({
    required super.name,
    required this.multisigConfig,
    super.walletInfo,
  }) : super(multisigConfig: multisigConfig);

  @override
  final BitcoinMultisigConfig multisigConfig;
}
