import 'package:ledger_flutter/ledger_flutter.dart';
import 'package:mobx/mobx.dart';

part 'hardware_wallet_view_wallet.g.dart';

class HardwareWalletViewModel = HardwareWalletViewModelBase
    with _$HardwareWalletViewModel;

abstract class HardwareWalletViewModelBase extends WalletChangeListenerViewModel with Store {

  @observable
  LedgerDevice? connectedDevice = null;


}
