import 'package:cake_wallet/ethereum/ethereum.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:mobx/mobx.dart';

part 'deuro_borrowing_view_model.g.dart';

class DEuroBorrowingViewModel = DEuroBorrowingViewModelBase with _$DEuroBorrowingViewModel;

abstract class DEuroBorrowingViewModelBase with Store {
  final AppStore appStore;

  DEuroBorrowingViewModelBase(this.appStore);

  @observable
  bool isLoading = true;

  @observable
  ObservableList<Map<String, dynamic>> positions = ObservableList();

  @action
  Future<void> loadPosition() async {
    final response = await ethereum!.getDEuroOwnedPositions(this.appStore.wallet!);

    if (response.length == positions.length) return;
    positions.clear();
    positions.addAll(response);
  }

  @observable
  String collateralAmount = '';

  @observable
  String liquidationPrice = '';

  @observable
  String expiryDate = '';

  
}
