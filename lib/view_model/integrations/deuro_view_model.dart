import 'package:cake_wallet/ethereum/ethereum.dart';
import 'package:cake_wallet/store/app_store.dart';
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
  String interestRate = '0';

  @observable
  String accruedInterest = '0.00';

  @action
  Future<void> reloadSavingsUserData() async {
    final savingsBalanceRaw = ethereum!.getDEuroSavingsBalance(_appStore.wallet!);
    final accruedInterestRaw = ethereum!.getDEuroAccruedInterest(_appStore.wallet!);

    savingsBalance = ethereum!
        .formatterEthereumAmountToDouble(amount: await savingsBalanceRaw)
        .toStringAsFixed(6);
    accruedInterest = ethereum!
        .formatterEthereumAmountToDouble(amount: await accruedInterestRaw)
        .toStringAsFixed(6);
  }

  @action
  Future<void> reloadInterestRate() async {
    final interestRateRaw = await ethereum!.getDEuroInterestRate(_appStore.wallet!);

    interestRate = (interestRateRaw / BigInt.from(10000)).toString();
  }
}
