import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/anypay/any_pay_payment.dart';
import 'package:cake_wallet/anypay/any_pay_payment_committed_info.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/ionia/ionia_anypay.dart';
import 'package:cake_wallet/ionia/cake_pay_vendor.dart';
import 'package:cake_wallet/ionia/ionia_tip.dart';
import 'package:cake_wallet/ionia/ionia_any_pay_payment_info.dart';
import 'package:cake_wallet/view_model/send/send_view_model.dart';

part 'cake_pay_purchase_view_model.g.dart';

class CakePayPurchaseViewModel = CakePayPurchaseViewModelBase with _$CakePayPurchaseViewModel;

abstract class CakePayPurchaseViewModelBase with Store {
  CakePayPurchaseViewModelBase({
    required this.ioniaAnyPayService,
    required this.amount,
    required this.vendor,
    required this.sendViewModel,
  }) : tipAmount = 0.0,
        percentage = 0.0,
        invoiceCreationState = InitialExecutionState(),
        invoiceCommittingState = InitialExecutionState(),
        tips = <IoniaTip>[
          IoniaTip(percentage: 0, originalAmount: amount),
          IoniaTip(percentage: 15, originalAmount: amount),
          IoniaTip(percentage: 18, originalAmount: amount),
          IoniaTip(percentage: 20, originalAmount: amount),
          IoniaTip(percentage: 0, originalAmount: amount, isCustom: true),
        ] {
    selectedTip = tips.first;
  }

  final double amount;

  List<IoniaTip> tips;

  @observable
  IoniaTip? selectedTip;

  final CakePayVendor vendor;

  final SendViewModel sendViewModel;

  final IoniaAnyPay ioniaAnyPayService;

  IoniaAnyPayPaymentInfo? paymentInfo;

  AnyPayPayment? get invoice => paymentInfo?.anyPayPayment;

  AnyPayPaymentCommittedInfo? committedInfo;

  @observable
  ExecutionState invoiceCreationState;

  @observable
  ExecutionState invoiceCommittingState;

  @observable
  double percentage;

  @computed
  double get giftCardAmount => double.parse((amount + tipAmount).toStringAsFixed(2));

  @computed
  double get billAmount => double.parse((giftCardAmount * (1 - ( 1 / 100))).toStringAsFixed(2)); //TODO: check if this is correct vendor.discount

  @observable
  double tipAmount;

  @action
  void addTip(IoniaTip tip) {
    tipAmount = tip.additionalAmount;
    selectedTip = tip;
  }

  @action
  Future<void> createInvoice() async {
    try {
      invoiceCreationState = IsExecutingState();
      paymentInfo = await ioniaAnyPayService.purchase(merchId: vendor.id.toString(), amount: giftCardAmount);
      invoiceCreationState = ExecutedSuccessfullyState();
    } catch (e) {
      invoiceCreationState = FailureState(e.toString());
    }
  }

  @action
  Future<void> commitPaymentInvoice() async {
    try {
      if (invoice == null) {
        throw Exception('Invoice is created. Invoince is null');
      }

      invoiceCommittingState = IsExecutingState();
      committedInfo = await ioniaAnyPayService.commitInvoice(invoice!);
      invoiceCommittingState = ExecutedSuccessfullyState(payload: committedInfo!);
    } catch (e) {
      invoiceCommittingState = FailureState(e.toString());
    }
  }
}
