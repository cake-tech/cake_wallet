import 'package:cw_core/wallet_info.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';

part 'new_wallet_type_view_model.g.dart';

class NewWalletTypeViewModel = NewWalletTypeViewModelBase with _$NewWalletTypeViewModel;

abstract class NewWalletTypeViewModelBase with Store {
  NewWalletTypeViewModelBase(this._walletInfoSource);

  @computed
  bool get hasExisitingWallet => _walletInfoSource.isNotEmpty;

  final Box<WalletInfo> _walletInfoSource;
}
