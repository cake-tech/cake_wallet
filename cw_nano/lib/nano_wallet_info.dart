import 'package:cw_core/wallet_info.dart';

enum DerivationType { bip39, nano }

class NanoWalletInfo extends WalletInfo {
  DerivationType derivationType;

  NanoWalletInfo({required WalletInfo walletInfo, required this.derivationType})
      : super(
          walletInfo.id,
          walletInfo.name,
          walletInfo.type,
          walletInfo.isRecovery,
          walletInfo.restoreHeight,
          walletInfo.timestamp,
          walletInfo.dirPath,
          walletInfo.path,
          walletInfo.address,
          walletInfo.yatEid,
          walletInfo.yatLastUsedAddressRaw,
          walletInfo.showIntroCakePayCard,
        );
}
