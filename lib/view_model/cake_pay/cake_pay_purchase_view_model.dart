import 'dart:async';

import 'package:cake_wallet/cake_pay/cake_pay_card.dart';
import 'package:cake_wallet/cake_pay/cake_pay_order.dart';
import 'package:cake_wallet/cake_pay/cake_pay_payment_credantials.dart';
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
    required this.paymentCredential,
    required this.card,
    required this.sendViewModel,
  }) : walletType = sendViewModel.walletType;

  final WalletType walletType;

  final PaymentCredential paymentCredential;

  final CakePayCard card;

  final SendViewModel sendViewModel;

  final CakePayService cakePayService;

  CakePayOrder? order;

  Timer? _timer;

  DateTime? expirationTime;

  Duration? remainingTime;

  String? get userName => paymentCredential.userName;

  double get amount => paymentCredential.amount;

  int get quantity => paymentCredential.quantity;

  double get totalAmount => paymentCredential.totalAmount;

  String get fiatCurrency => paymentCredential.fiatCurrency;

  CryptoPaymentData? get cryptoPaymentData {
    if (order == null) return null;

    if (WalletType.monero == walletType) {
      return order!.paymentData.xmr;
    }

    if (WalletType.bitcoin == walletType) {
      final paymentUrls = order!.paymentData.btc.paymentUrls!.bip21;

      final uri = Uri.parse(paymentUrls!);

      final address = uri.path;
      final price = uri.queryParameters['amount'];

      return CryptoPaymentData(
        address: address,
        price: price ?? '0',
      );
    }

    return null;
  }

  @observable
  bool isOrderExpired = false;

  @observable
  String formattedRemainingTime = '';

  @action
  Future<void> createOrder() async {
    if (walletType != WalletType.bitcoin && walletType != WalletType.monero) {
      sendViewModel.state = FailureState('Unsupported wallet type, please use Bitcoin or Monero.');
    }
    try {
      order = await cakePayService.createOrder(
          cardId: card.id,
          price: paymentCredential.amount.toString(),
          quantity: paymentCredential.quantity);
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
    final cryptoPaymentData = this.cryptoPaymentData;
    try {
      if (order == null || cryptoPaymentData == null) return;

      sendViewModel.clearOutputs();
      final output = sendViewModel.outputs.first;
      output.address = cryptoPaymentData.address;
      output.setCryptoAmount(cryptoPaymentData.price);

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
