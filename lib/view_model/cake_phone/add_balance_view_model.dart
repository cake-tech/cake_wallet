import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/view_model/buy/buy_amount_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/wallet_base.dart';

part 'add_balance_view_model.g.dart';

class AddBalanceViewModel = AddBalanceViewModelBase with _$AddBalanceViewModel;

abstract class AddBalanceViewModelBase with Store {
  AddBalanceViewModelBase(this.buyAmountViewModel, {@required this.wallet}) {
    state = InitialExecutionState();

    isRunning = false;
    isDisabled = true;
  }

  final BuyAmountViewModel buyAmountViewModel;
  final WalletBase wallet;

  @observable
  ExecutionState state;

  @observable
  bool isRunning;

  @observable
  bool isDisabled;

  WalletType get type => wallet.type;

  double get doubleAmount => buyAmountViewModel.doubleAmount;

  @computed
  FiatCurrency get fiatCurrency => buyAmountViewModel.fiatCurrency;

  CryptoCurrency get cryptoCurrency => walletTypeToCryptoCurrency(type);
}
