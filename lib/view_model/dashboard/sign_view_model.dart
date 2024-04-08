import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cw_core/receive_page_option.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';

part 'sign_view_model.g.dart';

class SignViewModel = SignViewModelBase with _$SignViewModel;

abstract class SignViewModelBase with Store {
  SignViewModelBase(this._wallet) {}

  final WalletBase _wallet;
}
