import 'package:cake_wallet/anypay/any_pay_payment_committed_info.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/ionia/cake_pay_card.dart';
import 'package:cake_wallet/ionia/cake_pay_order.dart';
import 'package:cake_wallet/ionia/cake_pay_service.dart';
import 'package:cake_wallet/ionia/ionia_tip.dart';
import 'package:cake_wallet/view_model/send/send_view_model.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';

part 'cake_pay_purchase_view_model.g.dart';

class CakePayPurchaseViewModel = CakePayPurchaseViewModelBase with _$CakePayPurchaseViewModel;

abstract class CakePayPurchaseViewModelBase with Store {
  CakePayPurchaseViewModelBase({
    required this.cakePayService,
    required this.amount,
    required this.card,
    required this.sendViewModel,
  })  : walletType = sendViewModel.walletType,
        orderCreationState = InitialExecutionState(),
        invoiceCommittingState = InitialExecutionState();

  final WalletType walletType;

  final List<double> amount;

  @observable
  IoniaTip? selectedTip;

  final CakePayCard card;

  final SendViewModel sendViewModel;

  final CakePayService cakePayService;

  CakePayOrder? order;

  AnyPayPaymentCommittedInfo? committedInfo;

  CryptoPaymentData? get cryptoPaymentData {
    if (order == null) return null;

    if (WalletType.monero == walletType) {
      return order!.paymentData.xmr;
    }

    if (WalletType.bitcoin == walletType) {
      return order!.paymentData.btc;
    }

    return null;
  }

  @observable
  ExecutionState orderCreationState;

  @observable
  ExecutionState invoiceCommittingState;

  @computed
  double get giftCardAmount => amount[0];

  @computed
  int get giftQuantity => amount[1].round();

  @computed
  double get totalAmount => giftCardAmount * giftQuantity;

  @action
  Future<void> createOrder() async {
    try {
      orderCreationState = IsExecutingState();
      order = await cakePayService.createOrder(
          cardId: card.id, price: giftCardAmount.toString(), quantity: giftQuantity);
      await confirmSending();
      orderCreationState = ExecutedSuccessfullyState();
    } catch (e) {
      orderCreationState = FailureState(
          sendViewModel.translateErrorMessage(e, walletType, sendViewModel.wallet.currency));
    }
  }

  @action
  Future<void> confirmSending() async {
    try {
      if (order == null || cryptoPaymentData == null) return;

      sendViewModel.clearOutputs();
      final output = sendViewModel.outputs.first;
      output.address = cryptoPaymentData?.address ?? '';
      output.setCryptoAmount(cryptoPaymentData?.price ?? '');

      await sendViewModel.createTransaction();
    } catch (e) {
      throw e;
    }
  }

  Future<void> simulatePayment() async {
    try {
      if (order == null) {
        throw Exception('Order is not created yet');
      }

      await cakePayService.simulatePayment(orderId: order!.orderId);
    } catch (e) {
      orderCreationState = FailureState(e.toString());
    }
  }

  @action
  Future<void> commitPaymentInvoice() async {
    try {
      if (order == null) {
        throw Exception('Order is not created yet');
      }

      invoiceCommittingState = IsExecutingState();
      //committedInfo = await ioniaAnyPayService.commitInvoice(order!);
      invoiceCommittingState = ExecutedSuccessfullyState(payload: committedInfo!);
    } catch (e) {
      invoiceCommittingState = FailureState(e.toString());
    }
  }
}
