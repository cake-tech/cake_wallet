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
  })  : tipAmount = 0.0,
        percentage = 0.0,
        walletType = sendViewModel.walletType,
        orderCreationState = InitialExecutionState(),
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

  final WalletType walletType;

  final double amount;

  List<IoniaTip> tips;

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

  @observable
  double percentage;

  @computed
  double get giftCardAmount => double.parse((amount + tipAmount).toStringAsFixed(2));

  @computed
  double get billAmount => double.parse((giftCardAmount * (1 - (1 / 100)))
      .toStringAsFixed(2)); //TODO: check if this is correct vendor.discount

  @observable
  double tipAmount;

  @action
  void addTip(IoniaTip tip) {
    tipAmount = tip.additionalAmount;
    selectedTip = tip;
  }

  @action
  Future<void> createOrder() async {
    try {
      orderCreationState = IsExecutingState();
      order = await cakePayService.createOrder(
          cardId: card.id, price: giftCardAmount.toString(), quantity: 1);
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
