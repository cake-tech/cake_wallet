import 'dart:async';
import 'package:breez_sdk/breez_sdk.dart';
import 'package:breez_sdk/bridge_generated.dart';
import 'package:mobx/mobx.dart';

part 'lightning_view_model.g.dart';

class LightningViewModel = LightningViewModelBase with _$LightningViewModel;

abstract class LightningViewModelBase with Store {
  LightningViewModelBase() {}

  Future<List<String>> receiveOnchain() async {
    final sdk = await BreezSDK();

    ReceiveOnchainRequest req = const ReceiveOnchainRequest();
    SwapInfo swapInfo = await sdk.receiveOnchain(req: req);
    print("Minimum amount allowed to deposit in sats: ${swapInfo.minAllowedDeposit}");
    print("Maximum amount allowed to deposit in sats: ${swapInfo.maxAllowedDeposit}");
    int fee = swapInfo.channelOpeningFees?.minMsat ?? 2000;
    fee = fee ~/ 1000;
    return [
      swapInfo.bitcoinAddress,
      swapInfo.minAllowedDeposit.toString(),
      swapInfo.maxAllowedDeposit.toString(),
      fee.toString(),
    ];
  }

  Future<String> createInvoice({required String amount, String? description}) async {
    final sdk = await BreezSDK();
    final req = ReceivePaymentRequest(
      amountMsat: (double.parse(amount) * 1000).round(),
      description: description ?? '',
    );
    final res = await sdk.receivePayment(req: req);
    return res.lnInvoice.bolt11;
  }

  Future<List<String>> invoiceLimitsSats() async {
    final sdk = await BreezSDK();
    final req = ReceivePaymentRequest(
      amountMsat: 3000 * 1000,// 3000 sats
      description: "limits",
    );
    final res = await sdk.receivePayment(req: req);
    int min = (res.openingFeeMsat ?? (2500 * 1000)) ~/ 1000;
    int max = 1000000000 * 1000 * 10;// 10 BTC
    return [min.toString(), max.toString()];
  }
}
