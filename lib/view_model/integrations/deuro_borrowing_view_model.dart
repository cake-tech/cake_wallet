import 'package:mobx/mobx.dart';

part 'deuro_borrowing_view_model.g.dart';

class DEuroBorrowingViewModel = DEuroBorrowingViewModelBase with _$DEuroBorrowingViewModel;

abstract class DEuroBorrowingViewModelBase with Store {

  @observable
  bool isLoading = true;

  @action
  Future<void> loadPosition() async {

  }
}
