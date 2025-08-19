import 'dart:async';

import 'package:cake_wallet/cake_pay/src/models/cake_pay_card.dart';
import 'package:cake_wallet/cake_pay/src/models/cake_pay_order.dart';
import 'package:cake_wallet/cake_pay/src/models/cake_pay_vendor.dart';
import 'package:cake_wallet/cake_pay/src/services/cake_pay_service.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/utils/feature_flag.dart';
import 'package:cake_wallet/view_model/send/send_view_model.dart';
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';

part 'cake_pay_buy_card_view_model.g.dart';

class CakePayBuyCardViewModel = CakePayBuyCardViewModelBase with _$CakePayBuyCardViewModel;

abstract class CakePayBuyCardViewModelBase with Store {
  CakePayBuyCardViewModelBase(
      {required this.vendor, required CakePayService cakePayService, required this.sendViewModel})
      : _cakePayService = cakePayService, walletType = sendViewModel.walletType,
        amount = vendor.card!.denominationItems.isNotEmpty
            ? vendor.card!.denominationItems.first.value
            : 0,
        quantity = 1,
        card = vendor.card!,
        min = _toDouble(vendor.card!.minValue) ?? 0,
        max = _toDouble(vendor.card!.maxValue) ?? 0 {
    selectedPaymentMethod = availableMethods.isNotEmpty ? availableMethods.first : null;
  }

  static double? _toDouble(String? value) {
    if (value == null || value.isEmpty) return null;
    return double.tryParse(value.replaceAll(',', '.'));
  }

  final CakePayVendor vendor;
  final SendViewModel sendViewModel;
  final CakePayService _cakePayService;
  final double max;
  final double min;
  final CakePayCard card;
  final WalletType walletType;

  CakePayOrder? order;
  Timer? _timer;
  DateTime? expirationTime;
  Duration? remainingTime;
  bool confirmsNoVpn = false;
  bool confirmsVoidedRefund = false;
  bool confirmsTermsAgreed = false;
  (String, int?) selectedDenomination = ('', null);

  String simulatedResponse = '';

  bool get isDenominationSelected =>
      card.denominationItems.isNotEmpty &&
      card.denominationItems.any((item) => item.value == amount);
  
  Future<bool> get isUserLogged async => await _cakePayService.isLogged();

  @observable
  double amount;

  @observable
  int quantity;

  @observable
  bool isPurchasing = false;

  @observable
  bool isSimulatingFlow = false;

  @observable
  bool isOrderExpired = false;

  @observable
  String formattedRemainingTime = '';

  @computed
  bool get isAmountSufficient =>
      (amount >= min && amount <= max) || (isDenominationSelected && quantity > 0);

  @observable
  CakePayPaymentMethod? selectedPaymentMethod;

  @computed
  double get totalAmount => amount * quantity;

  @computed
  bool get isSimulating =>
      isSimulatingFlow &&
      FeatureFlag.hasDevOptions &&
      FeatureFlag.isCakePayPurchaseSimulationEnabled;

  @computed
  List<CakePayPaymentMethod> get availableMethods {
    switch (walletType) {
      case WalletType.bitcoin:
        return [CakePayPaymentMethod.BTC];
      case WalletType.litecoin:
        return [CakePayPaymentMethod.LTC,if (sendViewModel.isMwebEnabled) CakePayPaymentMethod.LTC_MWEB];
      case WalletType.monero:
        return [CakePayPaymentMethod.XMR];
      default:
        return const [];
    }
  }

  @action
  void chooseMethod(CakePayPaymentMethod method) {
    selectedPaymentMethod = method;
    if (walletType == WalletType.litecoin) {
      sendViewModel.setAllowMwebCoins(method == CakePayPaymentMethod.LTC_MWEB);
    }
  }

  @action
  void onQuantityChanged(int? input) => quantity = input ?? 1;

  @action
  void onAmountChanged(String input) {
    if (input.isEmpty) return;
    amount = double.parse(input.replaceAll(',', '.'));
  }

  CryptoPaymentData? getPaymentDataFor(CakePayPaymentMethod? method) {
    if (order == null || method == null) return null;

    final data = switch (method) {
      CakePayPaymentMethod.BTC => order?.paymentData.btc,
      CakePayPaymentMethod.XMR => order?.paymentData.xmr,
      CakePayPaymentMethod.LTC => order?.paymentData.ltc,
      CakePayPaymentMethod.LTC_MWEB => order?.paymentData.ltc_mweb,
      _ => null
    };

    if (data == null) return null;

    final bip21 = data.paymentUrls?.bip21;
    if (bip21 != null && bip21.isNotEmpty) {
      final uri = Uri.parse(bip21);
      final addr = uri.path;
      final price = uri.queryParameters['amount'] ?? data.price;

      return CryptoPaymentData(price: price, address: addr);
    }

    return data;
  }

  @action
  Future<void> createOrder() async {
    if (walletType != WalletType.bitcoin &&
        walletType != WalletType.monero &&
        walletType != WalletType.litecoin) {
      sendViewModel.state =
          FailureState('Unsupported wallet type, please use Bitcoin, Monero, or Litecoin.');
    }
    try {
      order = await _cakePayService.createOrder(
        cardId: isDenominationSelected ? selectedDenomination.$2 ?? card.id : card.id,
        price: isDenominationSelected ? selectedDenomination.$1 : amount.toString(),
        quantity: quantity,
        confirmsNoVpn: confirmsNoVpn,
        confirmsVoidedRefund: confirmsVoidedRefund,
        confirmsTermsAgreed: confirmsTermsAgreed,
      );
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
    final cryptoPaymentData = getPaymentDataFor(selectedPaymentMethod);
    if (order == null || cryptoPaymentData == null) return;

    try {
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
  Future<void> simulatePayment() async {
    if (order == null) {
      throw Exception('Order is not created yet.');
    }

    try {
      simulatedResponse = await _cakePayService.simulatePayment(orderId: order!.orderId);
      sendViewModel.state = TransactionCommitted();
    } catch (e) {
      sendViewModel.state = FailureState(
          sendViewModel.translateErrorMessage(e, walletType, sendViewModel.wallet.currency));
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
  
  Future<void> logout() async => await _cakePayService.logout();

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
