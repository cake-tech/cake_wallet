import 'package:cake_wallet/entities/receive_page_option.dart';
import 'package:mobx/mobx.dart';

part 'address_page_view_model.g.dart';

class AddressPageViewModel = AddressPageViewModelBase with _$AddressPageViewModel;

abstract class AddressPageViewModelBase with Store {
  AddressPageViewModelBase() : selectedReceiveOption = ReceivePageOption.mainnet;

  @observable
  ReceivePageOption selectedReceiveOption;

  List<ReceivePageOption> get options => ReceivePageOption.values;

  @action
  void selectReceiveOption(ReceivePageOption option) {
    selectedReceiveOption = option;
  }
}
