import "package:cw_core/multisig/multisig_config.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_credentials.dart";

abstract class MutiSigWalletCredentials extends WalletCredentials {
  MutiSigWalletCredentials({
    required this.multisigConfig,
    required super.name,
    super.height,
    super.walletInfo,
  });

  final MultisigConfig multisigConfig;
}

interface class MultisigWalletService<RMS extends MutiSigWalletCredentials> {
  Future<WalletBase> restoreMultiSigWallet(RMS credentials) => throw UnimplementedError();
}
