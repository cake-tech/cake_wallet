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
    amount = '';
    enableCardPurchase = false;
  }

  IoniaMerchant ioniaMerchant;

  IoniaAnyPay ioniaAnyPayService;

  AnyPayPayment invoice;

  AnyPayPaymentCommittedInfo committedInfo;

  @observable
  ExecutionState invoiceCreationState;

  @observable
  ExecutionState invoiceCommittingState;

  @observable
  String amount;

  @observable
  double percentage;

  @computed
  double get giftCardAmount => double.parse(amount) + tipAmount;

  @observable
  double tipAmount;

  @observable
  bool enableCardPurchase;

  @action
  void onAmountChanged(String input) {
    if (input.isEmpty) return;
    amount = input;
    final inputAmount = double.parse(input);
    final min = ioniaMerchant.minimumCardPurchase;
    final max = ioniaMerchant.maximumCardPurchase;

    enableCardPurchase = inputAmount >= min && inputAmount <= max;
  }

  void setSelectedMerchant(IoniaMerchant merchant) {
    ioniaMerchant = merchant;
  }

  @action
  void addTip(IoniaTip tip) {
    tipAmount = tip.additionalAmount;
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
