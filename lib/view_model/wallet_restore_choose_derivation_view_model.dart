import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_nano/nano_balance.dart';
import 'package:cw_nano/nano_util.dart';
import 'package:cw_nano/nano_wallet_service.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/view_model/restore/restore_mode.dart';

part 'wallet_restore_choose_derivation_view_model.g.dart';

class WalletRestoreChooseDerivationViewModel = WalletRestoreChooseDerivationViewModelBase
    with _$WalletRestoreChooseDerivationViewModel;

class Derivation {
  Derivation(this.balance, this.address, this.derivationType, this.height);

  final String balance;
  final String address;
  final DerivationType derivationType;
  final int height;
}

abstract class WalletRestoreChooseDerivationViewModelBase with Store {
  WalletRestoreChooseDerivationViewModelBase({required this.credentials})
      : mode = WalletRestoreMode.seed {}

  
  dynamic credentials;

  @observable
  WalletRestoreMode mode;

  Future<List<Derivation>> get derivations async {
    var list = <Derivation>[];

    switch (getIt.get<AppStore>().wallet!.type) {
      case WalletType.nano:
        var seed = credentials['seed'] as String;
        var bip39Info =
            await NanoWalletService.getInfoFromSeedOrMnemonic(DerivationType.bip39, mnemonic: seed);
        var standardInfo =
            await NanoWalletService.getInfoFromSeedOrMnemonic(DerivationType.nano, mnemonic: seed);

        list.add(Derivation(
          NanoUtil.getRawAsUsableString(bip39Info["balance"] as String, NanoUtil.rawPerNano),
          bip39Info["address"] as String,
          DerivationType.bip39,
          int.parse(
            bip39Info["confirmation_height"] as String,
          ),
        ));
        list.add(Derivation(
          NanoUtil.getRawAsUsableString(standardInfo["balance"] as String, NanoUtil.rawPerNano),
          standardInfo["address"] as String,
          DerivationType.nano,
          int.parse(
            standardInfo["confirmation_height"] as String,
          ),
        ));

        break;
      default:
        break;
    }
    return list;
  }
}
