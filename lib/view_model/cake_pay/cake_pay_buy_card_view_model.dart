import 'dart:async';

import 'package:cake_wallet/cake_pay/src/cake_pay_exceptions.dart';
import 'package:cake_wallet/order/order_provider_description.dart';
import 'package:cake_wallet/order/order.dart';
import 'package:cake_wallet/order/order_source_description.dart';
import 'package:cake_wallet/cake_pay/src/models/cake_pay_card.dart';
import 'package:cake_wallet/cake_pay/src/models/cake_pay_order.dart';
import "package:cake_wallet/cake_pay/src/models/cake_pay_payment_method.dart";
import "package:cake_wallet/cake_pay/src/models/cake_pay_stablecoin.dart";
import 'package:cake_wallet/cake_pay/src/models/cake_pay_vendor.dart';
import 'package:cake_wallet/cake_pay/src/services/cake_pay_service.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import "package:cake_wallet/solana/solana.dart";
import 'package:cake_wallet/utils/feature_flag.dart';
import 'package:cake_wallet/view_model/send/send_view_model.dart';
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import "package:collection/collection.dart";
import "package:cw_core/erc20_token.dart";
import "package:cw_core/spl_token.dart";
import "package:cw_core/tron_token.dart";
import 'package:cw_core/wallet_type.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';

part 'cake_pay_buy_card_view_model.g.dart';

class CakePayBuyCardViewModel = CakePayBuyCardViewModelBase with _$CakePayBuyCardViewModel;

abstract class CakePayBuyCardViewModelBase with Store {
  CakePayBuyCardViewModelBase(
      {required this.vendor,
      required CakePayService cakePayService,
      required this.sendViewModel,
      required this.orders})
      : _cakePayService = cakePayService,
        walletType = sendViewModel.walletType,
        amount = vendor.card!.denominationItems.isNotEmpty
            ? vendor.card!.denominationItems.first.value
            : 0,
        quantity = 1,
        card = vendor.card!,
        min = vendor.card!.prepaidRange.isNotEmpty
            ? vendor.card!.prepaidRange.first.minValue
            : _toDouble(vendor.card!.minValue) ?? 0,
        max = vendor.card!.prepaidRange.isNotEmpty
            ? vendor.card!.prepaidRange.first.maxValue
            : _toDouble(vendor.card!.maxValue) ?? 0 {
    selectedPaymentMethod = availableMethods.isNotEmpty ? availableMethods.first : null;
  }

  static double? _toDouble(String? value) {
    if (value == null || value.isEmpty) return null;
    return double.tryParse(value.replaceAll(',', '.'));
  }

  final CakePayVendor vendor;
  final SendViewModel sendViewModel;
  final CakePayService _cakePayService;
  final CakePayCard card;
  final WalletType walletType;
  final Box<Order> orders;

  CakePayOrder? order;
  Timer? _timer;
  DateTime? expirationTime;
  Duration? remainingTime;
  bool confirmsNoVpn = false;
  bool confirmsVoidedRefund = false;
  bool confirmsTermsAgreed = false;
  double max;
  double min;
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
  bool get isStablecoinWallet => StablecoinNetwork.supportsNetwork(sendViewModel.wallet.currency);

  @computed
  List<CakePayPaymentMethod> get availableMethods {
    switch (walletType) {
      case WalletType.bitcoin:
        return [
          CakePayPaymentMethod.BTC,
          if (sendViewModel.wallet.isSoftwareWallet) CakePayPaymentMethod.BTC_LN
        ];
      case WalletType.litecoin:
        return [
          CakePayPaymentMethod.LTC,
          if (sendViewModel.isMwebEnabled) CakePayPaymentMethod.LTC_MWEB
        ];
      case WalletType.monero:
        return [CakePayPaymentMethod.XMR];
      case WalletType.zcash:
        return [CakePayPaymentMethod.ZEC];
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

  void onPrepaidRangeChanged(PrepaidRange range) {
    min = range.minValue;
    max = range.maxValue;
    selectedDenomination = (range.minValue.toString(), int.tryParse(range.rangeId));

    if (amount < min || amount > max) {
      amount = min;
    }
  }

  @action
  void onAmountChanged(String input) {
    if (input.isEmpty) return;
    amount = double.parse(input.replaceAll(',', '.'));

    if (card.prepaidRange.isNotEmpty) {
      selectedDenomination = (input.replaceAll(',', '.'), selectedDenomination.$2);
    }
  }

  @action
  Future<List<CakePayPaymentMethod>> prepareStablecoinOrder() async {
    try {
      disposeExpirationTimer();
      await _createBackendOrder();
      final methods = [
        for (final option in order!.paymentData.stablecoins)
          if (option.findNetwork(sendViewModel.wallet.currency) != null) option.method,
      ];
      if (methods.isEmpty) {
        throw const CakePayNoDataException(
          "Payment for this purchase isn’t available on your wallet’s network. Please try a wallet on another network.",
        );
      }
      return methods;
    } on CakePayUnauthorizedException {
      rethrow;
    } catch (e) {
      sendViewModel.state = FailureState(
          sendViewModel.translateErrorMessage(e, walletType, sendViewModel.wallet.currency));
      return [];
    }
  }

  @action
  Future<void> createOrder() async {
    if (!isStablecoinWallet && availableMethods.isEmpty) {
      sendViewModel.state = FailureState(
          "Unsupported wallet type, please use Bitcoin, Monero, Litecoin, Zcash, Ethereum, "
          "Polygon, Base, Arbitrum, BNB Chain, Solana or Tron.");
      return;
    }

    try {
      if (!isStablecoinWallet) {
        await _createBackendOrder();
      }
      final method = selectedPaymentMethod!;
      expirationTime = order!.paymentData.expirationTime;
      updateRemainingTime();
      if (isOrderExpired) {
        return;
      }

      final paymentData = isStablecoinWallet
          ? await _prepareStablecoinPayment(method)
          : CakePayOrder.getPaymentDataFor(method: method, order: order);
      if (paymentData == null || order == null)
        throw CakePayNoDataException('Payment data or order is not available.');

      updateRemainingTime();
      if (isOrderExpired) {
        return;
      }
      await confirmSending(paymentData);

      final orderRecord = Order(
          id: order!.orderId,
          state: TradeState.deserialize(raw: order!.status),
          transferId: order!.externalId ?? '',
          from: CakePayOrder.getCurrencyCodeFromPaymentMethod(selectedPaymentMethod!),
          to: order!.fiatCurrencyCode,
          createdAt: DateTime.now(),
          amount: paymentData.amount,
          receiveAmount: order!.totalReceiveAmount,
          quantity: order!.quantity.toString(),
          receiveAddress: paymentData.address,
          source: OrderSourceDescription.order,
          giftCardProvider: OrderProviderDescription.cakePay,
          walletId: sendViewModel.wallet.id);
      orders.add(orderRecord);
      updateRemainingTime();
      if (!isOrderExpired) {
        _startExpirationTimer();
      }
    } on CakePayUnauthorizedException {
      rethrow;
    } catch (e) {
      sendViewModel.state = FailureState(
          sendViewModel.translateErrorMessage(e, walletType, sendViewModel.wallet.currency));
    }
  }

  Future<void> _createBackendOrder() async {
    final isPrepaidRangeSelected = card.prepaidRange.isNotEmpty;

    int selectedCardId = card.id;
    String selectedPrice = amount.toString();

    if (isPrepaidRangeSelected) {
      selectedCardId = selectedDenomination.$2 ?? card.id;
      selectedPrice =
          selectedDenomination.$1.isNotEmpty ? selectedDenomination.$1 : amount.toString();
    } else if (isDenominationSelected) {
      selectedCardId = selectedDenomination.$2 ?? card.id;
      selectedPrice = selectedDenomination.$1;
    }

    order = await _cakePayService.createOrder(
      cardId: selectedCardId,
      price: selectedPrice,
      quantity: quantity,
      confirmsNoVpn: confirmsNoVpn,
      confirmsVoidedRefund: confirmsVoidedRefund,
      confirmsTermsAgreed: confirmsTermsAgreed,
    );
  }

  Future<CryptoPaymentData> _prepareStablecoinPayment(CakePayPaymentMethod method) async {
    final coin = method.name;
    final network = order!.paymentData.stablecoins
        .firstWhere((payment) => payment.method == method)
        .findNetwork(sendViewModel.wallet.currency)!;

    final quote = await _cakePayService.getStablecoinQuote(
      orderId: order!.orderId,
      paymentMethod: coin,
      chain: network.id,
    );
    final contract = quote.contract;
    final tokens = walletType == WalletType.solana
        ? solana!.getSPLTokenCurrencies(sendViewModel.wallet).where((token) => token.enabled)
        : sendViewModel.wallet.balance.keys;
    final token = contract == null
        ? null
        : tokens.firstWhereOrNull(
            (currency) =>
                (currency is Erc20Token &&
                    currency.contractAddress.toLowerCase() == contract.toLowerCase()) ||
                (currency is TronToken && currency.contractAddress == contract) ||
                (currency is SPLToken && currency.mintAddress == contract),
          );
    if (token == null) {
      throw CakePayNoDataException("$coin is not available in this wallet.");
    }
    sendViewModel.selectedCryptoCurrency = token;
    final offeredUntil = quote.offeredUntil;
    if (offeredUntil != null && offeredUntil.isBefore(expirationTime!)) {
      expirationTime = offeredUntil;
    }
    return CryptoPaymentData(
      price: quote.amount,
      amount: quote.amount,
      address: quote.address,
    );
  }

  @action
  Future<void> confirmSending(CryptoPaymentData paymentData) async {
    try {
      sendViewModel.clearOutputs();
      final output = sendViewModel.outputs.first;
      output.address = paymentData.address;
      output.setCryptoAmount(paymentData.price);

      await sendViewModel.createTransaction();
    } catch (e) {
      throw e;
    }
  }

  @action
  Future<void> simulatePayment() async {
    if (order == null) {
      throw CakePayNoDataException('Order is not created yet.');
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
