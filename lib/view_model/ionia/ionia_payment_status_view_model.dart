import 'dart:async';
import 'package:cake_wallet/anypay/any_pay_chain.dart';
import 'package:mobx/mobx.dart';
import 'package:flutter/foundation.dart';
import 'package:cake_wallet/ionia/ionia_service.dart';
import 'package:cake_wallet/ionia/ionia_gift_card.dart';
import 'package:cake_wallet/anypay/any_pay_payment_committed_info.dart';
import 'package:cake_wallet/ionia/ionia_any_pay_payment_info.dart';

part 'ionia_payment_status_view_model.g.dart';

class IoniaPaymentStatusViewModel = IoniaPaymentStatusViewModelBase with _$IoniaPaymentStatusViewModel;

abstract class IoniaPaymentStatusViewModelBase with Store {
  IoniaPaymentStatusViewModelBase(
    this.ioniaService, {
      required this.paymentInfo,
      required this.committedInfo})
    : error = '' {
      _timer = Timer.periodic(updateTime, (timer) async {
        await updatePaymentStatus();

        if (giftCard != null) {
          timer?.cancel();
        }
      });
    }

  static const updateTime = Duration(seconds: 3);

  final IoniaService ioniaService;
  final IoniaAnyPayPaymentInfo paymentInfo;
  final AnyPayPaymentCommittedInfo committedInfo;

  @observable
  IoniaGiftCard? giftCard;

  @observable
  String error;

  Timer? get timer => _timer;

  bool get payingByBitcoin => paymentInfo.anyPayPayment.chain == AnyPayChain.btc;

  Timer? _timer;

  @action
  Future<void> updatePaymentStatus() async {
    try {
      final giftCardId = await ioniaService.getPaymentStatus(
        orderId: paymentInfo.ioniaOrder.id,
        paymentId: paymentInfo.ioniaOrder.paymentId);

      if (giftCardId != null) {
        giftCard = await ioniaService.getGiftCard(id: giftCardId);
      }

    } catch (e) {
      error = e.toString();
    }
  }
}
