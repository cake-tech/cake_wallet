import 'dart:async';
import 'package:breez_sdk/breez_sdk.dart';
import 'package:breez_sdk/bridge_generated.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/view_model/auth_state.dart';
import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/entities/biometric_auth.dart';
import 'package:cake_wallet/store/settings_store.dart';

part 'lightning_view_model.g.dart';

class LightningViewModel = LightningViewModelBase with _$LightningViewModel;

abstract class LightningViewModelBase with Store {
  LightningViewModelBase() {}

  // @observable
  // ExecutionState state;

  @action
  Future<void> receiveOnChain() async {
                  print("pressed");
                  // ReceivePaymentRequest req = const ReceivePaymentRequest(
                  //   amountMsat: 3000000,
                  //   description: "Invoice for 3000 sats",
                  // );
                  // ReceivePaymentResponse receivePaymentResponse =
                  //     await BreezSDK().receivePayment(req: req);

                  // print(receivePaymentResponse.lnInvoice);

                  final sdk = await BreezSDK();

                  sdk.nodeStateStream.listen((event) {
                    // print("Node state: $event");
                    if (event == null) return;
                    int balanceSat = event.maxPayableMsat ~/ 1000;
                    print("sats: $balanceSat");
                  });

                  // ServiceHealthCheckResponse healthCheck = await sdk.serviceHealthCheck();
                  // print("Current service status is: ${healthCheck.status}");

                  // ReceivePaymentRequest req = ReceivePaymentRequest(
                  //   amountMsat: 123 * 1000,
                  //   description: "Invoice for 123 sats",
                  // );
                  // final s = await sdk.receivePayment(req: req);
                  // print(s.lnInvoice.bolt11);

                  // ReceiveOnchainRequest req = const ReceiveOnchainRequest();
                  // SwapInfo swapInfo = await sdk.receiveOnchain(req: req);
                  // // Send your funds to the below bitcoin address
                  // String address = swapInfo.bitcoinAddress;
                  // print(address);
                  // print("Minimum amount allowed to deposit in sats: ${swapInfo.minAllowedDeposit}");
                  // print("Maximum amount allowed to deposit in sats: ${swapInfo.maxAllowedDeposit}");

                  ListPaymentsRequest lReq = ListPaymentsRequest();

                  var list = await sdk.listPayments(req: lReq);
                  print(list[0].amountMsat);

                  var data = await sdk.fetchNodeData();
                  print(data);


  }
}
