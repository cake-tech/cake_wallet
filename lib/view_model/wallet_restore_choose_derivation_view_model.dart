import 'package:cw_core/wallet_info.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/view_model/restore/restore_mode.dart';

part 'wallet_restore_choose_derivation_view_model.g.dart';

class WalletRestoreChooseDerivationViewModel = WalletRestoreChooseDerivationViewModelBase
    with _$WalletRestoreChooseDerivationViewModel;

abstract class WalletRestoreChooseDerivationViewModelBase with Store {
  WalletRestoreChooseDerivationViewModelBase({required this.derivationInfos})
      : mode = WalletRestoreMode.seed {}

  @observable
  List<DerivationInfo> derivationInfos;

  Future<List<DerivationInfo>> get derivations async {
    return derivationInfos;
  }

  @observable
  WalletRestoreMode mode;
}
