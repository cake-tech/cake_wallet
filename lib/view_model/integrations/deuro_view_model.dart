import 'dart:math';

import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/ethereum/ethereum.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:mobx/mobx.dart';

part 'deuro_view_model.g.dart';

class DEuroViewModel = DEuroViewModelBase with _$DEuroViewModel;

abstract class DEuroViewModelBase with Store {
  final AppStore _appStore;

  DEuroViewModelBase(this._appStore) {
    reloadInterestRate();
    reloadSavingsUserData();
  }

  @observable
  String savingsBalance = '0.00';

  @observable
  ExecutionState state = InitialExecutionState();

  @observable
  String interestRate = '0';

  @observable
  String accruedInterest = '0.00';

  @observable
  PendingTransaction? transaction = null;

  @action
  Future<void> reloadSavingsUserData() async {
    final savingsBalanceRaw =
    ethereum!.getDEuroSavingsBalance(_appStore.wallet!);
    final accruedInterestRaw =
    ethereum!.getDEuroAccruedInterest(_appStore.wallet!);

    savingsBalance = ethereum!
        .formatterEthereumAmountToDouble(amount: await savingsBalanceRaw)
        .toStringAsFixed(6);
    accruedInterest = ethereum!
        .formatterEthereumAmountToDouble(amount: await accruedInterestRaw)
        .toStringAsFixed(6);
  }

  @action
  Future<void> reloadInterestRate() async {
    final interestRateRaw =
    await ethereum!.getDEuroInterestRate(_appStore.wallet!);

    interestRate = (interestRateRaw / BigInt.from(10000)).toString();
  }

  @action
  Future<void> prepareSavingsEdit(String amountRaw, bool isAdding) async {
    final amount = BigInt.from(num.parse(amountRaw) * pow(10, 18));
    print(amount);
    transaction = await (isAdding
        ? ethereum!.addDEuroSaving(_appStore.wallet!, amount)
        : ethereum!.removeDEuroSaving(_appStore.wallet!, amount));
  }

  @action
  Future<void> commitTransaction() async {
    if (transaction != null) {
      state = TransactionCommitting();
      await transaction!.commit();
      reloadSavingsUserData();
      state = TransactionCommitted();
    }
  }

  @action
  void dismissTransaction() {
    state = InitialExecutionState();
    transaction == null;
  }
}
