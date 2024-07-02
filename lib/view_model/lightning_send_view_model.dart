import 'dart:async';
import 'package:breez_sdk/breez_sdk.dart';
import 'package:breez_sdk/bridge_generated.dart' as BZG;
import 'package:cake_wallet/entities/calculate_fiat_amount_raw.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/lightning/lightning.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/widgets.dart';
import 'package:mobx/mobx.dart';

part 'lightning_send_view_model.g.dart';

class LightningSendViewModel = LightningSendViewModelBase with _$LightningSendViewModel;

abstract class LightningSendViewModelBase with Store {
  LightningSendViewModelBase({
    required this.settingsStore,
    required this.fiatConversionStore,
  }) {}

  final SettingsStore settingsStore;
  final FiatConversionStore fiatConversionStore;

  @observable
  bool loading = false;

  @action
  void setLoading(bool value) {
    loading = value;
  }

  FiatCurrency get fiat => settingsStore.fiatCurrency;

  String formattedFiatAmount(int sats) {
    String amount = calculateFiatAmountRaw(
      cryptoAmount: lightning!.formatterLightningAmountToDouble(amount: sats),
      price: fiatConversionStore.prices[CryptoCurrency.btcln],
    );
    return amount;
  }

  @action
  Future<void> send(BZG.LNInvoice invoice, int satAmount) async {
    try {
      setLoading(true);

      final sdk = await BreezSDK();
      late BZG.SendPaymentRequest req;

      if (invoice.amountMsat == null) {
        req = BZG.SendPaymentRequest(
          bolt11: invoice.bolt11,
          amountMsat: satAmount * 1000,
        );
      } else {
        req = BZG.SendPaymentRequest(bolt11: invoice.bolt11);
      }

      final response = await sdk.sendPayment(req: req);
      if (response.payment.error != null) {
        throw Exception(response.payment.error);
      }

      if (response.payment.status == BZG.PaymentStatus.Failed) {
        throw Exception("Payment failed");
      }

      setLoading(false);
    } catch (e) {
      setLoading(false);
      rethrow;
    }
  }

  @action
  Future<void> processInput(BuildContext context, String input) async {
    FocusScope.of(context).unfocus();

    final sdk = await BreezSDK();

    late BZG.InputType inputType;

    try {
      inputType = await sdk.parseInput(input: input);
    } catch (_) {
      throw Exception("Unknown input type");
    }

    if (inputType is BZG.InputType_Bolt11) {
      final bolt11 = await sdk.parseInvoice(input);
      Navigator.of(context).pushNamed(Routes.lightningSendConfirm, arguments: bolt11);
    } else if (inputType is BZG.InputType_LnUrlPay) {
      throw Exception("Unsupported input type");
    } else {
      throw Exception("Unknown input type");
    }
  }
}
