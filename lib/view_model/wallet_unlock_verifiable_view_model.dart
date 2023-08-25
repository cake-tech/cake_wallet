import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/view_model/wallet_password_auth_view_model.dart';

part 'wallet_unlock_verifiable_view_model.g.dart';

class WalletUnlockVerifiableViewModel = WalletUnlockVerifiableViewModelBase
    with _$WalletUnlockVerifiableViewModel;

abstract class WalletUnlockVerifiableViewModelBase extends WalletPasswordAuthViewModel with Store {
  WalletUnlockVerifiableViewModelBase(this._appStore,
      {required this.useTotp, required this.walletName, required this.walletType})
      : super(useTotp: useTotp, walletName: walletName, walletType: walletType);

  final String walletName;
  final WalletType walletType;
  final AppStore _appStore;

  @observable
  bool useTotp;

  @action
  Future<void> verify() async {
    final valid = _appStore.wallet!.password == password;
    if (!valid) throw Exception('${S.current.invalid_password}');
  }
}
