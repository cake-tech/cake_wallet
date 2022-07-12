import 'dart:convert';

import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/entities/cake_phone_entities/top_up.dart';
import 'package:http/http.dart' as http;
import 'package:cake_wallet/entities/cake_phone_entities/service_plan.dart';
import 'package:country_pickers/countries.dart';
import 'package:country_pickers/country.dart';
import 'package:mobx/mobx.dart';

part 'phone_plan_view_model.g.dart';

class PhonePlanViewModel = PhonePlanViewModelBase with _$PhonePlanViewModel;

abstract class PhonePlanViewModelBase with Store {
  PhonePlanViewModelBase({this.selectedPlan}) {
    payWithCakeBalanceState = InitialExecutionState();
    payWithXMRState = InitialExecutionState();

    additionalSms = 0;
    rateInCents = 20; // TODO: get from api

    servicePlans = [
      ServicePlan(id: "1", duration: 1, price: 20, quantity: 30),
      ServicePlan(id: "2", duration: 3, price: 10, quantity: 60),
      ServicePlan(id: "3", duration: 6, price: 9, quantity: 120),
      ServicePlan(id: "4", duration: 12, price: 5, quantity: 200),
      ServicePlan(id: "5", duration: 24, price: 2, quantity: 400),
    ];
    // TODO: servicePlans = _getServicesFromApi

    selectedPlan ??= servicePlans.first;

    selectedCountry = countryList.firstWhere((element) => element.iso3Code == "USA");
  }

  @observable
  ExecutionState payWithCakeBalanceState;

  @observable
  ExecutionState payWithXMRState;

  @observable
  ServicePlan selectedPlan;

  @observable
  Country selectedCountry;

  @observable
  List<ServicePlan> servicePlans;

  @observable
  int additionalSms;

  @observable
  int rateInCents;

  @computed
  double get totalPrice => (selectedPlan?.price ?? 0) + (additionalSms * ((rateInCents ?? 0) / 100)).toDouble();

  @action
  void addAdditionalSms() => additionalSms++;

  @action
  void removeAdditionalSms() {
    if (additionalSms > 0) {
      additionalSms--;
    }
  }

  final String _baseUrl = '';

  Future<bool> purchasePlan() async {
    payWithCakeBalanceState = IsExecutingState();

    final headers = {'Content-Type': 'application/json'};
    final body = <String, String>{
      "country": "US",
      "plan_id": "8b23b65a-a465-4d02-819e-9a6054eb4c22",
    };

    final uri = Uri.https(_baseUrl, '/account/me/service/phone_number');
    final response = await http.post(uri, headers: headers, body: json.encode(body));

    if (response.statusCode != 200) {
      payWithCakeBalanceState = FailureState(response.body);
      return false;
    }

    buyAdditionalSMS();

    payWithCakeBalanceState = ExecutedSuccessfullyState();
    return true;
  }

  Future<bool> buyAdditionalSMS() async {
    if (additionalSms == 0) {
      return true;
    }

    final headers = {'Content-Type': 'application/json'};
    final body = <String, int>{"quantity": additionalSms};

    final uri = Uri.https(_baseUrl, '/account/me/service/message_receive');
    final response = await http.post(uri, headers: headers, body: json.encode(body));

    if (response.statusCode != 200) {
      return false;
    }

    return true;
  }

  Future<TopUp> getMoneroPaymentInfo(double totalPrice) async {
    final headers = {'Content-Type': 'application/json'};
    final body = <String, String>{"amount": totalPrice.toString()};

    final uri = Uri.https(_baseUrl, '/account/me/topup/moneropay');
    final response = await http.post(uri, headers: headers, body: json.encode(body));

    if (response.statusCode != 200) {
      return null;
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;

    return TopUp(
      id: responseJSON['id'] as String,
      address: responseJSON['address'] as String,
      amount: responseJSON['amount'] as double,
    );
  }
}
