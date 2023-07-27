import 'package:cake_wallet/ionia/ionia_merchant.dart';
import 'package:cake_wallet/ionia/ionia_tip.dart';
import 'package:mobx/mobx.dart';

part 'ionia_custom_tip_view_model.g.dart';

class IoniaCustomTipViewModel = IoniaCustomTipViewModelBase with _$IoniaCustomTipViewModel;

abstract class IoniaCustomTipViewModelBase with Store {
  IoniaCustomTipViewModelBase({
    required this.amount,
    required this.tip,
    required this.ioniaMerchant})
    : customTip = tip,
      percentage = 0;
      
  final IoniaMerchant ioniaMerchant;
  final double amount;
  final IoniaTip tip;
  
  @observable
  IoniaTip customTip;

  @observable
  double percentage;

  @action
  void onTipChanged(String value){
   
    final _amount = value.isEmpty ? 0 : double.parse(value.replaceAll(',', '.'));
    percentage = _amount/amount * 100;
    customTip = IoniaTip(percentage: percentage, originalAmount: amount);
  }
}