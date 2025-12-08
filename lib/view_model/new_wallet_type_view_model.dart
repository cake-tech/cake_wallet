import 'package:mobx/mobx.dart';

part 'new_wallet_type_view_model.g.dart';

class NewWalletTypeViewModel = NewWalletTypeViewModelBase with _$NewWalletTypeViewModel;

abstract class NewWalletTypeViewModelBase with Store {
  NewWalletTypeViewModelBase(this.hasExisitingWallet);

  final bool hasExisitingWallet;
}
