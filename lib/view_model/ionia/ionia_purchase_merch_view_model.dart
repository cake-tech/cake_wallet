import 'package:cake_wallet/anypay/any_pay_payment.dart';
import 'package:cake_wallet/anypay/any_pay_payment_committed_info.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/ionia/ionia_anypay.dart';
import 'package:cake_wallet/ionia/ionia_merchant.dart';
import 'package:cake_wallet/ionia/ionia_tip.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';

part 'ionia_purchase_merch_view_model.g.dart';

class IoniaMerchPurchaseViewModel = IoniaMerchPurchaseViewModelBase with _$IoniaMerchPurchaseViewModel;

abstract class IoniaMerchPurchaseViewModelBase with Store {
  IoniaMerchPurchaseViewModelBase({
    @required this.ioniaAnyPayService,
    @required this.amount,
    @required this.ioniaMerchant,
  }) {
    tipAmount = 0.0;
    percentage = 0.0;
    tips = <IoniaTip>[
      IoniaTip(percentage: 0, originalAmount: amount),
      IoniaTip(percentage: 10, originalAmount: amount),
      IoniaTip(percentage: 20, originalAmount: amount),
    ];
    selectedTip = tips.first;
  }

  final double amount;

  List<IoniaTip> tips;

  @observable
  IoniaTip selectedTip;

  final IoniaMerchant ioniaMerchant;

  final IoniaAnyPay ioniaAnyPayService;

  AnyPayPayment invoice;

  AnyPayPaymentCommittedInfo committedInfo;

  @observable
  ExecutionState invoiceCreationState;

  @observable
  ExecutionState invoiceCommittingState;

  @observable
  double percentage;

  @computed
  double get giftCardAmount => amount + tipAmount;

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
      invoice = await ioniaAnyPayService.purchase(merchId: ioniaMerchant.id.toString(), amount: giftCardAmount);
      invoiceCreationState = ExecutedSuccessfullyState();
    } catch (e) {
      invoiceCreationState = FailureState(e.toString());
    }
  }

  @action
  Future<void> commitPaymentInvoice() async {
    try {
      invoiceCommittingState = IsExecutingState();
      committedInfo = await ioniaAnyPayService.commitInvoice(invoice);
      invoiceCommittingState = ExecutedSuccessfullyState(payload: committedInfo);
    } catch (e) {
      invoiceCommittingState = FailureState(e.toString());
    }
  }
}
