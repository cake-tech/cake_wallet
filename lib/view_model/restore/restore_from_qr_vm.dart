
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/core/wallet_creation_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/view_model/wallet_creation_vm.dart';
import 'package:cw_core/wallet_info.dart';

part 'restore_from_qr_vm.g.dart';

class WalletRestorationFromQRVM = WalletRestorationFromQRVMBase with _$WalletRestorationFromQRVM;

abstract class WalletRestorationFromQRVMBase extends WalletCreationVM with Store {
  WalletRestorationFromQRVMBase(AppStore appStore, WalletCreationService walletCreationService,
      Box<WalletInfo> walletInfoSource, {required this.isNewInstall})
      : super(appStore, walletInfoSource, walletCreationService,
            type: WalletType.monero, isRecovery: true);

  final bool isNewInstall;
}
