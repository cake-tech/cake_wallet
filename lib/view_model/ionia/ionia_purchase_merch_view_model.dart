import 'package:cake_wallet/anypay/any_pay_payment.dart';
import 'package:cake_wallet/anypay/any_pay_payment_committed_info.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/ionia/ionia_anypay.dart';
import 'package:cake_wallet/ionia/ionia_merchant.dart';
import 'package:cake_wallet/ionia/ionia_tip.dart';
import 'package:mobx/mobx.dart';

part 'ionia_purchase_merch_view_model.g.dart';

class IoniaMerchPurchaseViewModel = IoniaMerchPurchaseViewModelBase with _$IoniaMerchPurchaseViewModel;

abstract class IoniaMerchPurchaseViewModelBase with Store {
  IoniaMerchPurchaseViewModelBase(this.ioniaAnyPayService) {
    tipAmount = 0.0;
    percentage = 0.0;
    amount = 0;
    enableCardPurchase = false;

    selectedTip = tips.first;
  }

  @computed
  List<IoniaTip> get tips => <IoniaTip>[
        IoniaTip(percentage: 0, originalAmount: amount),
        IoniaTip(percentage: 10, originalAmount: amount),
        IoniaTip(percentage: 20, originalAmount: amount),
      ];

  @observable
  IoniaTip selectedTip;

  IoniaMerchant ioniaMerchant;

  IoniaAnyPay ioniaAnyPayService;

  AnyPayPayment invoice;

  AnyPayPaymentCommittedInfo committedInfo;

  @observable
  ExecutionState invoiceCreationState;

  @observable
  ExecutionState invoiceCommittingState;

  @observable
  double amount;

  @observable
  double percentage;

  @computed
  double get giftCardAmount => amount + tipAmount;

  @observable
  double tipAmount;

  @observable
  bool enableCardPurchase;

  @action
  void onAmountChanged(String input) {
    if (input.isEmpty) return;
    amount = double.parse(input);
    final min = ioniaMerchant.minimumCardPurchase;
    final max = ioniaMerchant.maximumCardPurchase;

    enableCardPurchase = amount >= min && amount <= max;
  }

  void setSelectedMerchant(IoniaMerchant merchant) {
    ioniaMerchant = merchant;
  }

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
