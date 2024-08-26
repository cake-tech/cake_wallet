import 'dart:async';
// import 'package:breez_sdk/breez_sdk.dart';
// import 'package:breez_sdk/bridge_generated.dart' as BZG;
import 'package:cake_wallet/lightning/lightning.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_lightning/lightning_wallet.dart';
import 'package:mobx/mobx.dart';
import 'package:ldk_node/ldk_node.dart' as ldk;

part 'lightning_view_model.g.dart';

class LightningViewModel = LightningViewModelBase with _$LightningViewModel;

abstract class LightningViewModelBase with Store {
  LightningViewModelBase({
    required this.appStore,
    required this.settingsStore,
    required this.wallet,
  }) {
    // _sdk = BreezSDK();
    // _builder = createBuilder("mnemonic");
  }

  final AppStore appStore;
  final SettingsStore settingsStore;
  final WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> wallet;

  // late ldk.Builder _builder;
  // ldk.Node? _node;

  // Future<ldk.Builder> createBuilder(String mnemonic) async {
  //   String workingDir = await pathForWalletDir(name: walletInfo.name, type: type);
  //   workingDir = "$workingDir/ldk/";
  //   new Directory(workingDir).createSync(recursive: true);

  //   String esploraUrl = "https://mutinynet.ltbl.io/api";

  //   ldk.SocketAddress address = ldk.SocketAddress.hostname(addr: "0.0.0.0", port: 3003);

  //   return ldk.Builder.mutinynet()
  //       .setEntropyBip39Mnemonic(mnemonic: ldk.Mnemonic(seedPhrase: mnemonic))
  //       .setEsploraServer(esploraUrl)
  //       .setStorageDirPath(workingDir)
  //       .setListeningAddresses([address]);
  // }

  Future<ReceiveOnchainResult> receiveOnchain() async {
    // BZG.ReceiveOnchainRequest req = const BZG.ReceiveOnchainRequest();
    // BZG.SwapInfo swapInfo = await _sdk.receiveOnchain(req: req);
    // print("Minimum amount allowed to deposit in sats: ${swapInfo.minAllowedDeposit}");
    // print("Maximum amount allowed to deposit in sats: ${swapInfo.maxAllowedDeposit}");

    // int fee = 0;
    // double feePercent = 0;

    // try {
    //   final nodeState = (await _sdk.nodeInfo())!;
    //   int inboundLiquidity = nodeState.inboundLiquidityMsats ~/ 1000;
    //   final openingFees = await _sdk.openChannelFee(
    //       req: BZG.OpenChannelFeeRequest(amountMsat: inboundLiquidity + 1));
    //   feePercent = (openingFees.feeParams.proportional * 100) / 1000000;
    //   fee = openingFees.feeParams.minMsat ~/ 1000;
    // } catch (_) {}

    // return ReceiveOnchainResult(
    //   bitcoinAddress: swapInfo.bitcoinAddress,
    //   minAllowedDeposit: swapInfo.minAllowedDeposit,
    //   maxAllowedDeposit: swapInfo.maxAllowedDeposit,
    //   feePercent: feePercent,
    //   fee: fee,
    // );

    // TODO: use proxy layer:
    final address = await (wallet as LightningWallet).newOnchainAddress();
    print("New onchain address: $address");

    return ReceiveOnchainResult(
      bitcoinAddress: address,
      minAllowedDeposit: 0,
      maxAllowedDeposit: 0,
      feePercent: 0,
      fee: 0,
    );
  }

  Future<String> createInvoice({required String amountSats, String? description}) async {
    // final req = BZG.ReceivePaymentRequest(
    //   amountMsat: (double.parse(amountSats) * 1000).round(),
    //   description: description ?? '',
    // );
    // final res = await _sdk.receivePayment(req: req);

    // return res.lnInvoice.bolt11;
    return "";
  }

  Future<InvoiceSoftLimitsResult> invoiceSoftLimitsSats() async {
    double feePercent = 0.4;
    int minFee = (2500 * 1000) ~/ 1000; // 2500 sats
    int inboundLiquidity = 1000000000 * 1000 * 10; // 10 BTC
    int balance = 0;

    // try {
    //   final nodeState = (await _sdk.nodeInfo())!;
    //   inboundLiquidity = nodeState.inboundLiquidityMsats ~/ 1000;

    //   final openingFees = await _sdk.openChannelFee(
    //       req: BZG.OpenChannelFeeRequest(amountMsat: inboundLiquidity + 1));

    //   feePercent = (openingFees.feeParams.proportional * 100) / 1000000;
    //   minFee = openingFees.feeParams.minMsat ~/ 1000;
    //   balance = nodeState.channelsBalanceMsat ~/ 1000;
    // } catch (_) {
    //   minFee = 0;
    // }

    return InvoiceSoftLimitsResult(
      minFee: minFee,
      inboundLiquidity: inboundLiquidity,
      feePercent: feePercent,
      balance: balance,
    );
  }

  Future<int> getBalanceSats() async {
    // try {
    //   final nodeState = (await _sdk.nodeInfo())!;
    //   return nodeState.channelsBalanceMsat ~/ 1000;
    // } catch (_) {
    //   return 0;
    // }
    return 0;
  }

  // Future<BZG.HealthCheckStatus> serviceHealthCheck() async {
  //   try {
  //     BZG.ServiceHealthCheckResponse response =
  //         await _sdk.serviceHealthCheck(apiKey: lightning!.getBreezApiKey());
  //     return response.status;
  //   } catch (_) {
  //     return BZG.HealthCheckStatus.ServiceDisruption;
  //   }
  // }
}

class ReceiveOnchainResult {
  final String bitcoinAddress;
  final int minAllowedDeposit;
  final int maxAllowedDeposit;
  final int fee;
  final double feePercent;

  ReceiveOnchainResult({
    required this.bitcoinAddress,
    required this.minAllowedDeposit,
    required this.maxAllowedDeposit,
    required this.fee,
    required this.feePercent,
  });
}

class InvoiceSoftLimitsResult {
  final double feePercent;
  final int minFee;
  final int inboundLiquidity;
  final int balance;

  InvoiceSoftLimitsResult({
    required this.inboundLiquidity,
    required this.feePercent,
    required this.minFee,
    required this.balance,
  });
}

class LightningInvoice {
  final String bolt11;
  final BigInt amountSat;
  final String? description;

  LightningInvoice({
    required this.bolt11,
    required this.amountSat,
    this.description,
  });
}
