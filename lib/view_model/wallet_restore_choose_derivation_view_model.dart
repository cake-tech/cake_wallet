import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cw_bitcoin/bitcoin_wallet_service.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_nano/nano_util.dart';
import 'package:cw_nano/nano_wallet_service.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/view_model/restore/restore_mode.dart';

part 'wallet_restore_choose_derivation_view_model.g.dart';

class WalletRestoreChooseDerivationViewModel = WalletRestoreChooseDerivationViewModelBase
    with _$WalletRestoreChooseDerivationViewModel;

abstract class WalletRestoreChooseDerivationViewModelBase with Store {
  WalletRestoreChooseDerivationViewModelBase({required this.credentials})
      : mode = WalletRestoreMode.seed {}

  dynamic credentials;

  @observable
  WalletRestoreMode mode;

  Future<List<DerivationInfo>> get derivations async {
    var list = <DerivationInfo>[];
    var walletType = credentials["walletType"] as WalletType;
    var appStore = getIt.get<AppStore>();
    var node = appStore.settingsStore.getCurrentNode(walletType);
    switch (walletType) {
      case WalletType.bitcoin:
        String? mnemonic = credentials['seed'] as String?;
        return await BitcoinWalletService.getDerivationsFromMnemonic(mnemonic: mnemonic!, node: node);

        // var standardInfo = await NanoWalletService.getInfoFromSeedOrMnemonic(
        //   DerivationType.nano,
        //   mnemonic: mnemonic,
        //   seedKey: seedKey,
        //   node: node,
        // );

        // list.add(DerivationInfo(
        //   balance: "0.00000",
        //   address: "address",
        //   height: 0,
        //   derivationType: DerivationType.bip39,
        // ));
        break;
      case WalletType.nano:
        String? mnemonic = credentials['seed'] as String?;
        String? seedKey = credentials['private_key'] as String?;
        var bip39Info = await NanoWalletService.getInfoFromSeedOrMnemonic(DerivationType.bip39,
            mnemonic: mnemonic, seedKey: seedKey, node: node);
        var standardInfo = await NanoWalletService.getInfoFromSeedOrMnemonic(
          DerivationType.nano,
          mnemonic: mnemonic,
          seedKey: seedKey,
          node: node,
        );

        if (standardInfo["balance"] != null) {
          list.add(DerivationInfo(
            derivationType: DerivationType.nano,
            balance: NanoUtil.getRawAsUsableString(
                standardInfo["balance"] as String, NanoUtil.rawPerNano),
            address: standardInfo["address"] as String,
            height: int.tryParse(
                  standardInfo["confirmation_height"] as String,
                ) ??
                0,
          ));
        }

        if (bip39Info["balance"] != null) {
          list.add(DerivationInfo(
            derivationType: DerivationType.bip39,
            balance:
                NanoUtil.getRawAsUsableString(bip39Info["balance"] as String, NanoUtil.rawPerNano),
            address: bip39Info["address"] as String,
            height: int.tryParse(
                  bip39Info["confirmation_height"] as String? ?? "",
                ) ??
                0,
          ));
        }

        break;
      default:
        break;
    }

    return list;
  }
}
