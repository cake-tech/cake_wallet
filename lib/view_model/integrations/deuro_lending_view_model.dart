import 'package:mobx/mobx.dart';

part 'deuro_lending_view_model.g.dart';

class DEuroLendingViewModel = DEuroLendingViewModelBase with _$DEuroLendingViewModel;

abstract class DEuroLendingViewModelBase with Store {

  @observable
  bool isLoading = true;

  @action
  Future<void> loadPosition() async {

  }
}
