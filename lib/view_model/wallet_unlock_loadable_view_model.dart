import 'package:cw_core/wallet_base.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/core/wallet_loading_service.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/view_model/wallet_password_auth_view_model.dart';

part 'wallet_unlock_loadable_view_model.g.dart';

class WalletUnlockLoadableViewModel = WalletUnlockLoadableViewModelBase
    with _$WalletUnlockLoadableViewModel;

abstract class WalletUnlockLoadableViewModelBase extends WalletPasswordAuthViewModel with Store {
  WalletUnlockLoadableViewModelBase(this._appStore, this._walletLoadingService,
      {required this.useTotp, required this.walletName, required this.walletType})
      : super(useTotp: useTotp, walletName: walletName, walletType: walletType);

  final String walletName;
  final WalletType walletType;
  final WalletLoadingService _walletLoadingService;
  final AppStore _appStore;

  @observable
  bool useTotp;

  @action
  Future<dynamic> load() async {
    final wallet = await _walletLoadingService.load(walletType, walletName, password: password);
    return wallet;
  }

  @action
  Future<dynamic> unlock() async {
    final wallet = await load();
    _appStore.changeCurrentWallet(wallet as WalletBase);
    return wallet;
  }
}
