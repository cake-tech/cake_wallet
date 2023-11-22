import 'package:cw_core/wallet_info.dart';

abstract class WalletCredentials {
  WalletCredentials({
    required this.name,
    this.height,
    this.seedPhraseLength,
    this.walletInfo,
    this.password,
    this.derivationType,
    this.derivationPath,
  });

  final String name;
  final int? height;
  int? seedPhraseLength;
  String? password;
  DerivationType? derivationType;
  String? derivationPath;
  WalletInfo? walletInfo;
}
