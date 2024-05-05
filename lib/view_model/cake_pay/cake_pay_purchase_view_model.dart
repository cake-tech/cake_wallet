import 'dart:async';

import 'package:cake_wallet/cake_pay/cake_pay_card.dart';
import 'package:cake_wallet/cake_pay/cake_pay_order.dart';
import 'package:cake_wallet/cake_pay/cake_pay_service.dart';
import 'package:cake_wallet/core/execution_state.dart';
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
  })  : walletType = sendViewModel.walletType;

  final WalletType walletType;

  final List<double> amount;

  final CakePayCard card;

  final SendViewModel sendViewModel;

  final CakePayService cakePayService;

  CakePayOrder? order;

  Timer? _timer;

  DateTime? expirationTime;

  Duration? remainingTime;

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
  bool isOrderExpired = false;

  @observable
  String formattedRemainingTime = '';

  @computed
  double get giftCardAmount => amount[0];

  @computed
  int get giftQuantity => amount[1].round();

  @computed
  double get totalAmount => giftCardAmount * giftQuantity;

  @action
  Future<void> createOrder() async {
    try {
      order = await cakePayService.createOrder(
          cardId: card.id, price: giftCardAmount.toString(), quantity: giftQuantity);
      await confirmSending();
      expirationTime = order!.paymentData.expirationTime;
      updateRemainingTime();
      _startExpirationTimer();
    } catch (e) {
      sendViewModel.state = FailureState(
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
  void updateRemainingTime() {
    if (expirationTime == null) {
      formattedRemainingTime = '';
      return;
    }

    remainingTime = expirationTime!.difference(DateTime.now());

    isOrderExpired = remainingTime!.isNegative;

    if (isOrderExpired) {
      disposeExpirationTimer();
      sendViewModel.state = FailureState('Order has expired.');
    } else {
      formattedRemainingTime = formatDuration(remainingTime!);
    }
  }

  void _startExpirationTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      updateRemainingTime();
    });
  }

  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void disposeExpirationTimer() {
    _timer?.cancel();
    remainingTime = null;
    formattedRemainingTime = '';
    expirationTime = null;
  }

  void dispose() {
    disposeExpirationTimer();
  }
}