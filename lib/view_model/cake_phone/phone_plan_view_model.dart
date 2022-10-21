import 'package:cake_wallet/entities/cake_phone_entities/service_plan.dart';
import 'package:country_pickers/countries.dart';
import 'package:country_pickers/country.dart';
import 'package:mobx/mobx.dart';

part 'phone_plan_view_model.g.dart';

class PhonePlanViewModel = PhonePlanViewModelBase with _$PhonePlanViewModel;

abstract class PhonePlanViewModelBase with Store {
  PhonePlanViewModelBase({this.selectedPlan}) : this.additionalSms = 0 {
    rateInCents = 20; // TODO: get from api

    servicePlans = [
      ServicePlan(id: "1", duration: 1, price: 20, quantity: 30),
      ServicePlan(id: "2", duration: 3, price: 10, quantity: 60),
      ServicePlan(id: "3", duration: 6, price: 9, quantity: 120),
      ServicePlan(id: "4", duration: 12, price: 5, quantity: 200),
      ServicePlan(id: "5", duration: 24, price: 2, quantity: 400),
    ];
    // TODO: servicePlans = _getServicesFromApi

    selectedPlan ??= servicePlans!.first;

    selectedCountry = countryList.firstWhere((element) => element.iso3Code == "USA");
  }

  @observable
  ServicePlan? selectedPlan;

  @observable
  Country? selectedCountry;

  @observable
  List<ServicePlan>? servicePlans;

  @observable
  int additionalSms;

  @observable
  int? rateInCents;

  @computed
  double get totalPrice => (selectedPlan?.price ?? 0)
      + (additionalSms * ((rateInCents ?? 0) / 100)).toDouble();

  @action
  void addAdditionalSms() => additionalSms++;

  @action
  void removeAdditionalSms() {
    if (additionalSms > 0) {
      additionalSms--;
    }
  }
}
