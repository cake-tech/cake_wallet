import 'dart:async';
import 'package:breez_sdk/breez_sdk.dart';
import 'package:breez_sdk/bridge_generated.dart' as BZG;
import 'package:cake_wallet/entities/calculate_fiat_amount_raw.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/lightning/lightning.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:mobx/mobx.dart';

part 'lightning_view_model.g.dart';

class LightningViewModel = LightningViewModelBase with _$LightningViewModel;

abstract class LightningViewModelBase with Store {
  LightningViewModelBase() {}

  Future<ReceiveOnchainResult> receiveOnchain() async {
    final sdk = await BreezSDK();

    BZG.ReceiveOnchainRequest req = const BZG.ReceiveOnchainRequest();
    BZG.SwapInfo swapInfo = await sdk.receiveOnchain(req: req);
    print("Minimum amount allowed to deposit in sats: ${swapInfo.minAllowedDeposit}");
    print("Maximum amount allowed to deposit in sats: ${swapInfo.maxAllowedDeposit}");
    int fee = swapInfo.channelOpeningFees?.minMsat ?? 2000;
    fee = fee ~/ 1000;
    return ReceiveOnchainResult(
      bitcoinAddress: swapInfo.bitcoinAddress,
      minAllowedDeposit: swapInfo.minAllowedDeposit,
      maxAllowedDeposit: swapInfo.maxAllowedDeposit,
      fee: fee,
    );
  }

  Future<String> createInvoice({required String amountSats, String? description}) async {
    final sdk = await BreezSDK();
    final req = BZG.ReceivePaymentRequest(
      amountMsat: (double.parse(amountSats) * 1000).round(),
      description: description ?? '',
    );
    final res = await sdk.receivePayment(req: req);
    return res.lnInvoice.bolt11;
  }

  Future<InvoiceSoftLimitsResult> invoiceSoftLimitsSats() async {
    final sdk = await BreezSDK();
    BZG.ReceivePaymentRequest? req = null;
    req = BZG.ReceivePaymentRequest(
      amountMsat: 10000 * 1000, // 10000 sats
      description: "limits",
    );
    final res = await sdk.receivePayment(req: req);
    int min = (res.openingFeeMsat ?? (2500 * 1000)) ~/ 1000;
    int max = 1000000000 * 1000 * 10; // 10 BTC

    int balance = 0;

    try {
      final nodeState = (await sdk.nodeInfo())!;
      max = nodeState.inboundLiquidityMsats ~/ 1000;
      balance = nodeState.channelsBalanceMsat ~/ 1000;
      if (balance > 0) {
        min = 0;
      }
    } catch (_) {}
    return InvoiceSoftLimitsResult(
      min: min,
      max: max,
      balance: balance,
    );
  }

  Future<int> getBalanceSats() async {
    try {
      final sdk = await BreezSDK();
      final nodeState = (await sdk.nodeInfo())!;
      return nodeState.channelsBalanceMsat ~/ 1000;
    } catch (_) {
      return 0;
    }
  }
}


class ReceiveOnchainResult {
  final String bitcoinAddress;
  final int minAllowedDeposit;
  final int maxAllowedDeposit;
  final int fee;

  ReceiveOnchainResult({
    required this.bitcoinAddress,
    required this.minAllowedDeposit,
    required this.maxAllowedDeposit,
    required this.fee,
  });
}

class InvoiceSoftLimitsResult {
  final int min;
  final int max;
  final int balance;

  InvoiceSoftLimitsResult({
    required this.min,
    required this.max,
    required this.balance,
  });
}